-- Configuracoes: lista lateral e painel direito compartilhado com a categoria aberta.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Icons=require("ui.icons")
local Defs=require("ui.settings_defs")
local S={}
local P=require("ui.side_panel")
local VIS=P.VIS

function S.index(id)
  for i,c in ipairs(Defs.LIST) do if c.id==id then return i end end
  return 1
end
function S.sidebar(sel,top,focused)
  return P.sidebar(Defs.LIST,sel,top,focused)
end
function S:enter(p)
  self.sel=p and p.cat and S.index(p.cat) or self.sel or 1
  self.top=self.top or 0
end
function S:draw()
  G.header(L("Configurações"))
  self.top=S.sidebar(self.sel,self.top,true)
  P.summary(Defs.LIST[self.sel])
  G.hints({{"dpad",L("Navegar")},{"a",L("Abrir")},{"b",L("Voltar")}})
end
function S:action(act)
  local n=#Defs.LIST
  if act=="b" then App.pop();return end
  if n==0 then return end
  if act=="up" then self.sel=(self.sel-2)%n+1
  elseif act=="down" then self.sel=self.sel%n+1
  elseif act=="l1" then self.sel=math.max(1,self.sel-VIS)
  elseif act=="r1" then self.sel=math.min(n,self.sel+VIS)
  elseif act=="a" then App.push("settings_cat",{id=Defs.LIST[self.sel].id,sidebar_top=self.top}) end
end
return S
