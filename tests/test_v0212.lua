-- v0.2.12: START amarelo solido sem corte e titulo Em destaque alinhado.
package.path='src/?.lua;'..package.path
local rects, texts, circles={},{},{}
local currentColor={1,1,1,1}
local font={}
function font:getWidth(s) return #tostring(s)*7 end
function font:getHeight() return 13 end
function font:getWrap(s,width)
  local lines,chunk={},''
  for word in tostring(s):gmatch('%S+') do
    local candidate=chunk=='' and word or chunk..' '..word
    if self:getWidth(candidate)>width and chunk~='' then
      lines[#lines+1]=chunk;chunk=word
    else chunk=candidate end
  end
  if chunk~='' then lines[#lines+1]=chunk end
  return width,lines
end
local gfx={}
for _,k in ipairs({'setDefaultFilter','line','polygon','setLineWidth','setFont','setScissor','draw'}) do
  gfx[k]=function()end
end
function gfx.setColor(r,g,b,a) currentColor={r,g,b,a or 1} end
function gfx.getScissor() return nil end
function gfx.newFont() return font end
function gfx.newImage() return {getDimensions=function()return 120,90 end}end
function gfx.rectangle(mode,x,y,w,h)
  rects[#rects+1]={mode=mode,x=x,y=y,w=w,h=h,color={table.unpack(currentColor)}}
end
function gfx.circle(mode,x,y,r)
  circles[#circles+1]={mode=mode,x=x,y=y,r=r}
end
function gfx.print(s,x,y) texts[#texts+1]={s=tostring(s),x=x,y=y} end
function gfx.printf(s,x,y,w,align)
  texts[#texts+1]={s=tostring(s),x=x,y=y,w=w,align=align}
end
love={graphics=gfx,filesystem={newFileData=function(v)return v end},event={quit=function()end}}
require('main')
love.load()
local ui=require('ui')
ui.setFontSize('large')
local ext=require('external')
ext.games={
  {name='ROM Exemplo',category='snes',game_path='https://example.org/1.zip',cover_id=''},
  {name='ROM Dois',category='snes',game_path='https://example.org/2.zip',cover_id=''},
  {name='ROM Tres',category='snes',game_path='https://example.org/3.zip',cover_id=''}
}
ext.total=#ext.games
local function upvalue(name)
  local work={love.draw,love.gamepadpressed,love.update}
  local seen={}
  for _=1,600 do
    local f=table.remove(work,1)
    if not f then break end
    if not seen[f] then
      seen[f]=true
      for i=1,150 do
        local n,v=debug.getupvalue(f,i)
        if not n then break end
        if n==name then return f,i,v end
        if type(v)=='function' then work[#work+1]=v end
      end
    end
  end
  error('Upvalue ausente: '..name)
end
local function route(screen)
  local f,i=upvalue('screen');debug.setupvalue(f,i,screen)
end
local function reset() rects={};texts={};circles={} end
local function elementAt(v,x,y)
  for _,obj in ipairs(v) do if obj.x==x and obj.y==y then return obj end end
end
route('home');reset();love.draw()
local overviewTitle,featuredTitle
local translations=require('i18n')
local featuredKey=translations.get('pt','featured')
local overviewKey=translations.get('pt','overview')
for _,t in ipairs(texts) do
  if t.s==overviewKey then overviewTitle=t end
  if t.s==featuredKey then featuredTitle=t end
end
assert(overviewTitle and featuredTitle,'Titulos Visao geral ou Em destaque ausentes')
assert(overviewTitle.y==featuredTitle.y and overviewTitle.y==209,
  'Titulos devem estar na mesma linha horizontal')
assert(overviewTitle.x==180 and featuredTitle.x==428,
  'Titulos devem comecar na mesma coordenada X de seus paineis')
local slide=elementAt(rects,428,237)
assert(slide and slide.w==166 and slide.h==187,'Slide fora do alinhamento da Visao geral')
local dots={}
for _,c in ipairs(circles) do
  if c.mode=='fill' and c.y==414 then dots[#dots+1]=c.x end
end
assert(#dots==3,'Bolinhas nao desenhadas no slide')
local sum=0
for _,x in ipairs(dots) do sum=sum+x end
assert(math.abs(sum/#dots-511)<0.01,'Bolinhas fora do centro do slide')
route('about');reset();love.draw()
local starts={}
for _,r in ipairs(rects) do
  if r.mode=='fill' and r.w==56 and r.h==20 and math.abs(r.color[1]-1)<.001 and
     math.abs(r.color[2]-.82)<.001 and math.abs(r.color[3]-.22)<.001 then
    starts[#starts+1]=r
  end
end
assert(#starts==2,'Os START do cartao e da legenda precisam ser amarelos solidos')
local startCard,startFooter
for _,r in ipairs(starts) do
  if r.y==157 then startCard=r end
  if r.y==448 then startFooter=r end
end
assert(startCard and startFooter,'Faltou START no cartao da comunidade ou no rodape')
local community=elementAt(rects,284,107)
assert(community and community.w==232,'Cartao da comunidade mudou de tamanho')
assert(startCard.x>=community.x and startCard.x+startCard.w<=community.x+community.w,
  'START do cartao cortado na borda')
assert(startFooter.x+startFooter.w+61<486,'START do rodape invade botao B')
local buttonWords=0
for _,t in ipairs(texts) do
  if t.s=='START' then
    buttonWords=buttonWords+1
    assert(t.w==48,'Texto START deve ter area util de 48 px')
    assert(font:getWidth(t.s)<t.w,'Texto START cortado pela largura disponivel')
  end
end
assert(buttonWords>=2,'START da legenda foi truncado')
print('v0.2.12: destaque alinhado; 2 botoes START amarelos solidos, inteiros, legiveis: OK')
