-- Configuracoes: categorias em lista vertical, no mesmo estilo do menu principal.
-- Somente esta tela muda; as opcoes internas continuam em settings_cat.lua.
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local Icons = require("ui.icons")
local Defs = require("ui.settings_defs")
local lg = love.graphics

local S = {}

-- Mesma largura, linha e margem da lista do menu principal.
-- A coluna direita detalha a categoria selecionada, sem criar novas acoes.
local X, Y, W, ROW_H, VISIBLE = 20, 54, 300, 44, 8
local DX, DY, DW, DH = 340, 54, 280, 372

local function category_color(cat)
  return T.c[cat.color] or T.c.accent
end

function S:enter(p)
  self.sel = math.max(1, math.min(self.sel or 1, #Defs.LIST))
  self.top = self.top or 0
  if p and p.cat then
    for i, cat in ipairs(Defs.LIST) do
      if cat.id == p.cat then self.sel = i; break end
    end
  end
  self:follow()
end

-- Primeira opcao visivel: indice 0-based, como no menu principal.
function S:follow()
  local n = #Defs.LIST
  self.top = math.max(0, math.min(self.top or 0, math.max(0, n - VISIBLE)))
  if self.sel <= self.top then self.top = self.sel - 1 end
  if self.sel > self.top + VISIBLE then self.top = self.sel - VISIBLE end
  self.top = math.max(0, math.min(self.top, math.max(0, n - VISIBLE)))
end

local function draw_lines(font, s, x, y, w, max_h, ink)
  local f, lines, line_h = G.fit_lines(font, s or "", w, max_h, true)
  for i, line in ipairs(lines) do
    if (i - 1) * line_h + f:getHeight() > max_h then break end
    G.text(f, line, x, y + (i - 1) * line_h, ink)
  end
end

function S:draw()
  G.header(L("Configurações"))
  self:follow()
  local n = #Defs.LIST
  -- Lista de categorias: mesma selecao com fundo, contorno e barra lateral
  -- usada na coluna esquerda do menu principal (640x480).
  G.clip(14, Y, 314, VISIBLE * ROW_H)
  for i = self.top + 1, math.min(n, self.top + VISIBLE) do
    local cat = Defs.LIST[i]
    local y = Y + (i - self.top - 1) * ROW_H
    local on = (i == self.sel)
    if on then
      G.rect(X, y, W, ROW_H - 3, T.c.bg2, 8)
      G.frame(X, y, W, ROW_H - 3, T.c.accent, 8, 2)
      G.rect(X, y + 7, 4, ROW_H - 17, T.c.accent, 2)
    end
    Icons.draw(cat.icon, X + 16, y + 10, on and T.c.accent or T.c.dim, 1)
    G.text_fit(T.f.bodyb, cat.name, X + 48, y + 3, W - 60, on and T.c.text or T.c.dim)
    G.text_fit(T.f.small, cat.desc or "", X + 48, y + 23, W - 60, on and T.c.dim or T.c.faint)
  end
  G.unclip()

  if n > VISIBLE then
    G.color(T.c.accent2)
    local x = X + W + 7
    if self.top > 0 then
      lg.polygon("fill", x, Y + 4, x - 5, Y + 12, x + 5, Y + 12)
    end
    if self.top + VISIBLE < n then
      local bottom = Y + VISIBLE * ROW_H - 4
      lg.polygon("fill", x, bottom, x - 5, bottom - 8, x + 5, bottom - 8)
    end
  end

  local cat = Defs.LIST[self.sel]
  if cat then
    local c = category_color(cat)
    -- Painel direito: resumo da selecao, semelhante ao painel de destaque.
    G.panel(DX, DY, DW, DH, { bg = T.c.bg1 })
    G.rect(DX + 12, DY + 16, 4, 39, c, 2)
    Icons.draw(cat.icon, DX + 28, DY + 17, c, 1.6)
    local count = string.format("%d/%d", self.sel, n)
    G.text(T.f.small, count, DX + DW - 14 - T.f.small:getWidth(count), DY + 20, T.c.faint)

    draw_lines(T.f.h3, cat.name, DX + 18, DY + 83, DW - 36, 52, T.c.text)
    G.rect(DX + 18, DY + 144, DW - 36, 1, T.c.line)
    draw_lines(T.f.body, cat.desc, DX + 18, DY + 158, DW - 36, 106, T.c.dim)

    G.rect(DX + 18, DY + 279, DW - 36, 1, T.c.line)
    local ok, status = pcall(cat.status)
    if ok and status and tostring(status) ~= "" then
      draw_lines(T.f.bodyb, tostring(status), DX + 18, DY + 294, DW - 36, 60, c)
    end
  end

  local hints = { { "dpad", L("Navegar") }, { "a", L("Abrir") }, { "b", L("Voltar") } }
  G.hints(hints)
end

function S:action(act)
  local n = #Defs.LIST
  if act == "b" then App.pop(); return end
  if n == 0 then return end
  if act == "up" then self.sel = (self.sel - 2) % n + 1
  elseif act == "down" then self.sel = self.sel % n + 1
  elseif act == "l1" then self.sel = math.max(1, self.sel - VISIBLE)
  elseif act == "r1" then self.sel = math.min(n, self.sel + VISIBLE)
  elseif act == "a" then App.push("settings_cat", { id = Defs.LIST[self.sel].id }); return
  else return end
  self:follow()
end

return S
