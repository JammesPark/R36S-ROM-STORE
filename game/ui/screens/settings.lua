-- Configuracoes: lista lateral e painel direito compartilhado com a categoria aberta.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Icons=require("ui.icons")
local Defs=require("ui.settings_defs")
local S={}
local X,Y,W,RH,VIS=14,52,194,43,9
local DX,DY,DW,DH=220,52,406,384

function S.index(id)
  for i,c in ipairs(Defs.LIST) do if c.id==id then return i end end
  return 1
end
function S.sidebar(sel,top,focused)
  local n=#Defs.LIST
  top=math.max(0,math.min(top or 0,math.max(0,n-VIS)))
  if sel<=top then top=sel-1 end
  if sel>top+VIS then top=sel-VIS end
  G.panel(X,Y,W,DH,{bg=T.c.bg1})
  G.clip(X+2,Y+2,W-4,DH-4)
  for i=top+1,math.min(n,top+VIS) do
    local cat=Defs.LIST[i]
    local y=Y+3+(i-top-1)*RH
    local on=i==sel
    if on then
      G.rect(X+3,y,W-6,RH-4,T.c.bg2,6)
      G.frame(X+3,y,W-6,RH-4,focused and T.c.accent or T.c.line,6,focused and 2 or 1)
      G.rect(X+3,y+6,3,RH-16,T.c.accent,2)
    end
    Icons.draw(cat.icon,X+12,y+8,on and T.c.accent or T.c.dim,.9)
    G.text_fit(T.f.bodyb,cat.name,X+38,y+12,W-49,on and T.c.text or T.c.dim)
  end
  G.unclip()
  return top
end
function S:enter(p)
  self.sel=p and p.cat and S.index(p.cat) or self.sel or 1
  self.top=self.top or 0
end
function S:draw()
  G.header(L("Configurações"))
  self.top=S.sidebar(self.sel,self.top,true)
  local cat=Defs.LIST[self.sel]
  G.panel(DX,DY,DW,DH,{bg=T.c.bg1})
  if cat then
    local c=T.c[cat.color] or T.c.accent
    Icons.draw(cat.icon,DX+18,DY+17,c,1.5)
    G.text_fit(T.f.h3,cat.name,DX+62,DY+23,DW-80,T.c.text)
    G.rect(DX+16,DY+66,DW-32,1,T.c.line)
    local f,lines,lh=G.fit_lines(T.f.body,cat.desc or "",DW-32,190,true)
    for i,line in ipairs(lines) do G.text(f,line,DX+16,DY+82+(i-1)*lh,T.c.dim) end
    G.text(T.f.small,L("Pressione A para abrir as opções."),DX+16,DY+320,T.c.faint)
  end
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
