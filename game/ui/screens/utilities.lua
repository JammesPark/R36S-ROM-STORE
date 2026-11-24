-- Utilitarios: categorias na esquerda, descricao e ferramentas na direita.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Icons=require("ui.icons")
local Catalog=require("core.catalog")
local Tools=require("core.tools")
local Favorites=require("core.favorites")
local S={}
local P=require("ui.side_panel")
local VIS=P.VIS
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
  cats[#cats+1]={id="installed",name=L("Instalados"),icon="set_grid",desc=L("Utilitários instalados no console.")}
  self.cats=cats;self.sel=1
  if old then for i,c in ipairs(cats) do if c.id==old.id then self.sel=i;break end end end
  self:rebuild()
end
function S:rebuild()
  local cat=self.cats[self.sel];local list={}
  local filter=cat.id=="all" and "all" or (cat.id=="installed" and "installed" or "cat:"..cat.id)
  for _,t in ipairs(Tools.for_filter("tools",filter)) do list[#list+1]=t end
  for _,p in ipairs(Catalog.filter(filter,App.status,"tools")) do list[#list+1]=p end
  self.rows=list;self.row,self.rowtop=1,0
  if self.sel<=self.top then self.top=self.sel-1 end
  if self.sel>self.top+VIS then self.top=self.sel-VIS end
end
function S:resume() self:on_catalog() end
function S:draw()
  G.header(L("Utilitários"))
  self.top=P.sidebar(self.cats,self.sel,self.top,self.focus=="categories")
  local cat=self.cats[self.sel]
  local selected=self.rows[self.row]
  if self.focus=="categories" then
    P.summary(cat,#self.rows==0 and L("Nenhuma ferramenta nesta categoria.") or nil)
  else
    local c=T.c[cat.color] or T.c.accent
    P.heading(cat,c)
    for i=self.rowtop+1,math.min(#self.rows,self.rowtop+P.VISIBLE) do
      local tool=self.rows[i]
      local y=P.LIST_Y+(i-self.rowtop-1)*(P.ROW_H+P.GAP)
      local on=i==self.row
      P.row(y,on,c)
      Icons.draw(tool.icon or "tools",P.DX+12,y+9,on and c or T.c.dim,1)
      G.text_fit(T.f.bodyb,tool.name,P.DX+44,y+12,P.DW-74,on and T.c.text or T.c.dim)
    end
    P.scrollbar(#self.rows,self.rowtop,c)
    local description=selected and (selected.builtin and (selected.short or "") or Catalog.text(selected,"short")) or ""
    P.description(cat,selected and selected.name,description,c)
  end
  local hints={{"dpad",L("Navegar")},{"a",L("Abrir")},{"b",L("Voltar")},{"x",L("Pesquisar")},{"y",L("Atualizar")}}
  if self.focus=="rows" and selected and not selected.builtin then hints[#hints+1]={"select",L("Favorito")} end
  G.hints(hints)
end
function S:action(act)
  if act=="x" then App.push("search",{from="utilities",section="tools"});return end
  if act=="y" then App.refresh_catalog(true);return end
  if self.focus=="categories" then
    if act=="b" then App.pop();return end
    if act=="up" then self.sel=(self.sel-2)%#self.cats+1;self:rebuild()
    elseif act=="down" then self.sel=self.sel%#self.cats+1;self:rebuild()
    elseif act=="l1" then self.sel=math.max(1,self.sel-VIS);self:rebuild()
    elseif act=="r1" then self.sel=math.min(#self.cats,self.sel+VIS);self:rebuild()
    elseif (act=="a" or act=="right") and #self.rows>0 then self.focus="rows" end
  else
    if act=="b" or act=="left" then self.focus="categories";return end
    local n=#self.rows
    if n==0 then self.focus="categories";return end
    if act=="up" then self.row=(self.row-2)%n+1
    elseif act=="down" then self.row=self.row%n+1
    elseif act=="select" then
      local p=self.rows[self.row]
      if not p.builtin then
        local on=Favorites.toggle(p)
        App.toast(on and L("Adicionado aos favoritos") or L("Removido dos favoritos"),"info")
      end
    elseif act=="a" then
      local p=self.rows[self.row]
      if p.builtin then App.push(p.screen,{from="store"}) else App.push("details",{port=p}) end
    end
    if self.row<=self.rowtop then self.rowtop=self.row-1 end
    if self.row>self.rowtop+P.VISIBLE then self.rowtop=self.row-P.VISIBLE end
  end
end
return S
