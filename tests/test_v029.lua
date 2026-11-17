package.path='src/?.lua;'..package.path
local font={getWidth=function(_,s) return #tostring(s)*6 end,getHeight=function() return 14 end,
getWrap=function(_,s,w) return w,{'ok'} end}
local gfx={}
for _,name in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw','print','printf'}) do gfx[name]=function() end end
function gfx.getScissor() return nil end
function gfx.newFont() return font end
function gfx.newImage() return {getDimensions=function()return 120,100 end} end
local audio={}
function audio.newSource(path,kind)
  return {setLooping=function()end,setVolume=function()end,play=function()end,stop=function()end}
end
love={graphics=gfx,audio=audio,filesystem={newFileData=function(data)return data end},event={quit=function()end}}
require('main')
love.load()
local function locate(target)
  local pending={love.draw,love.gamepadpressed,love.update}
  local seen={}
  for j=1,300 do
    local fn=table.remove(pending,1)
    if not fn then break end
    if not seen[fn] then
      seen[fn]=true
      for i=1,180 do
        local n,v=debug.getupvalue(fn,i)
        if not n then break end
        if n==target then return fn,i end
        if type(v)=='function' then pending[#pending+1]=v end
      end
    end
  end
  error('upvalue ausente: '..target)
end
local function value(n) local fn,i=locate(n);local _,v=debug.getupvalue(fn,i);return v end
local function set(n,v) local fn,i=locate(n);debug.setupvalue(fn,i,v) end
local ext=require('external')
local one={name='Jogo Um',category='snes',game_path='https://example.com/one.zip'}
local two={name='Jogo Dois',category='snes',game_path='https://example.com/two.zip'}
ext.games={one};ext.page=1;ext.totalPages=2;ext.total=2;ext.pending=nil
set('screen','catalog');set('focus','grid');set('gameIndex',1)
local requested=0
ext.loadNext=function()
  requested=requested+1
  ext.games[#ext.games+1]=two
  ext.page=2
  return true
end
ext.update=function()end
love.gamepadpressed(nil,'dpdown')
assert(requested==1,'Rolagem no fim deve solicitar proximo lote')
love.update(.2)
assert(value('gameIndex')==2,'Jogo seguinte nao ficou selecionado apos carregar')
assert(value('screen')=='catalog','Rolagem nao deve mudar tela')
set('screen','about')
love.gamepadpressed(nil,'a')
assert(value('qrModal')=='telegram','A precisa abrir QR do Telegram')
love.gamepadpressed(nil,'a')
assert(value('qrExpanded')==true,'A precisa ampliar QR')
love.gamepadpressed(nil,'b')
assert(value('qrExpanded')==false and value('qrModal')=='telegram','B deve voltar ao modal')
love.gamepadpressed(nil,'b')
assert(value('qrModal')==nil,'B deve fechar o modal')
set('screen','installed')
local record={name='Minha ROM',category='snes',card='sd1',game_path=one.game_path,filename='one.zip'}
set('downloads',{record})
set('installIndex',1)
love.gamepadpressed(nil,'x')
assert(value('pendingDelete')==record,'X deve abrir confirmacao antes de apagar')
love.gamepadpressed(nil,'b')
assert(value('pendingDelete')==nil,'B deve cancelar exclusao')
local removed=false
ext.remove=function(d) removed=(d==record);return true end
love.gamepadpressed(nil,'x')
love.gamepadpressed(nil,'a')
assert(removed,'A deve pedir remocao do registro selecionado')
local i18n=require('i18n')
for _,lang in ipairs({'pt','en','es','ru'}) do
  assert(i18n.get(lang,'delete_rom_question')~='delete_rom_question','Falta traducao para '..lang)
  assert(i18n.get(lang,'overwrite')~='overwrite','Falta traducao de sobrescrita: '..lang)
end
print('v0.2.9: lista continua, QR ampliado, exclusao confirmada e idiomas OK')
