-- Teste runtime puro: nao permite textos e cartoes invadir status, previews
-- ou rodape na tela 640x480, em fontes normais e ampliadas.
package.path="src/?.lua;src/?/init.lua;"..package.path
local rec = {}
local function event(tp,t) t.type=tp;rec[#rec+1]=t;return t end
local function font(h)
  return {getHeight=function()return h end,getWidth=function(_,s)return #tostring(s or "")*(h*0.58) end}
end
local T={c=setmetatable({}, {__index=function(_,k)return k end}),f={},W=640,H=480}
local G={}
local function text_event(tp,f,s,x,y,w)
  event(tp,{s=tostring(s or ""),x=x,y=y,w=w or 0,h=f:getHeight()})
end
G.header=function(...)event("header",{})end
G.text_fit=function(f,s,x,y,w)text_event("textfit",f,s,x,y,w)end
G.text=function(f,s,x,y,_,align,w)text_event("text",f,s,x,y,w)end
G.panel=function(x,y,w,h,...) event("panel",{x=x,y=y,w=w,h=h}) end
G.rect=function(x,y,w,h,...) event("rect",{x=x,y=y,w=w,h=h}) end
G.frame=function()end
G.clip=function(x,y,w,h) event("clip",{x=x,y=y,w=w,h=h}) end
G.unclip=function()event("unclip",{})end
G.fit_lines=function(f,s,w,maxh)
  local lines={}
  local n=math.min(5,math.floor(maxh / f:getHeight()))
  for i=1,n do lines[#lines+1]="Linha "..i.." da descricao" end
  return f,lines,f:getHeight(),n<5
end
G.step=function(f,n)return math.max(f:getHeight(),n) end
G.tag=function(s,x,y,_,_,f)
  event("tag",{s=s,x=x,y=y,w=(f and f:getWidth(s) or 48)+12,h=(f and f:getHeight() or 8)+8})
  return (f and f:getWidth(s) or 48)+12
end
G.progress=function(x,y,w,h)event("progress",{x=x,y=y,w=w,h=h})end
G.progress_busy=G.progress
G.hints=function(list)
  local size=14
  for _,hint in ipairs(list) do
    local icon=(hint[1]=="select") and 58 or 16
    size=size+icon+6+T.f.small:getWidth(hint[2])+16
  end
  event("hints",{y=454,labels=list,width=size})
  assert(size<630,"Dicas de botoes ultrapassam 640: "..size)
end
package.loaded["ui.theme"]=T
package.loaded["ui.gfx"]=G
package.loaded["lib.i18n"]={L=function(s)return s end,tr=function(s)return s end}
package.loaded["config"]={TMP_DIR="/tmp"}
package.loaded["lib.util"]={
 clamp=function(n,mi,ma)return math.max(mi,math.min(ma,n))end,
 upper=function(s)return tostring(s):upper()end,
 read_file=function()end,
}
package.loaded["core.fetcher"]={}
local Themes={current="chosen",list={},by_id={},scan=function()end}
package.loaded["core.themes"]=Themes
local M={items={},source="online",state="ready",job=nil,
  status=function(p)return p.status or "available" end,
  refresh=function(_,fn)if fn then fn(true) end end}
package.loaded["core.theme_store"]=M
love={graphics={
  setColor=function()end,
  newImage=function()error("sem imagem")end,
  draw=function()end,
  rectangle=function()end,
}}
App={t=1}
local Store=require("ui.screens.theme_store")
local ThemeScreen=require("ui.screens.themes")
local function check_store(status)
  local list=0
  local right=0
  local info=0
  local preview
  for _,c in ipairs(rec) do
    if c.type=="panel" and c.x==12 and c.y>=70 and c.y<400 then
      list=list+1
      assert(c.y+c.h<=390,"Lista invade status: "..c.y)
    elseif c.type=="panel" and c.x==284 then
      preview=c
      assert(c.y==70 and c.y+c.h==390,"Preview fora da caixa")
    elseif c.type=="text" or c.type=="textfit" then
      if c.x>=284 and c.x<640 and c.y>=70 then
        right=right+1
        assert(c.y+c.h<=390,"Texto da previa invade rodape: "..c.s)
      elseif c.x<284 and c.y>=70 and c.y<400 then
        assert(c.y+c.h<=390,"Texto da lista invade rodape: "..c.s)
      elseif c.y>=400 and c.y<448 then
        info=info+1
        assert(c.y+c.h<=448,"Aviso invade dicas")
      end
    elseif c.type=="progress" then
      assert(c.y>=402 and c.y+c.h<448,"Progresso cruza dicas")
    end
  end
  assert(preview and list==5 and right>=2)
  assert(info>0,status.." nao mostrou andamento")
end
local function fonts(delta)
  T.f={small=font(12+delta),body=font(14+delta),bodyb=font(14+delta),
    h3=font(16+delta),pix8=font(8),pix16=font(16)}
end
for _,extra in ipairs({0,3}) do
  fonts(extra)
  M.items={}
  for i=1,7 do
    M.items[i]={id="test_"..i,name="Tema longo com nome "..i,version="1.5.22",
      author="Autor com nome muito extenso para a faixa",status="available",
      description=string.rep("Descricao detalhada da interface. ",30)}
  end
  M.job={name="Tema de teste com título longo",phase="download",total=100,done=44}
  local page=setmetatable({}, {__index=Store})
  page:enter()
  page.sel=7
  rec={}
  page:draw()
  check_store("download")
  M.job=nil
  page.msg="Falha na conexao - mostrar cache local em todas as telas"
  rec={}
  page:draw()
  check_store("erro de rede")
  M.job=nil
  Themes.list={{
    id="chosen",name="Tema escolhido",builtin=true,version="2.0",
    description=string.rep("Descricao comprida. ",40),
    colors={bg0={1,1,1},bg1={1,1,1},accent={1,1,1},accent2={1,1,1}}
  }}
  Themes.by_id={chosen=Themes.list[1]}
  local screen=setmetatable({}, {__index=ThemeScreen})
  screen:enter()
  screen.sel=2
  rec={}
  screen:draw()
  local badge,sub,status
  for _,c in ipairs(rec) do
    if c.type=="tag" and c.s=="EM USO" then badge=c end
    if c.type=="textfit" and c.s:find("Incluso no app",1,true) then sub=c end
    if c.type=="text" and c.s=="TEMA EM USO" then status=c end
    if c.type=="clip" and c.x>=274 and c.y>300 then
      assert(c.y+c.h<=399,"Descricao do tema invade selo inferior")
    end
  end
  assert(badge and sub and status,"Selo do tema ativo nao apareceu")
  assert(sub.x+sub.w<=badge.x-4,"Texto da versao invade selo EM USO")
  assert(status.y>=412,"Selo inferior fora do rodape")
end
print("Baixar Temas: 5 cards, status, preview, fontes normais/grandes e EM USO sem conflitos: OK")
