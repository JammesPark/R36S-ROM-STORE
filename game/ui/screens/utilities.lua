-- Utilitarios: categorias na esquerda, descricao e ferramentas na direita.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Icons=require("ui.icons")
local Catalog=require("core.catalog")
local Tools=require("core.tools")
local S={}
local X,Y,W,RH,VIS=14,52,194,43,9
local DX,DY,DW,DH=220,52,406,384
local desc={manutencao="Verificação, análise e manutenção do cartão e do sistema.",
 diagnostico_do_sistema="Diagnóstico de rede e informações do sistema.",
 testes_de_controles="Teste dos analógicos e botões do console.",
 ferramentas_de_sistema="Ferramentas adicionais para o sistema."}
function S:enter()
  self.sel,self.top,self.row,self.rowtop=1,0,1,0
  self.focus="categories";self:on_catalog()
end
function S:on_catalog()
  local old=self.cats and self.cats[self.sel]
  local cats={{id="all",name=L("Todos"),icon="tools",desc=L("Todas as ferramentas disponíveis no Hub.")}}
  local seen={all=true}
  local function add(c)
    if c.id and not seen[c.id] then
      seen[c.id]=true
      cats[#cats+1]={id=c.id,name=c.name or c.id,icon=c.icon or "tools",desc=L(desc[c.id] or "Ferramentas desta categoria.")}
    end
  end
  for _,c in ipairs(Catalog.categories) do if c.section=="tools" then add(c) end end
  for _,t in ipairs(Tools.LIST) do add({id=t.category_id,name=t.category,icon=t.icon}) end
  self.cats=cats;self.sel=1
  if old then for i,c in ipairs(cats) do if c.id==old.id then self.sel=i;break end end end
  self:rebuild()
end
function S:rebuild()
  local cat=self.cats[self.sel];local list={}
  local filter=cat.id=="all" and "all" or "cat:"..cat.id
  for _,t in ipairs(Tools.for_filter("tools",filter)) do list[#list+1]=t end
  for _,p in ipairs(Catalog.filter(filter,nil,"tools")) do list[#list+1]=p end
  self.rows=list;self.row,self.rowtop=1,0
  if self.sel<=self.top then self.top=self.sel-1 end
  if self.sel>self.top+VIS then self.top=self.sel-VIS end
end
function S:resume() self:on_catalog() end
function S:draw()
  G.header(L("Utilitários"))
  G.panel(X,Y,W,DH,{bg=T.c.bg1})
  G.clip(X+2,Y+2,W-4,DH-4)
  for i=self.top+1,math.min(#self.cats,self.top+VIS) do
    local cat=self.cats[i];local y=Y+3+(i-self.top-1)*RH;local on=i==self.sel
    if on then G.rect(X+3,y,W-6,RH-4,T.c.bg2,6);G.frame(X+3,y,W-6,RH-4,self.focus=="categories" and T.c.accent or T.c.line,6,2) end
    Icons.draw(cat.icon,X+12,y+8,on and T.c.accent or T.c.dim,.9)
    G.text_fit(T.f.bodyb,cat.name,X+38,y+12,W-49,on and T.c.text or T.c.dim)
  end
  G.unclip()
  local cat=self.cats[self.sel]
  G.panel(DX,DY,DW,DH,{bg=T.c.bg1})
  G.text_fit(T.f.h3,cat.name,DX+12,DY+12,DW-24,T.c.text)
  local f,lines,lh=G.fit_lines(T.f.small,cat.desc,DW-24,42,true)
  for i,line in ipairs(lines) do G.text(f,line,DX+12,DY+39+(i-1)*lh,T.c.dim) end
  local listY=DY+88
  for i=self.rowtop+1,math.min(#self.rows,self.rowtop+5) do
    local p=self.rows[i];local y=listY+(i-self.rowtop-1)*38
    local on=self.focus=="rows" and i==self.row
    G.panel(DX+8,y,DW-16,34,{bg=on and T.c.bg3 or T.c.bg0,border=on and T.c.accent or T.c.line})
    Icons.draw(p.icon or "tools",DX+17,y+6,on and T.c.accent or T.c.dim,.8)
    G.text_fit(T.f.bodyb,p.name,DX+46,y+8,DW-62,on and T.c.text or T.c.dim)
  end
  if #self.rows==0 then G.text(T.f.small,L("Nenhuma ferramenta nesta categoria."),DX+12,listY+12,T.c.faint) end
  local selected=self.rows[self.row]
  local description=selected and (selected.builtin and selected.short or Catalog.text(selected,"short")) or ""
  G.rect(DX+12,DY+284,DW-24,1,T.c.line)
  local df,dl,dh=G.fit_lines(T.f.small,description or "",DW-24,80,true)
  for i,line in ipairs(dl) do G.text(df,line,DX+12,DY+296+(i-1)*dh,T.c.dim) end
  G.hints({{"dpad",L("Navegar")},{"a",self.focus=="rows" and L("Abrir") or L("Selecionar")},{"b",L("Voltar")},{"x",L("Pesquisar")}})
end
function S:action(act)
  if act=="x" then App.push("search",{from="utilities"});return end
  if self.focus=="categories" then
    if act=="b" then App.pop();return end
    if act=="up" then self.sel=(self.sel-2)%#self.cats+1;self:rebuild()
    elseif act=="down" then self.sel=self.sel%#self.cats+1;self:rebuild()
    elseif (act=="a" or act=="right") and #self.rows>0 then self.focus="rows" end
  else
    if act=="b" or act=="left" then self.focus="categories";return end
    local n=#self.rows
    if n==0 then self.focus="categories";return end
    if act=="up" then self.row=(self.row-2)%n+1
    elseif act=="down" then self.row=self.row%n+1
    elseif act=="a" then
      local p=self.rows[self.row]
      if p.builtin then App.push(p.screen,{from="store"}) else App.push("details",{port=p}) end
    end
    if self.row<=self.rowtop then self.rowtop=self.row-1 end
    if self.row>self.rowtop+5 then self.rowtop=self.row-5 end
  end
end
return S
