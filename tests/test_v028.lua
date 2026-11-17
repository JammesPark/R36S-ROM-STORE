package.path='src/?.lua;'..package.path
local drawn={}
local f={getWidth=function(_,s) return #tostring(s)*6 end,getHeight=function() return 14 end,
  getWrap=function(_,s,w) local n=math.max(1,math.ceil(#tostring(s)*6/w));local t={};for i=1,n do t[i]='line' end;return w,t end}
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[k]=function() end
end
function gfx.getScissor() return nil end
function gfx.newFont() return f end
function gfx.newImage() return {getDimensions=function() return 100,100 end} end
function gfx.print(x) drawn[#drawn+1]=tostring(x) end
function gfx.printf(x) drawn[#drawn+1]=tostring(x) end
local loaded={}
local audio={}
function audio.newSource(path,kind)
  assert(kind=='stream','OGG deve usar stream')
  local v={path=path,playing=false}
  function v:setLooping(b)self.looping=b end
  function v:setVolume(n)self.volume=n end
  function v:play() self.playing=true end
  function v:stop() self.playing=false end
  loaded[#loaded+1]=v
  return v
end
love={graphics=gfx,audio=audio,filesystem={newFileData=function(v,n)return v end},event={quit=function()end}}
require('main')
love.load()
local function getup(name)
 for i=1,180 do local n,v=debug.getupvalue(love.draw,i);if n==name then return v end end
 error('upvalue ausente: '..name)
end
local function setup(name,value)
 for i=1,180 do local n=debug.getupvalue(love.draw,i);if n==name then debug.setupvalue(love.draw,i,value);return end end
 error('upvalue ausente: '..name)
end
assert(#loaded==3,'Três temas OGG devem ser carregados')
local legal=require('legal_text')
assert(not table.concat(legal.get('pt').notice,' '):find('ports de terceiros',1,true),'Remover ports do aviso')
setup('screen','about')
drawn={};love.draw()
assert(table.concat(drawn,' '):find('@r36sportsbr',1,true),'Cabeçalho sem Telegram')
assert(table.concat(drawn,' '):find('CANAL',1,true),'Cabeçalho sem canal')
love.gamepadpressed(nil,'a')
assert(getup('qrModal')=='telegram','Botão A do Sobre deve abrir Telegram')
love.draw()
love.gamepadpressed(nil,'b')
assert(getup('qrModal')==nil,'Botão B deve fechar QR')
love.gamepadpressed(nil,'start')
assert(getup('qrModal')=='livepix','START do Sobre deve abrir LivePix')
love.draw()
love.gamepadpressed(nil,'b')
assert(getup('qrModal')==nil,'Botão B deve fechar LivePix')
setup('screen','catalog')
setup('focus','grid')
love.gamepadpressed(nil,'b')
assert(getup('screen')=='catalog' and getup('focus')=='sidebar','B da lista deve focar categorias')
love.gamepadpressed(nil,'b')
assert(getup('screen')=='home','B do menu de categorias deve retornar ao Início')
-- Fontes locais: todos os principais recursos gráficos devem estar empacotados.
local paths={'src/assets/logo_dev.png','src/assets/qr_telegram.png','src/assets/qr_livepix.png',
  'src/assets/telegram_icon.png','src/assets/flag_pt.png','src/assets/flag_es.png',
  'src/assets/flag_en.png','src/assets/flag_ru.png','src/assets/icons/house.png',
  'src/assets/icons/joystick.png','src/assets/music/tema_principal.ogg',
  'src/assets/music/tema_navegacao.ogg','src/assets/music/tema_download.ogg'}
for _,path in ipairs(paths) do local p=io.open(path,'rb');assert(p,'Não empacotado: '..path);p:close() end
print('v0.2.8: músicas, ícones, bandeiras, Telegram, LivePix, B categoria e Sobre: OK')
