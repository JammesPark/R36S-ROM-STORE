-- Painel de utilitarios do Tema Padrao: categorias a esquerda, itens e descricoes a direita.
-- As acoes continuam usando os mesmos modulos da tela de catalogo.
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local Icons = require("ui.icons")
local Catalog = require("core.catalog")
local Favorites = require("core.favorites")
local Tools = require("core.tools")

local P = {}
local LX, Y, LW, RX, RW, H = 12, 52, 202, 226, 402, 378
local TAB_H, TAB_VIS, ITEM_H, ITEM_VIS = 36, 10, 36, 5

function P.active(scr)
  return scr.section == "tools" and not scr.mine and not scr.favs
    and not scr.installed_store and T.style.layout == nil
end

local function category_desc(tab)
  if tab.id == "all" then return L("Ferramentas disponíveis para gerenciamento e manutenção do console.") end
  if tab.id == "installed" then return L("Utilitários e ferramentas encontrados instalados no console.") end
  for _, cat in ipairs(Catalog.categories) do
    if tab.id == "cat:" .. cat.id and cat.section == "tools" then
      return cat.description or cat.desc or (L("Ferramentas da categoria ") .. cat.name .. ".")
    end
  end
  return L("Selecione uma ferramenta da categoria.")
end

local function focus_tab(scr, index)
  index = math.max(1, math.min(#scr.tabs, index))
  if index == scr.tab then return end
  scr.tab = index
  scr.filter = scr.tabs[index].id
  scr.section = scr.tabs[index].section
  scr.sel, scr.scroll = 1, 0
  scr.tool_item_top = 0
  scr:refresh()
end

function P.draw(scr)
  local focus = scr.tool_focus or "categories"
  local n = #scr.tabs
  scr.tool_tab_top = scr.tool_tab_top or 0
  if scr.tab <= scr.tool_tab_top then scr.tool_tab_top = scr.tab - 1 end
  if scr.tab > scr.tool_tab_top + TAB_VIS then scr.tool_tab_top = scr.tab - TAB_VIS end
  scr.tool_tab_top = math.max(0, math.min(scr.tool_tab_top, math.max(0, n - TAB_VIS)))

  G.clip(LX - 2, Y, LW + 4, TAB_VIS * TAB_H)
  for i = scr.tool_tab_top + 1, math.min(n, scr.tool_tab_top + TAB_VIS) do
    local tab = scr.tabs[i]
    local y = Y + (i - scr.tool_tab_top - 1) * TAB_H
    local on = i == scr.tab
    if on then
      G.rect(LX, y, LW, TAB_H - 3, T.c.bg2, 7)
      G.frame(LX, y, LW, TAB_H - 3, focus == "categories" and T.c.green or T.c.line, 7, focus == "categories" and 2 or 1)
      G.rect(LX, y + 6, 4, TAB_H - 15, T.c.green, 2)
    end
    Icons.draw(tab.id == "all" and "roms_tools_kit" or "games", LX + 13, y + 7, on and T.c.green or T.c.dim, 0.8)
    G.text_fit(T.f.bodyb, tab.label, LX + 42, y + 7, LW - 50, on and T.c.text or T.c.dim)
  end
  G.unclip()
  if n > TAB_VIS then
    local track = TAB_H * TAB_VIS
    local bar = track * TAB_VIS / n
    G.rect(LX + LW + 2, Y + (track - bar) * (scr.tool_tab_top / (n - TAB_VIS)), 3, bar, T.c.green, 1)
  end

  G.panel(RX, Y, RW, H, { bg = T.c.bg1 })
  local tab = scr.tabs[scr.tab]
  if not tab then return end
  G.rect(RX + 14, Y + 13, 4, 24, T.c.green, 2)
  G.text_fit(T.f.h3, tab.label, RX + 26, Y + 12, RW - 48, T.c.text)
  local cf, lines, lh = G.fit_lines(T.f.small, category_desc(tab), RW - 32, 35, true)
  for i, line in ipairs(lines) do G.text(cf, line, RX + 16, Y + 42 + (i - 1) * lh, T.c.dim) end
  G.rect(RX + 14, Y + 82, RW - 28, 1, T.c.line)

  local listY = Y + 89
  local count = #scr.items
  scr.tool_item_top = scr.tool_item_top or 0
  if scr.sel <= scr.tool_item_top then scr.tool_item_top = scr.sel - 1 end
  if scr.sel > scr.tool_item_top + ITEM_VIS then scr.tool_item_top = scr.sel - ITEM_VIS end
  scr.tool_item_top = math.max(0, math.min(scr.tool_item_top, math.max(0, count - ITEM_VIS)))
  if count == 0 then
    G.text(T.f.bodyb, L("Nenhuma ferramenta nesta categoria."), RX + 20, listY + 62, T.c.dim)
  else
    G.clip(RX + 9, listY, RW - 18, ITEM_H * ITEM_VIS)
    for i = scr.tool_item_top + 1, math.min(count, scr.tool_item_top + ITEM_VIS) do
      local p = scr.items[i]
      local iy = listY + (i - scr.tool_item_top - 1) * ITEM_H
      local on = i == scr.sel
      G.rect(RX + 11, iy, RW - 22, ITEM_H - 2, on and T.c.bg3 or T.c.bg2, 5)
      if on and focus == "items" then G.frame(RX + 11, iy, RW - 22, ITEM_H - 2, T.c.green, 5, 2) end
      if on then G.rect(RX + 11, iy + 6, 3, ITEM_H - 14, T.c.green, 2) end
      Icons.draw(p.icon or "roms_tools_kit", RX + 22, iy + 7, on and T.c.green or T.c.dim, 0.85)
      G.text_fit(T.f.bodyb, p.name or "", RX + 52, iy + 7, RW - 83, on and T.c.text or T.c.dim)
    end
    G.unclip()
  end

  local dy = Y + 277
  G.rect(RX + 14, dy, RW - 28, 1, T.c.line)
  local p = scr.items[scr.sel]
  if p then
    G.text_fit(T.f.bodyb, p.name, RX + 17, dy + 8, RW - 34, T.c.text)
    G.text_fit(T.f.small, tostring(p.category or tab.label), RX + 17, dy + 28, RW - 34, T.c.green)
    local short = p.builtin and (p.short or "") or Catalog.text(p, "short")
    local f, ls, lineH = G.fit_lines(T.f.small, short ~= "" and short or L("Sem descrição."), RW - 34, 49, true)
    for i, line in ipairs(ls) do G.text(f, line, RX + 17, dy + 47 + (i - 1) * lineH, T.c.dim) end
  else
    G.text(T.f.small, L("Selecione uma categoria para ver as ferramentas."), RX + 17, dy + 18, T.c.faint)
  end
  local hints = { { "dpad", L("Navegar") }, { "a", focus == "categories" and L("Abrir lista") or L("Detalhes") }, { "b", focus == "items" and L("Categorias") or L("Voltar") } }
  G.hints(hints)
end

function P.action(scr, act)
  local focus = scr.tool_focus or "categories"
  if act == "b" then
    if focus == "items" then scr.tool_focus = "categories" else App.pop() end
    return
  end
  if act == "l1" or act == "r1" then
    focus_tab(scr, (scr.tab - 1 + (act == "l1" and -1 or 1)) % #scr.tabs + 1)
    scr.tool_focus = "categories"
    return
  end
  if focus == "categories" then
    if act == "up" then focus_tab(scr, (scr.tab - 2) % #scr.tabs + 1)
    elseif act == "down" then focus_tab(scr, scr.tab % #scr.tabs + 1)
    elseif act == "a" or act == "right" then
      if #scr.items > 0 then scr.tool_focus = "items" end
    elseif act == "x" then App.push("search", { from = "store" })
    end
    return
  end
  local n = #scr.items
  if act == "left" then scr.tool_focus = "categories"
  elseif act == "up" and n > 0 then scr.sel = (scr.sel - 2) % n + 1
  elseif act == "down" and n > 0 then scr.sel = scr.sel % n + 1
  elseif act == "a" and n > 0 then
    local p = scr.items[scr.sel]
    if p.builtin then App.push(p.screen, { from = "store" })
    else App.push("details", { port = p }) end
  elseif act == "select" and n > 0 then
    local p = scr.items[scr.sel]
    if not p.builtin then
      local on = Favorites.toggle(p)
      App.toast(on and (p.name .. L(" adicionado aos favoritos")) or (p.name .. L(" removido dos favoritos")), "info")
    end
  elseif act == "x" then App.push("search", { from = "store" })
  elseif act == "y" then
    App.toast(L("Atualizando catálogo..."), "info")
    App.refresh_catalog(true)
  end
end

return P
