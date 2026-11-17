package.path='src/?.lua;'..package.path
local font={}
local gfx={}
for _,key in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[key]=function(...) end
end
function gfx.getScissor() return nil end
function gfx.newFont(...) return font end
function gfx.newImage() return {getDimensions=function() return 100,180 end} end
function gfx.printf(...) end
function gfx.print(...) end
love={graphics=gfx,filesystem={newFileData=function(v) return v end},event={quit=function() end}}
require('main')
love.load();love.update(2)
local external=require('external')
local ui=require('ui')
local function var(name)
  for i=1,90 do
    local key,val=debug.getupvalue(love.draw,i)
    if not key then break end
    if key==name then return val end
  end
end
local function route(name)
  for i=1,90 do
    local key=debug.getupvalue(love.draw,i)
    if key=='screen' then debug.setupvalue(love.draw,i,name);return end
  end
  error('screen unavailable')
end
route('home')
-- Page shoulders may not leave home nor change selected route.
love.gamepadpressed(nil,'leftshoulder')
assert(var('screen')=='home','L1 changed home')
love.gamepadpressed(nil,'rightshoulder')
assert(var('screen')=='home','R1 changed home')
-- Old aliases must not be active on the keyboard.
love.keypressed('q');love.keypressed('e');love.keypressed('z');love.keypressed('space')
assert(var('screen')=='home','Legacy keyboard aliases are still active')
-- New font sizes and translations.
local tr=require('i18n')
for _,language in ipairs({'pt','en','es','ru'}) do
  assert(tr.get(language,'font_small')~='font_small')
  assert(tr.get(language,'current_download')~='current_download')
end
ui.setFontSize('large');ui.setFontSize('small');ui.setFontSize('medium')
route('font_size');love.draw();love.keypressed('down');love.keypressed('return')
route('downloads');love.draw()
route('home');love.draw()
local device=require('device_status')
device.update(0,true)
assert(type(device.get().time)=='string')
print('v0.2.4: layout, download, fonte, status e controles OK')
