-- Layout unico de Configuracoes e Utilitarios (640x480).
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Icons=require("ui.icons")
local P={X=14,Y=52,W=194,RH=42,VIS=9,DX=220,DY=52,DW=406,DH=384,
  LIST_Y=84,ROW_H=42,GAP=4,VISIBLE=5,FOOT_Y=318}
function P.sidebar(cats,sel,top,focused)
  local X,Y,W,RH,VIS,DH=P.X,P.Y,P.W,P.RH,P.VIS,P.DH
  local n=#cats
  top=math.max(0,math.min(top or 0,math.max(0,n-VIS)))
  if sel<=top then top=sel-1 end
  if sel>top+VIS then top=sel-VIS end
  top=math.max(0,top)
  G.panel(X,Y,W,DH,{bg=T.c.bg1})
  G.clip(X+2,Y+2,W-4,DH-4)
  for i=top+1,math.min(n,top+VIS) do
    local cat=cats[i]
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
function P.summary(cat,prompt)
  local x,y,w,h=P.DX,P.DY,P.DW,P.DH
  G.panel(x,y,w,h,{bg=T.c.bg1})
  if not cat then return end
  local c=T.c[cat.color] or T.c.accent
  Icons.draw(cat.icon,x+18,y+17,c,1.5)
  G.text_fit(T.f.h3,cat.name,x+62,y+23,w-80,T.c.text)
  G.rect(x+16,y+66,w-32,1,T.c.line)
  local f,lines,lh=G.fit_lines(T.f.body,cat.desc or "",w-32,190,true)
  for i,line in ipairs(lines) do G.text(f,line,x+16,y+82+(i-1)*lh,T.c.dim) end
  G.text_fit(T.f.small,prompt or L("Pressione A para abrir as opções."),x+16,y+320,w-32,T.c.faint)
end
function P.heading(cat,c)
  G.text_fit(T.f.bodyb,cat.name,P.DX+8,55,P.DW-16,c)
end
function P.row(y,on,c)
  G.panel(P.DX,y,P.DW,P.ROW_H,{bg=on and T.c.bg3 or T.c.bg1,border=on and c or T.c.line,lw=on and 2 or 1})
  if on then G.rect(P.DX,y+8,4,P.ROW_H-16,c,2) end
end
function P.scrollbar(n,top,c)
  if n<=P.VISIBLE then return end
  local track=P.VISIBLE*(P.ROW_H+P.GAP)-P.GAP
  local hh=track*P.VISIBLE/n
  G.rect(T.W-8,P.LIST_Y+(track-hh)*(top/(n-P.VISIBLE)),3,hh,c,1,.7)
end
function P.description(cat,label,desc,c)
  local x,w,y=P.DX,P.DW,P.FOOT_Y
  local h=436-y
  G.panel(x,y,w,h,{bg=T.c.bg1})
  G.rect(x,y,4,h,c,2)
  G.text_fit(T.f.small,cat.desc or "",x+12,y+7,w-24,T.c.faint)
  if label then
    G.text_fit(T.f.bodyb,label,x+12,y+26,w-24,T.c.text)
    local ty=y+48
    local f,lines,lh=G.fit_lines(T.f.small,desc or "",w-24,y+h-6-ty,true)
    for k,line in ipairs(lines) do G.text(f,line,x+12,ty+(k-1)*lh,T.c.dim) end
  end
end
return P
