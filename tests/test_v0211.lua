-- Regressão v0.2.11: alinhamento em 640x480, botões e capa de preview limpa.
package.path='src/?.lua;'..package.path
local texts,buttons,rects,circles,posters={},{},{},{},{}
local font={getWidth=function(_,s) return #tostring(s)*6 end,getHeight=function()return 13 end}
function font:getWrap(s,width)
  local lines={} local line=''
  for word in tostring(s):gmatch('%S+') do
    local nextLine=(line=='' and word or line..' '..word)
    if self:getWidth(nextLine)>width and line~='' then lines[#lines+1]=line;line=word
    else line=nextLine end
  end
  if line~='' then lines[#lines+1]=line end
  return width,lines
end
local g={}
for _,k in ipairs({'setDefaultFilter','setColor','line','polygon','setLineWidth','setFont','setScissor','draw'}) do g[k]=function()end end
function g.newFont()return font end
function g.newImage()return {getDimensions=function() return 128,128 end} end
function g.getScissor()return nil end
function g.rectangle(mode,x,y,w,h)
  rects[#rects+1]={mode=mode,x=x,y=y,w=w,h=h}
end
function g.circle(mode,x,y,r)
  circles[#circles+1]={mode=mode,x=x,y=y,r=r}
end
function g.print(t,x,y)texts[#texts+1]={text=tostring(t),x=x,y=y}end
function g.printf(t,x,y,w,align)
  texts[#texts+1]={text=tostring(t),x=x,y=y,w=w,align=align}
end
love={graphics=g,filesystem={newFileData=function(v)return v end},event={quit=function()end}}
require('main');love.load()
local ui=require('ui')
local oldButton=ui.buttonHint
ui.buttonHint=function(x,y,key,label,maxwidth)
  buttons[#buttons+1]={x=x,y=y,key=key,label=label,maxwidth=maxwidth}
  return oldButton(x,y,key,label,maxwidth)
end
local oldPoster=ui.poster
ui.poster=function(x,y,w,h,name,index,...)
  posters[#posters+1]={x=x,y=y,w=w,h=h,name=name}
  return oldPoster(x,y,w,h,name,index,...)
end
local function upvalue(name)
  local pending={love.draw,love.gamepadpressed,love.update}
  local seen={}
  for attempt=1,800 do
    local fn=table.remove(pending,1)
    if not fn then break end
    if not seen[fn] then
      seen[fn]=true
      for i=1,200 do
        local n,v=debug.getupvalue(fn,i)
        if not n then break end
        if n==name then return fn,i,v end
        if type(v)=='function' then pending[#pending+1]=v end
      end
    end
  end
  error('upvalue ausente: '..name)
end
local function route(v)local f,i=upvalue('screen');debug.setupvalue(f,i,v)end
local function focus(v)local f,i=upvalue('focus');debug.setupvalue(f,i,v)end
local function reset()texts={};buttons={};rects={};circles={};posters={} end
local function contains(needle)
  local count=0
  for _,v in ipairs(texts) do if v.text:find(needle,1,true) then count=count+1 end end
  return count
end
local ext=require('external')
ext.categories={{category='ALL',count=7},{category='snes',count=7}}
ext.games={
 {name='ROM Um',game_path='https://example.org/1.zip',category='snes',cover_id=''},
 {name='ROM Dois',game_path='https://example.org/2.zip',category='snes',cover_id=''},
 {name='ROM Tres',game_path='https://example.org/3.zip',category='snes',cover_id=''},
 {name='ROM Quatro',game_path='https://example.org/4.zip',category='snes',cover_id=''},
 {name='ROM Cinco',game_path='https://example.org/5.zip',category='snes',cover_id=''}
}
ext.total=#ext.games
route('home');reset();love.draw()
assert(contains('640×480')==0 and contains('640 × 480')==0,'Resolucao apareceu na interface')
local dots={}
for _,c in ipairs(circles) do if c.mode=='fill' and math.abs(c.y-414)<.001 then dots[#dots+1]=c.x end end
assert(#dots==5,'Carrossel deve desenhar 5 pontos; retornou '..#dots)
local sum=0;for _,x in ipairs(dots) do sum=sum+x end
assert(math.abs(sum/#dots-511)<.01,'Bolinhas fora do centro do slide')
assert(contains('DESTAQUE')>0,'Titulo EM DESTAQUE nao esta visivel')
local slideFound=false
for _,r in ipairs(rects) do if r.mode=='fill' and r.x==428 and r.y==237 and r.w==166 and r.h==187 then slideFound=true end end
assert(slideFound,'Slide nao foi reduzido/relocalizado')
route('about');reset();love.draw()
local header,community
for _,r in ipairs(rects) do
 if r.mode=='fill' and r.y==103 and r.h==86 and r.w==438 then header=r end
 if r.mode=='fill' and r.y==107 and r.h==76 and r.w==232 then community=r end
end
assert(header and community,'Cabecalho ou comunidade ausentes')
assert(math.abs((header.x+header.w/2)-(community.x+community.w/2))<.01,'Retangulo da comunidade nao esta centrado')
local start
for _,b in ipairs(buttons) do
 if b.key=='START' and b.y==157 then start=b end
 if b.maxwidth then assert(b.maxwidth>0,'Botoes nao podem usar largura de texto zero')end
end
assert(start and start.x+56<=community.x+community.w,'Botao START cortado no quadro')
route('catalog');focus('grid');reset();love.draw()
assert(contains('ROM Dois')==1,'Nome do jogo duplicado na capa selecionada')
local preview=false
for _,p in ipairs(posters) do
 if p.x==434 and p.y==134 and p.w==179 and p.h==277 then preview=true end
end
assert(preview,'Preview nao ocupa area inteira da capa')
for _,b in ipairs(buttons) do assert(b.key~='START','Rodape do catalogo ainda usa START') end
love.gamepadpressed(nil,'start')
assert(select(3,upvalue('screen'))=='catalog','START abriu pesquisar no catalogo')
love.gamepadpressed(nil,'x')
assert(select(3,upvalue('screen'))=='search','X nao abriu a busca')
route('startup');reset();love.draw()
assert(contains('640 × 480')==0,'Resolucao permanece no carregamento')
print('v0.2.11: alinhamento de QR e comunidade, slideshow, capa, rodapes e busca X OK')
