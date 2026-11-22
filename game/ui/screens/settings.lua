-- Configuracoes: lista de categorias a esquerda e opcoes na mesma tela a direita.
-- Tema Padrao 640x480. Mantem as acoes originais de settings_cat.lua.
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local Icons = require("ui.icons")
local Defs = require("ui.settings_defs")
local Inner = require("ui.screens.settings_cat")
local lg = love.graphics

local S = {}
local X, Y, W, ROW, VIS = 12, 52, 204, 36, 10
local RX, RY, RW, RH = 226, 52, 402, 378

function S:enter(p)
  self.sel = math.max(1, math.min(self.sel or 1, #Defs.LIST))
  self.top = self.top or 0
  self.focus, self.inner = "categories", nil
  if p and p.cat then
    for i, cat in ipairs(Defs.LIST) do
      if cat.id == p.cat then self.sel = i; break end
    end
  end
  self:follow()
end

function S:follow()
  local n = #Defs.LIST
  self.top = math.max(0, math.min(self.top or 0, math.max(0, n - VIS)))
  if self.sel <= self.top then self.top = self.sel - 1 end
  if self.sel > self.top + VIS then self.top = self.sel - VIS end
end

function S:open_category()
  local cat = Defs.LIST[self.sel]
  if not cat then return end
  if not self.inner or not self.inner.cat or self.inner.cat.id ~= cat.id then
    self.inner = setmetatable({}, { __index = Inner })
    self.inner:enter({ id = cat.id })
  end
  self.focus = "options"
end

function S:resume()
  if self.inner and self.inner.resume then self.inner:resume() end
end

function S:on_language()
  if self.inner and self.inner.on_language then self.inner:on_language() end
end

function S:update(dt)
  if self.inner and self.focus == "options" then self.inner:update(dt) end
end

local function lines(font, str, x, y, w, h, ink)
  local fit, txts, lh = G.fit_lines(font, str or "", w, h, true)
  for i, line in ipairs(txts) do
    if (i - 1) * lh + fit:getHeight() > h then break end
    G.text(fit, line, x, y + (i - 1) * lh, ink)
  end
end

function S:draw()
  G.header(L("Configurações"))
  self:follow()
  G.clip(X - 2, Y, W + 4, VIS * ROW)
  for i = self.top + 1, math.min(#Defs.LIST, self.top + VIS) do
    local cat = Defs.LIST[i]
    local y = Y + (i - self.top - 1) * ROW
    local on = i == self.sel
    local c = T.c[cat.color] or T.c.accent
    if on then
      G.rect(X, y, W, ROW - 3, T.c.bg2, 7)
      G.frame(X, y, W, ROW - 3, self.focus == "categories" and T.c.accent or T.c.line, 7, self.focus == "categories" and 2 or 1)
      G.rect(X, y + 6, 4, ROW - 15, c, 2)
    end
    Icons.draw(cat.icon, X + 13, y + 7, on and c or T.c.dim, 0.84)
    -- Descricoes apenas no painel direito; a lista lateral mostra so o nome.
    G.text_fit(T.f.bodyb, cat.name, X + 41, y + 8, W - 50, on and T.c.text or T.c.dim)
  end
  G.unclip()
  if #Defs.LIST > VIS then
    local track = VIS * ROW
    local size = track * VIS / #Defs.LIST
    G.rect(X + W + 2, Y + (track - size) * (self.top / (#Defs.LIST - VIS)), 3, size, T.c.accent2, 2, 0.7)
  end

  local cat = Defs.LIST[self.sel]
  if self.inner and self.inner.cat and cat and self.inner.cat.id == cat.id then
    self.inner:draw_embedded(RX, RY, RW, RH, self.focus == "options")
  elseif cat then
    local c = T.c[cat.color] or T.c.accent
    G.panel(RX, RY, RW, RH, { bg = T.c.bg1 })
    G.rect(RX + 14, RY + 16, 4, 42, c, 2)
    Icons.draw(cat.icon, RX + 31, RY + 21, c, 1.4)
    G.text_fit(T.f.h3, cat.name, RX + 20, RY + 87, RW - 40, T.c.text)
    G.rect(RX + 20, RY + 126, RW - 40, 1, T.c.line)
    lines(T.f.body, cat.desc, RX + 20, RY + 145, RW - 40, 100, T.c.dim)
    G.rect(RX + 20, RY + 267, RW - 40, 1, T.c.line)
    local ok, status = pcall(cat.status)
    if ok and status and tostring(status) ~= "" then
      lines(T.f.bodyb, tostring(status), RX + 20, RY + 280, RW - 40, 42, c)
    end
    G.text(T.f.small, L("Pressione A para abrir as opções neste painel."), RX + 20, RY + RH - 29, T.c.faint)
  end

  local hints
  if self.focus == "options" then
    local r = self.inner and self.inner.rows and self.inner.rows[self.inner.sel]
    local label = r and r.kind == "toggle" and L("Alternar") or (r and r.kind == "info" and L("Navegar") or L("Selecionar"))
    hints = { { "dpad", L("Navegar / ajustar") }, { "a", label }, { "b", L("Categorias") } }
  else
    hints = { { "dpad", L("Navegar") }, { "a", L("Abrir opções") }, { "b", L("Voltar") } }
  end
  G.hints(hints)
end

function S:action(act)
  local n = #Defs.LIST
  if self.focus == "options" then
    if act == "b" then self.focus = "categories"; return end
    if self.inner then
      if act == "l1" or act == "r1" then
        local delta = act == "l1" and -5 or 5
        self.inner.sel = math.max(1, math.min(#self.inner.rows, self.inner.sel + delta))
      else
        self.inner:action(act)
      end
    end
    return
  end
  if act == "b" then App.pop(); return end
  if n == 0 then return end
  local old = self.sel
  if act == "up" then self.sel = (self.sel - 2) % n + 1
  elseif act == "down" then self.sel = self.sel % n + 1
  elseif act == "l1" then self.sel = math.max(1, self.sel - VIS)
  elseif act == "r1" then self.sel = math.min(n, self.sel + VIS)
  elseif act == "a" or act == "right" then self:open_category(); return
  else return end
  if old ~= self.sel then self.inner = nil end
  self:follow()
end

return S
