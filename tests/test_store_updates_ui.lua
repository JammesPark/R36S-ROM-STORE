-- Atualizações: menu, alerta automático e confirmação para instalar.
package.path='src/?.lua;'..package.path
local lines={}
local f={getWidth=function(_,s)return #tostring(s)*6 end,getHeight=function()return 13 end,
 getWrap=function(_,s,w)return w,{tostring(s)}end}
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
 gfx[k]=function(...)end
end
gfx.getScissor=function()return nil end
gfx.newFont=function()return f end
gfx.newImage=function()return {getDimensions=function()return 120,160 end} end
gfx.print=function(s)lines[#lines+1]=tostring(s) end
gfx.printf=function(s)lines[#lines+1]=tostring(s) end
local quit=false
love={graphics=gfx,filesystem={newFileData=function(s)return s end,read=function()return "0.3.0-beta\n" end},
 event={quit=function()quit=true end}}
require('main')
love.load()
local up=require('store_update')
local function locate(name)
 local q={love.draw,love.update,love.gamepadpressed}
 local seen={}
 for n=1,750 do
  local fn=table.remove(q,1)
  if not fn then break end
  if not seen[fn] then
   seen[fn]=true
   for i=1,150 do
    local k,v=debug.getupvalue(fn,i)
    if not k then break end
    if k==name then return fn,i,v end
    if type(v)=='function' then q[#q+1]=v end
   end
  end
 end
 error('Estado inacessível: '..name)
end
local function set(name,value)
 local fn,i=locate(name)
 debug.setupvalue(fn,i,value)
end
local function get(name)
 local _,_,v=locate(name)
 return v
end
local function drawn(t)
 for _,v in ipairs(lines) do if v:find(t,1,true) then return true end end
 return false
end
lines={}
set('screen','settings')
love.draw()
assert(drawn('Atualizações da loja'),'Menu Configurações não mostra Atualizações')
up.status={phase='available',version='0.3.1-beta',notes='Novidades'}
up.offered=false
set('screen','home')
love.update(0.1)
assert(get('storeUpdateModal')==true,'Novo update não gerou alerta na home')
lines={}
love.draw()
assert(drawn('Atualização disponível'),'Modal de update não apareceu')
love.gamepadpressed(nil,'b')
assert(get('storeUpdateModal')==false,'B não dispensou update')
up.offered=false
love.update(0.1)
love.gamepadpressed(nil,'a')
assert(get('screen')=='updates','A no modal não abriu Atualizações')
local action=nil
local original=up.run
up.run=function(k)action=k;return true end
love.gamepadpressed(nil,'a')
assert(action=='download','A no update disponível não iniciou download')
up.status={phase='ready',version='0.3.1-beta',sha256=string.rep('a',64)}
local install=up.install
up.install=function()return true end
love.gamepadpressed(nil,'a')
assert(quit,'Instalar update não solicitou fechamento do LÖVE')
up.install=install
up.run=original
print('ATUALIZAÇÕES UI: tela, alerta, download confirmado e saída segura: OK')
