-- Catalogo de ports: abas de categoria + lista + pre-visualizacao
local L = require("lib.i18n").L
local I18N = require("lib.i18n")
local Compat = require("core.compat")
local T = require("ui.theme")
local G = require("ui.gfx")
local U = require("lib.util")
local Catalog = require("core.catalog")
local Covers = require("core.covers")
local Manifest = require("core.manifest")
local Cats = require("core.categories")
local PortRow = require("ui.portrow")
local CG = require("ui.covergrid")
local Favorites = require("core.favorites")
local Tools = require("core.tools")
local Icons = require("ui.icons")
local CV = require("ui.coverview")
local Region = require("ui.region")
local Prefs = require("core.prefs")
local Themes = require("core.themes")

local S = {}
-- Pulse e Matrix oferecem as mesmas tres vistas, com preferencias independentes.
local VIEWS = { "list", "grid", "showcase" }
local VIEW_NAMES = { list = "Lista", grid = "Grade Jedi", showcase = "Vitrine Pastel" }

local function view_key()
  return Themes.current=="neongrid" and "rom_view_matrix" or "rom_view_default"
end
local function active_view(section)
  if section=="tools" then return T.style.list=="grid" and "grid" or "list" end
  local id=Prefs.get(view_key())
  if id=="grid" or id=="showcase" or id=="list" then return id end
  return Themes.current=="neongrid" and "grid" or "list"
end

local function change_view(direction)
  local current = active_view()
  for i, value in ipairs(VIEWS) do
    if value == current then
      local next_mode = VIEWS[(i - 1 + direction + #VIEWS) % #VIEWS + 1]
      Prefs.set(view_key(), next_mode)
      return next_mode
    end
  end
  Prefs.set(view_key(), "list")
  return "list"
end

local ROW_H, LIST_Y, LIST_X, LIST_W = 50, 84, 12, 356
local VISIBLE = 7

local BADGE = {
  installed = { L("INSTALADO"), T.c.green },
  update = { L("ATUALIZAR"), T.c.yellow },
}

-- Modos:
--   area (params.section = "games" | "tools"): Todos + categorias da area + Instalados
--   Meus Ports (params.mine = true): abas Jogos | Utilitarios & Ferramentas (so instalados)
-- As duas areas nunca aparecem na mesma listagem.
function S:enter(params)
  self.installed_only=params.installed_only==true
  self.mine = params.mine and true or false
  self.favs = params.favs and true or false
  self.section = params.section or "games"
  self.filter = params.filter or (self.mine and "installed" or (self.favs and "favs" or "all"))
  self.sel, self.scroll, self.tab_scroll = 1, 0, 0
  if self.section=="tools" then
    Manifest.rescan()
    if self.mine then Manifest.refresh_locations() end
  end
  self:build_tabs()
  self:refresh()
end

function S:build_tabs()
  local tabs = {}
  if self.installed_only then
    self.installed_rows=require("core.rom_installed").list(Catalog)
    tabs[1]={id="installed",section="games",label=L("Todos")}
    local seen={}
    for _,q in ipairs(self.installed_rows) do seen[q.category_id]=q.category or q.category_id end
    local ordered={}
    for id,name in pairs(seen) do ordered[#ordered+1]={id=id,name=name} end
    table.sort(ordered,require("core.catalog_presentation").less)
    for _,c in ipairs(ordered) do tabs[#tabs+1]={id="cat:"..c.id,section="games",label=c.name} end
  elseif self.mine or self.favs then
    for _, sec in ipairs(Cats.SECTIONS) do
      tabs[#tabs + 1] = { id = self.mine and "installed" or "favs", section = sec.id, label = sec.name }
    end
  else
    tabs[1] = { id = "all", section = self.section, label = L("Todos") }
    local categories = self.section == "games" and Catalog.systems() or Catalog.categories
    for _, c in ipairs(categories) do
      if c.section == self.section then
        tabs[#tabs + 1] = { id = "cat:" .. c.id, section = self.section, label = c.name }
      end
    end
    tabs[#tabs + 1] = { id = "installed", section = self.section, label = L("Instalados") }
  end
  self.tabs = tabs
  self.tab = 1
  for i, t in ipairs(tabs) do
    if t.id == self.filter and t.section == self.section then self.tab = i end
  end
  self.filter = tabs[self.tab].id
  self.section = tabs[self.tab].section
end

function S:refresh()
  local cur = self.items and self.items[self.sel]
  Covers.reset_pending()
  self.items = {}
  if self.installed_only then
    for _,p in ipairs(self.installed_rows or {}) do
      if self.filter=="installed" or self.filter=="cat:"..p.category_id then self.items[#self.items+1]=p end
    end
    self.sel=1
    if cur then for i,p in ipairs(self.items) do if p.id==cur.id then self.sel=i;break end end end
    self:clamp()
    return
  end
  -- ferramentas integradas (Manutencao) primeiro; depois os ports do catalogo
  if not self.mine and not self.favs then
    for _, t in ipairs(Tools.for_filter(self.section, self.filter)) do self.items[#self.items + 1] = t end
  end
  -- Configuracoes > Catalogo > Ordenacao (favoritos: Favoritos e jogos > Ordenar)
  local status = App.status
  if self.mine then
    status = function(p) return Manifest.location_label(p) and "installed" or "none" end
  end
  local ports = Catalog.filter(self.filter, status, self.section)
  if self.filter ~= "cat:testes_de_controles" then   -- esta categoria ja vem agrupada pelo tipo de teste
    ports = require("ui.settings_extra").sort_ports(ports, self.favs and "fav_sort" or "list_sort")
  end
  -- Pacotes compactados na raiz de ports aparecem em Meus Ports como atalho.
  -- O scanner verifica ambos os cartoes montados separadamente.
  if self.mine and self.section == "games" then
    local PP = require("core.pendports")
    PP.scan()
    local n = PP.count()
    if n > 0 then
      self.items[#self.items + 1] = {
        id = "_pendports", builtin = true, screen = "pendports", icon = "download",
        badge = { L("INSTALAR"), T.c.yellow },
        name = string.format(require("lib.i18n").tr(L("%d arquivo(s) prontos para instalar")), n),
        short = L("Arquivos de ports compactados encontrados em SD1 e SD2."),
        category = L("Pasta ports"), category_id = "_pend", version = "", section = "games",
      }
    end
  end
  for _, p in ipairs(ports) do self.items[#self.items + 1] = p end
  self.sel = 1
  if cur then
    for i, p in ipairs(self.items) do if p.id == cur.id then self.sel = i end end
  end
  self:clamp()
end

function S:on_catalog()
  if self.mine and self.section=="tools" then Manifest.refresh_locations() end
  self:build_tabs()
  self:refresh()
end

function S:resume()
  if self.installed_only then self:build_tabs() end
  if self.mine and self.section=="tools" then Manifest.refresh_locations() end
  self:refresh()
end

function S:leave() Covers.reset_pending() end

function S:clamp()
  local n = #self.items
  self.sel = U.clamp(self.sel, 1, math.max(1, n))
  if self.sel <= self.scroll then self.scroll = self.sel - 1 end
  if self.sel > self.scroll + VISIBLE then self.scroll = self.sel - VISIBLE end
  self.scroll = U.clamp(self.scroll, 0, math.max(0, n - VISIBLE))
end

function S:title()
  if self.installed_only then return L("Instalados") end
  if self.mine then return L("Meus Ports") end
  if self.favs then return L("Favoritos") end
  return Cats.SECTION_BY_ID[self.section].name
end

function S:color()
  return self.section == "tools" and T.c.green or T.c.accent
end

function S:draw_tabs()
  local f = T.f.bodyb
  local x0, y = 12, 48
  local xs, x = {}, 0
  for i, t in ipairs(self.tabs) do
    local w = f:getWidth(t.label) + 24
    xs[i] = { x, w }
    x = x + w + 6
  end
  -- rolagem horizontal das abas
  local cur = xs[self.tab]
  local view = T.W - 24 - 96
  if cur[1] - self.tab_scroll < 0 then self.tab_scroll = cur[1] end
  if cur[1] + cur[2] - self.tab_scroll > view then self.tab_scroll = cur[1] + cur[2] - view end
  G.clip(x0, y - 2, view + 2, 32)
  for i, t in ipairs(self.tabs) do
    local tx = x0 + xs[i][1] - self.tab_scroll
    local w = xs[i][2]
    local on = i == self.tab
    if on then
      G.rect(tx, y, w, 26, self:color(), 13)
      G.text(f, t.label, tx, y + 4, T.c.bg0, "center", w)
    else
      G.rect(tx, y, w, 26, T.c.bg2, 13)
      G.text(f, t.label, tx, y + 4, T.c.dim, "center", w)
    end
  end
  G.unclip()
  G.button_icon("l1", T.W - 80, y + 5)
  G.button_icon("r1", T.W - 44, y + 5)
end

function S:draw_list()
  local n = #self.items
  if n == 0 then
    G.panel(LIST_X, LIST_Y, T.W - 24, 346, { bg = T.c.bg1 })
    local msg, sub
    local area = Cats.SECTION_BY_ID[self.section].name
    if self.filter == "favs" then
      msg, sub = L("Lista vazia"), L("Nenhum favorito em ") .. area .. L(".\nNa loja, pressione SELECT sobre um port para marcar com a estrela.")
    elseif self.installed_only or (self.filter == "installed" and self.section=="games") then
      msg,sub=L("Nada instalado"),L("Nenhuma ROM baixada por este aplicativo até agora.")
    elseif self.filter == "installed" then
      msg, sub = L("Nada instalado"), L("Nenhum port de ") .. area .. L(" instalado no console.")
    elseif self.section=="games" and (self.filter=="all" or self.filter:sub(1,4)=="cat:") then
      msg,sub=L("Categoria vazia"),L("Não há ROMs neste sistema do catálogo próprio.")
    elseif self.filter:sub(1, 4) == "cat:" then
      msg, sub = L("Categoria vazia"), L("Não existem ports disponíveis nesta categoria.")
    else
      msg, sub = L("Nenhum port ainda"), L("Não existem ports disponíveis em ") .. area .. L(".\nEles aparecem aqui quando o catálogo for atualizado (Configurações).")
    end
    G.text(T.f.pix16, U.upper(msg), LIST_X, LIST_Y + 130, T.c.dim, "center", T.W - 24)
    G.text(T.f.body, sub, LIST_X + 20, LIST_Y + 162, T.c.faint, "center", T.W - 64)
    return
  end
  G.panel(LIST_X, LIST_Y, LIST_W, VISIBLE * ROW_H + 8, { bg = T.c.bg1 })
  for i = self.scroll + 1, math.min(n, self.scroll + VISIBLE) do
    local p = self.items[i]
    local y = LIST_Y + 4 + (i - self.scroll - 1) * ROW_H
    PortRow.draw(p, LIST_X + 4, y, LIST_W - 8, ROW_H - 4, i == self.sel, T.c.accent,
      self.mine and { location = Manifest.location_label(p) } or nil)
  end
  -- barra de rolagem
  if n > VISIBLE then
    local track = VISIBLE * ROW_H - 4
    local h = math.max(20, track * VISIBLE / n)
    local yy = LIST_Y + 6 + (track - h) * (self.scroll / (n - VISIBLE))
    G.rect(LIST_X + LIST_W - 4, yy, 3, h, T.c.accent2, 1, 0.7)
  end
end

function S:draw_preview()
  local p = self.items[self.sel]
  if not p then return end
  local px, py, pw, ph = 380, LIST_Y, 248, VISIBLE * ROW_H + 8
  G.panel(px, py, pw, ph, { bg = T.c.bg1 })
  local cw, ch = 150, 200
  if p.builtin then
    G.rect(px + (pw - cw) / 2, py + 12, cw, ch, T.c.bg0, 10)
    G.frame(px + (pw - cw) / 2, py + 12, cw, ch, T.c.green, 10, 2)
    Icons.draw(p.icon, px + pw / 2 - 36, py + 70, T.c.green, 3)
    G.text(T.f.pix8, (p.badge and p.badge[1]) or L("INTEGRADO"), px, py + ch - 14,
      (p.badge and p.badge[2]) or T.c.green, "center", pw)
  else
    G.cover(Covers.get(p), p, px + (pw - cw) / 2, py + 12, cw, ch, Covers.is_loading(p), App.t)
  end
  local y = py + ch + 22
  G.text_fit(T.f.h3, Region.display_name(p), px + 14, y, pw - 28, T.c.text)
  y = y + 24
  local tw = Region.draw_system(p, px + 14, y, pw - 28)
  local rx = px + 20 + tw
  if Region.code(p) then rx = rx + Region.draw_region(p, rx, y) + 6 end
  if p.version ~= "" and rx < px + pw - 52 then G.tag("v" .. p.version, rx, y, T.c.bg3, T.c.dim) end
  y = y + 26
  if self.mine then
    local loc = Manifest.location_label(p)
    if loc then G.tag(loc, px + 14, y - 2, T.c.green, T.c.bg0); y = y + 22 end
  end
  local short = Catalog.text(p, "short")
  local lines = G.wrap(T.f.small, short ~= "" and short or L("Sem descrição."), pw - 28)
  for i = 1, math.min(3, #lines) do
    G.text(T.f.small, lines[i] .. ((i == 3 and #lines > 3) and "…" or ""), px + 14, y, T.c.dim)
    y = y + 15
  end
  -- compatibilidade do port em foco (resultado em cache; nada pesado aqui)
  if not p.builtin then
    local r = Compat.evaluate(p)
    if r then
      local col = T.c[Compat.COLOR[r.status]] or T.c.dim
      local label = Compat.LABEL[r.status]
      local tw = T.f.pix8:getWidth(I18N.tr(label)) + 12
      G.tag(label, px + (pw - tw) / 2, py + ph - 26, col, T.c.bg0)
    end
  end
end

function S:update(dt)
  if active_view(self.section) == "showcase" then CV.update(self, self.sel, dt) end
end

-- Pastel Pop: vitrine de capas (ui/coverview.lua) no lugar da lista + previa
function S:draw_showcase()
  local items = self.items
  local function cover(i, x, y, w, h)
    local p = items[i]
    if p.builtin then
      G.rect(x, y, w, h, T.c.bg1, 10)
      G.rect(x + 4, y + 4, w - 8, h - 8, T.c.green, 8, 0.10)
      local isz = math.min(w, h) * 0.5
      Icons.draw(p.icon, x + (w - isz) / 2, y + (h - isz) / 2, T.c.green, isz / 24)
    else
      G.cover(Covers.get(p), p, x, y, w, h, Covers.is_loading(p), App.t)
    end
  end
  local p = items[self.sel]
  local pills, tags = {}, {}
  pills[#pills + 1] = { p.category, Region.SYSTEM_COLOR }
  if Region.code(p) then pills[#pills + 1] = { Region.code(p), Region.color(Region.code(p)) } end
  if not p.builtin then
    if p.size_label and p.size_label ~= "?" then pills[#pills + 1] = { p.size_label, T.c.line } end
    if (p.version or "") ~= "" then pills[#pills + 1] = { "v" .. p.version, T.c.line } end
    local b = PortRow.BADGE[App.status(p)]
    if b then tags[#tags + 1] = { (self.mine and Manifest.location_label(p)) or b[1], b[2] }
    elseif Catalog.is_new(p) then tags[#tags + 1] = { PortRow.NEW[1], PortRow.NEW[2] } end
    if Favorites.is(p) then tags[#tags + 1] = { L("FAVORITO"), T.c.yellow } end
  else
    tags[#tags + 1] = p.badge or { L("INTEGRADO"), T.c.green }
  end
  local none = L("não informado")
  local sections = {}
  if p.builtin then
    sections[#sections + 1] = { title = L("Ferramenta integrada"), text = p.short or "" }
  else
    local st = App.status(p)
    local stt = st == "installed" and L("Instalado") or (st == "update" and L("Atualização disponível") or L("Não instalado"))
    sections[#sections + 1] = { title = L("Detalhes"), rows = {
      { L("Plataforma"), (p.platform or "") ~= "" and p.platform or none },
      { L("Versão"), (p.version or "") ~= "" and p.version or none },
      { L("Tamanho"), (p.size_label and p.size_label ~= "?") and p.size_label or none },
      { L("Desenvolvedor"), (p.author or "") ~= "" and p.author or none },
      { L("Estado"), stt, st == "installed" and T.c.green or (st == "update" and T.c.yellow or nil) },
      { L("Cartão"), (self.mine and Manifest.location_label(p)) or "—", T.c.green },
    } }
    local short = Catalog.text(p, "short")
    sections[#sections + 1] = { title = L("Descrição"), text = short ~= "" and short or L("Sem descrição.") }
    local r = Compat.evaluate(p)
    if r then
      local det = {}
      if r.reason then det[1] = r.reason end
      for _, it in ipairs(r.items or {}) do det[#det + 1] = I18N.tr(it.label) .. ": " .. I18N.tr(it.detail or "") end
      sections[#sections + 1] = { title = L("Compatibilidade"), badge = { Compat.LABEL[r.status], T.c[Compat.COLOR[r.status]] or T.c.dim },
        text = table.concat(det, "\n") }
    end
  end
  CV.draw(self, {
    top = 82, n = #items, sel = self.sel, draw_cover = cover,
    bg_cover = (not p.builtin) and function(x, y, w, h) G.cover(Covers.get(p), p, x, y, w, h, false, App.t) end or nil,
    name = Region.display_name(p), pills = pills, tags = tags, sections = sections,
  })
end

-- Neon Grid: grade de capas (ui/covergrid.lua) com o port escolhido em destaque
function S:draw_grid()
  local items = self.items
  local function cover(i, x, y, w, h)
    local p = items[i]
    if p.builtin then
      G.rect(x, y, w, h, T.c.bg2, 4)
      local isz = math.min(w, h) * 0.5
      Icons.draw(p.icon, x + (w - isz) / 2, y + (h - isz) / 2, T.c.green, isz / 24)
    else
      G.cover(Covers.get(p), p, x, y, w, h, Covers.is_loading(p), App.t)
    end
    if w >= 80 and h >= 105 and Region.code(p) then
      local code = Region.code(p)
      Region.draw_region(p, x + w - Region.pill_width(code) - 3, y + 3)
    end
    if self.mine then
      local loc = Manifest.location_label(p)
      if loc then
        local short = loc == "SD1 + SD2" and "SD1+2" or loc
        G.tag(short, x + 3, y + 3, T.c.green, T.c.bg0, T.f.pix8)
      end
    end
  end
  local p = items[self.sel]
  local pills, tags = {}, {}
  pills[#pills + 1] = { p.category, Region.SYSTEM_COLOR }
  if Region.code(p) then pills[#pills + 1] = { Region.code(p), Region.color(Region.code(p)) } end
  if not p.builtin then
    if p.size_label and p.size_label ~= "?" then pills[#pills + 1] = { p.size_label, T.c.line } end
    if (p.version or "") ~= "" then pills[#pills + 1] = { "v" .. p.version, T.c.line } end
    local b = PortRow.BADGE[App.status(p)]
    if b then tags[#tags + 1] = { (self.mine and Manifest.location_label(p)) or b[1], b[2] }
    elseif Catalog.is_new(p) then tags[#tags + 1] = { PortRow.NEW[1], PortRow.NEW[2] } end
    if Favorites.is(p) then tags[#tags + 1] = { L("FAVORITO"), T.c.yellow } end
  else
    tags[#tags + 1] = p.badge or { L("INTEGRADO"), T.c.green }
  end
  local short = p.builtin and (p.short or "") or Catalog.text(p, "short")
  CG.draw(self, {
    top = 82, n = #items, sel = self.sel, draw_cover = cover,
    name = Region.display_name(p), pills = pills, tags = tags, desc = short ~= "" and short or I18N.tr(L("Sem descrição.")),
    is_new = function(i) return Catalog.is_new(items[i]) and App.status(items[i]) == "none" end,
    badge = function(i)
      local q = items[i]
      if q.builtin then return nil end
      local st = App.status(q)
      return st == "installed" and T.c.green or (st == "update" and T.c.yellow or nil)
    end,
  })
end

function S:draw()
  local view = active_view(self.section)
  -- A lista baixa a capa selecionada; grade/vitrine priorizam a regiao visivel.
  local page = view == "grid" and math.floor((self.sel - 1) / CG.COLS) or self.sel
  Covers.focus_view(self, tostring(self.filter) .. ":" .. view .. ":" .. page, self.items[self.sel])
  local right = string.format(L("%d de %d"), #self.items > 0 and self.sel or 0, #self.items)
  if self.section == "games" then
    right = right .. " · L2/R2 " .. VIEW_NAMES[active_view(self.section)]
  end
  G.header(self:title(), right)
  self:draw_tabs()
  if view == "grid" and #self.items > 0 then
    self:draw_grid()
  elseif view == "showcase" and #self.items > 0 then
    self:draw_showcase()
  else
    self:draw_list()
    self:draw_preview()
  end
  local tabword = (self.mine or self.favs) and L("Área") or L("Categoria")
  -- Rodape: L2/R2 mudam a visualizacao; as abas continuam L1/R1 no topo.
  local left_key,right_key,footer_label="l1","r1",tabword
  if self.section=="games" then
    left_key,right_key,footer_label="l2","r2",L("Visualização")
  end
  if self.filter == "installed" or self.installed_only then
    local current = self.items[self.sel]
    local fav_text = (current and not current.builtin)
      and (Favorites.is(current) and L("Desfavoritar") or L("Favoritar")) or L("Favoritos")
    G.hints({ { "a", (current and current.builtin) and L("Abrir") or L("Detalhes") },
      { "x", L("Pesquisar") }, { "select", fav_text }, { "b", L("Voltar") },
      { left_key, "" }, { right_key, footer_label } },nil,nil,true)
  else
    local cur = self.items[self.sel]
    local fav_text = (cur and not cur.builtin)
      and (Favorites.is(cur) and L("Desfavoritar") or L("Favoritar")) or L("Favoritos")
    local hints = { { "a", (cur and cur.builtin) and L("Abrir") or L("Ver detalhes") },
      { "x", L("Pesquisar") }, { "select", fav_text }, { "b", L("Voltar") },
      { left_key, "" }, { right_key, footer_label }, { "y", L("Atualizar") } }
    G.hints(hints,nil,nil,true)
  end
end

function S:switch_tab(d)
  self.tab = (self.tab - 1 + d) % #self.tabs + 1
  self.filter = self.tabs[self.tab].id
  self.section = self.tabs[self.tab].section
  self.sel, self.scroll = 1, 0
  Covers.reset_pending()
  self:refresh()
end

function S:action(act)
  -- L2/R2 alternam as vistas de ROMs nos dois temas.
  if act == "l2" or act == "r2" then
    if self.section == "games" then
      local mode = change_view(act == "l2" and -1 or 1)
      self.cg_scroll, self.cv_pos = nil, self.sel
      Covers.reset_pending()
      self:clamp()
      App.toast("Visualização: " .. VIEW_NAMES[mode], "info")
    end
    return
  end
  local n = #self.items
  if active_view(self.section) == "grid" and n > 0 and (act == "up" or act == "down" or act == "left" or act == "right") then
    -- grade de capas: esquerda/direita andam 1, cima/baixo uma fileira
    local c = CG.COLS
    if act == "left" then self.sel = math.max(1, self.sel - 1)
    elseif act == "right" then self.sel = math.min(n, self.sel + 1)
    elseif act == "up" then if self.sel > c then self.sel = self.sel - c end
    else self.sel = math.min(n, self.sel + c) end
    self:clamp()
    return
  end
  if act == "up" and n > 0 then self.sel = (self.sel - 2) % n + 1; self:clamp()
  elseif act == "down" and n > 0 then self.sel = self.sel % n + 1; self:clamp()
  elseif act == "right" and n > 0 then self.sel = math.min(n, self.sel + VISIBLE); self:clamp()
  elseif act == "left" and n > 0 then self.sel = math.max(1, self.sel - VISIBLE); self:clamp()
  elseif act == "l1" then self:switch_tab(-1)
  elseif act == "r1" then self:switch_tab(1)
  elseif act == "a" and n > 0 and self.items[self.sel].builtin then App.push(self.items[self.sel].screen, { from = "store" })
  elseif act == "a" and n > 0 then App.push("details", { port = self.items[self.sel] })
  elseif act == "b" then App.pop()
  elseif act == "select" and n > 0 and self.items[self.sel].builtin then
    App.toast(L("Ferramentas integradas já ficam sempre aqui, em Manutenção."), "info")
  elseif act == "select" and n > 0 then
    local p = self.items[self.sel]
    local on = Favorites.toggle(p)
    App.toast(on and (p.name .. L(" adicionado aos favoritos")) or (p.name .. L(" removido dos favoritos")), "info")
    if self.favs then self:refresh() end
  elseif act == "x" then
    App.push("search", { from = "store", installed_only=self.installed_only,
      system=self.installed_only and self.filter:match("^cat:(.+)$") or nil })
  elseif act == "y" then
    App.refresh_catalog(true)
  end
end

return S
