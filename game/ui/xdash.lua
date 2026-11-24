-- =============================================================================
--  Tela inicial em PAINEL VERDE (layout "xdash": Neon Grid Edition)
--  Destaque vertical a esquerda, atalhos abaixo e menu de 3x3 a direita.
--    direcionais: navegar | A: abrir | X: detalhes do port | Y: pesquisar
--    L1/R1: trocar o destaque | B: sair/energia | SELECT: atualizar o hub
-- =============================================================================
local L = require("lib.i18n").L
local I18N = require("lib.i18n")
local T = require("ui.theme")
local G = require("ui.gfx")
local U = require("lib.util")
local C = require("config")
local Catalog = require("core.catalog")
local Covers = require("core.covers")
local Icons = require("ui.icons")
local lg = love.graphics

local XD = {}

-- blocos da direita (3 x 2) e atalhos do Guia Rapido
local function tiles()
  local out = {}
  for _, it in ipairs(require("ui.menu_entries").items()) do
    if it.id ~= "installed" and it.id ~= "favorites" and it.id ~= "downloads" then
      out[#out+1]=it
    end
  end
  return out
end

local LINKS = {
  { id = "installed", label = L("Instalados"), icon = "set_grid" },
  { id = "favorites", label = L("Favoritos"), icon = "set_favorites" },
  { id = "downloads", label = L("Downloads"), icon = "download" },
}

-- Destaque vertical e atalhos a esquerda; menu de 3x3 na direita.
local PX,PY,PW,PH=14,54,182,382
local RX,RW=208,418
local TY,TW,TH,TG=88,134,108,8
local function hero(S,self)
  return self.featured and self.featured[self.feat_i or 1]
end
function XD.update(S,self,dt)
  if self.ch_t then self.ch_t=self.ch_t+dt;if self.ch_t>.5 then self.ch_t=nil end end
  if self.dash_dirty then self.xd_tiles=tiles();self.dash_dirty=false end
end

local function draw_top(S, self)
  -- O nome do tema e a versao agora ficam no rodape.
  local lw=G.logo_box(14,2,268,48,"header")
  -- direita: hora, Wi-Fi e bateria
  local bw = S.draw_battery(self, 13, T.W - 16)
  local wx = T.W - 16 - bw - 26
  local _, wc, off = S.wifi_state()
  S.wifi_icon(wx, 12, wc, off)
  local clock = require("core.clock").time()
  local cf = T.base_font(T.f.bodyb)
  local cx = wx - 12 - cf:getWidth(clock)
  G.text(cf, clock, cx, 11, T.c.text)
  S.draw_update_notice(self,cx-16,math.floor(14+lw+18),12)
end

local function focus_glow(x, y, w, h, r)
  local fc = T.style.focus or T.c.accent
  local k = (App.pulse and App.animations()) and App.pulse(0.85, 0.15, 2.0) or 1
  for i = 6, 1, -1 do G.frame(x - i * 1.6, y - i * 1.6, w + i * 3.2, h + i * 3.2, fc, r + i * 1.6, 2, 0.07 * k) end
  G.frame(x, y, w, h, fc, r, 3, k)
end

local function draw_guide(S,self)
  local on_zone=self.xd_zone=="left"
  local x,y=PX+10,PY+10
  G.rect(PX+2,PY+4,PW,PH,T.c.shadow,8)
  G.rect(PX,PY,PW,PH,T.c.bg1,8,.94)
  G.text_fit(T.f.bodyb,U.upper(I18N.tr(L("Em destaque"))),x,y,PW-20,T.c.accent)
  local p=hero(S,self)
  local cx,cy,cw,ch=PX+13,PY+34,PW-26,202
  if p then
    G.cover(Covers.get(p),p,cx,cy,cw,ch,Covers.is_loading(p),App.t,{borderless=true,stretch=true})
    G.text_fit(T.f.bodyb,p.name,x,cy+208,PW-20,T.c.text)
    G.text_fit(T.f.small,p.category or "",x,cy+227,PW-20,T.c.dim)
  else
    G.rect(cx,cy,cw,ch,T.c.bg2,4)
    Icons.draw("games",cx+cw/2-14,cy+ch/2-14,T.c.faint,28/24)
    G.text_fit(T.f.small,L("Nenhum destaque no momento"),x,cy+208,PW-20,T.c.dim)
  end
  if on_zone and self.xd_left==1 then
    G.frame(PX+4,PY+4,PW-8,276,T.style.focus or T.c.accent,6,2)
  end
  local ay=PY+282
  G.text_fit(T.f.bodyb,L("Atalhos"),x,ay,PW-20,T.c.text)
  for j,it in ipairs(LINKS) do
    local on=on_zone and self.xd_left==j+1
    local ly=ay+24+(j-1)*24
    if on then G.rect(PX+4,ly-3,PW-8,23,T.style.focus or T.c.accent,4) end
    local c=on and T.c.bg0 or T.c.dim
    Icons.draw(it.icon,x,ly,c,18/24)
    local lab=I18N.tr(it.label)
    if it.id=="downloads" then
      local D=require("core.downloads")
      local n=(D.active() and 1 or 0)+D.waiting_count()
      if n>0 then lab=lab.."  ("..n..")" end
    end
    G.text_fit(T.f.body,lab,x+26,ly,PW-44,on and T.c.bg0 or T.c.text)
  end
end

local function draw_tiles(S, self)
  local list = self.xd_tiles
  local page=math.floor((math.max(1,self.xd_right or 1)-1)/9)
  local first=page*9+1
  for i=first,math.min(#list,first+8) do
    local it=list[i]
    local slot=i-first
    local c, r = slot % 3, math.floor(slot / 3)
    local x = RX + c * (TW + TG)
    local y = TY + r * (TH + TG)
    local on = self.xd_zone == "right" and self.xd_right == i
    local fc = T.style.focus or T.c.accent
    G.rect(x + 2, y + 4, TW, TH, T.c.shadow, 6)
    if on then
      for g = 4, 1, -1 do G.frame(x - g * 1.5, y - g * 1.5, TW + g * 3, TH + g * 3, fc, 6 + g * 1.5, 2, 0.08) end
      G.rect(x, y, TW, TH, fc, 6)
    else
      G.rect(x, y, TW, TH, T.c.bg2, 6, 0.95)
      G.frame(x, y, TW, TH, T.c.line, 6, 1)
    end
    local ic = on and T.c.bg0 or T.c.text
    Icons.draw(it.icon, x + TW / 2 - 17, y + 14, ic, 34 / 24)
    local lab = U.upper(I18N.tr(it.label))
    local f, ls, lh = G.fit_lines(T.f.bodyb, lab, TW - 16, 2 * T.base_font(T.f.bodyb):getHeight())
    local ly = y + TH - 10 - #ls * lh
    for k, l in ipairs(ls) do G.text(f, l, x + 10, ly + (k - 1) * lh, ic) end
  end
end

function XD.draw(S,self)
  self.xd_zone=self.xd_zone or "right"
  self.xd_tiles=self.xd_tiles or tiles()
  self.xd_right=math.max(1,math.min(#self.xd_tiles,self.xd_right or 1))
  self.xd_left=math.max(1,math.min(4,self.xd_left or 1))
  draw_top(S,self)
  draw_guide(S,self)
  G.text(T.f.h1,U.upper(I18N.tr(L("Início"))),RX,50,T.c.text)
  draw_tiles(S,self)
  if #self.xd_tiles>9 then
    G.text(T.f.small,string.format("%d/%d",math.floor((self.xd_right-1)/9)+1,math.ceil(#self.xd_tiles/9)),T.W-68,50,T.c.faint)
  end
  local hints={{"b",C.OS_MODE and L("Energia") or L("Sair")},{"a",L("Selecionar")},{"y",L("Pesquisar")},{"l1",""},{"r1",L("Destaque")}}
  if require("core.updnotice").pending() then hints[#hints+1]={"select",L("Atualizar")} end
  local Themes=require("core.themes")
  local th=Themes.by_id and Themes.by_id[Themes.current]
  G.hints(hints,nil,T.W-146,true)
  G.menu_identity(th and th.name or "Matrix Edition",C.VERSION,T.W-12,nil,124)
end

function XD.action(S,self,act)
  self.xd_zone=self.xd_zone or "right"
  self.xd_tiles=self.xd_tiles or tiles()
  local n=#self.xd_tiles
  self.xd_right=math.max(1,math.min(n,self.xd_right or 1))
  self.xd_left=math.max(1,math.min(4,self.xd_left or 1))
  if act=="b" then
    if require("core.prefs").get("exit_mode")=="quit" and not C.OS_MODE then App.quit() else S.exit_dialog() end
    return
  elseif act=="select" and require("core.updnotice").pending() then App.push("update");return
  elseif act=="y" then App.push("search");return
  elseif act=="l1" or act=="r1" then S.feat_go(self,act=="r1" and 1 or -1,true);return end
  local right=self.xd_zone=="right"
  local i=right and self.xd_right or self.xd_left
  if act=="a" then
    if right then local it=self.xd_tiles[i];if it then S.open(it.id) end
    elseif i==1 then local p=hero(S,self);if p then App.push("details",{port=p}) else S.open("store") end
    else S.open(LINKS[i-1].id) end
    return
  elseif act=="x" then
    if not right and i==1 then local p=hero(S,self);if p then App.push("details",{port=p}) end end
    return
  end
  if right then
    local col=(i-1)%3
    if act=="up" and i>3 then self.xd_right=i-3
    elseif act=="down" and i+3<=n then self.xd_right=i+3
    elseif act=="left" then
      if col==0 then self.xd_zone="left";self.xd_left=i>=7 and 2 or 1
      else self.xd_right=i-1 end
    elseif act=="right" and i<n then self.xd_right=i+1 end
  else
    if act=="up" then self.xd_left=math.max(1,i-1)
    elseif act=="down" then self.xd_left=math.min(4,i+1)
    elseif act=="right" then self.xd_zone="right";self.xd_right=i==1 and 1 or math.min(n,7) end
  end
end

return XD
