package.path='src/?.lua;'..package.path
local texts={}
local painted={}
local font={getWidth=function(_,s) return #tostring(s)*6 end, getHeight=function() return 13 end}
function font:getWrap(s,width)
  local lines={}
  local line=''
  for word in tostring(s):gmatch('%S+') do
    local candidate=(line=='' and word or line..' '..word)
    if self:getWidth(candidate)>width and line~='' then
      lines[#lines+1]=line;line=word
    else line=candidate end
  end
  if line~='' then lines[#lines+1]=line end
  return width,lines
end
local gfx={}
for _,name in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[name]=function()end
end
function gfx.getScissor()return nil end
function gfx.newFont()return font end
function gfx.newImage()return {getDimensions=function()return 127,74 end} end
function gfx.print(s,x,y)
  texts[#texts+1]={text=tostring(s),x=x,y=y,kind='print'}
end
function gfx.printf(s,x,y,width,align)
  texts[#texts+1]={text=tostring(s),x=x,y=y,width=width,align=align,kind='printf'}
end
local audio={newSource=function()return {setLooping=function()end,setVolume=function()end,play=function()end,stop=function()end}end}
love={graphics=gfx,audio=audio,filesystem={newFileData=function(data)return data end},event={quit=function()end}}
require('main')
love.load()
local function locate(target)
  local pending={love.draw,love.gamepadpressed,love.update}
  local seen={}
  for tries=1,500 do
    local fn=table.remove(pending,1)
    if not fn then break end
    if not seen[fn] then
      seen[fn]=true
      for i=1,200 do
        local n,v=debug.getupvalue(fn,i)
        if not n then break end
        if n==target then return fn,i end
        if type(v)=='function' then pending[#pending+1]=v end
      end
    end
  end
  error('variavel ausente '..target)
end
local function set(name,val)local f,i=locate(name);debug.setupvalue(f,i,val)end
local function reset() texts={}end
local ui=require('ui')
local keys,drawnAssets,icons={},{},{}
local oldHint=ui.buttonHint
ui.buttonHint=function(x,y,key,label,maxwidth) keys[#keys+1]={key=key,x=x,y=y};return oldHint(x,y,key,label,maxwidth)end
local oldDrawAsset=ui.drawAsset
ui.drawAsset=function(name,x,y,w,h,stretch)
  drawnAssets[#drawnAssets+1]={name=name,x=x,y=y,w=w,h=h}
  return oldDrawAsset(name,x,y,w,h,stretch)
end
local oldIcon=ui.icon
ui.icon=function(name,...) icons[#icons+1]=name;return oldIcon(name,...)end
local function anyKey(k)
  for _,key in ipairs(keys) do if key.key==k then return true end end
end
local function anyText(s)
  for _,t in ipairs(texts) do if t.text:find(s,1,true) then return true end end
end
set('screen','about');reset();keys={};drawnAssets={}
love.draw()
assert(anyKey('A') and anyKey('START'),'No cabecalho Sobre faltam icones A/START')
local foundDev=false
for _,a in ipairs(drawnAssets) do
  if a.name=='logo_dev' and a.w>=100 and a.h>=80 then foundDev=true end
end
assert(foundDev,'Logo do desenvolvedor nao aumentou')
assert(anyText('CANAL DA COMUNIDADE'),'Cabecalho da comunidade nao renderizou')
assert(anyText('R36S ROMS STORE'),'Texto Sobre nao renderizado')
-- Os paragrafos do Sobre sempre utilizam alinhamento a esquerda;
-- o aviso inicial continua justificado.
local paragraphCount=0
for _,t in ipairs(texts) do
  if t.kind=='printf' and t.x==198 then
    assert(t.align=='left','Sobre continua justificado em vez de a esquerda')
    paragraphCount=paragraphCount+1
  end
end
assert(paragraphCount>=3,'Paragrafos da tela Sobre nao encontrados')

set('qrModal','livepix');set('qrExpanded',false);reset();keys={}
love.draw()
assert(anyText('APOIE O PROJETO'),'Cabecalho do LivePix nao desenhado')
assert(anyText('Esta loja é gratuita.'),'Texto completo do LivePix nao apareceu')
assert(anyText('Obrigado pelo apoio!'),'Mensagem de agradecimento nao apareceu')
assert(anyKey('A') and anyKey('B'),'Modal QR deve mostrar A/B no formato de botoes')
for _,t in ipairs(texts) do
  if t.kind=='printf' and t.x==307 and t.y>=190 then
    assert(t.y<366,'Texto do LivePix fora da area visivel: '..t.y)
    assert(t.align=='left','Texto do QR nao alinhado a esquerda')
  end
end
set('qrModal','telegram');reset()
love.draw()
assert(anyText('Escaneie para seguir nosso canal'),'Texto da janela Telegram nao desenhado')

set('qrModal',nil);set('screen','settings');icons={};reset()
love.draw()
local expected={'languages','palette','type','hard-drive','wifi','circle-help'}
local found={}
for _,name in ipairs(icons) do found[name]=true end
for _,name in ipairs(expected) do assert(found[name],'Categoria sem icone: '..name)end

set('screen','home');set('focus','content');set('homeFocus','featured')
local ext=require('external')
ext.games={{name='Jogo Em Destaque Para Teste',category='snes',cover_id='',game_path='https://example.com/jogo.zip'}}
set('homeSlideIndex',1)
reset()
love.draw()
local nameVisible=false
for _,t in ipairs(texts) do
  if t.text:find('Jogo Em Destaque',1,true) then nameVisible=true end
end
assert(not nameVisible,'Slide nao pode exibir nomes dos jogos')
print('v0.2.10: Sobre alinhado, A/START, logo DEV, QR sem corte, 6 icones e Destaque OK')
