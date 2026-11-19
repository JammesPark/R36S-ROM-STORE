-- Teste offline das dimensoes SDL versus painel fisico KMSDRM/fbdev.
package.path = "game/?.lua;game/?/init.lua;" .. package.path
local D = require("core.display")
local function near(a,b)
  assert(math.abs(a-b)<0.000001, tostring(a).." != "..tostring(b))
end
local empty=function()return nil end
local none=function()return {} end
local function files(tbl) return function(path)return tbl[path] end end
local function modes(tbl) return function()return tbl end end
local w,h=640,480
local graphics={getDimensions=function()return w,h end}
local window={getMode=function()return 800,480 end,
 getDesktopDimensions=function()return 1024,600 end}
local function sample(pw,ph,scale,ox,oy,canvas)
  w,h=pw,ph
  D.detect(graphics,window,nil,nil,empty,none)
  assert(D.width==pw and D.height==ph and D.label()==pw.."x"..ph)
  near(D.scale,scale); near(D.scale_x,scale);near(D.scale_y,scale)
  assert(D.x==ox and D.y==oy)
  assert(D.needs_canvas()==canvas)
  local x,y=D.to_logical(ox+scale*320,oy+scale*240)
  near(x,320);near(y,240)
  assert(D.to_logical(-1,-1)==nil)
end
sample(640,480,1,0,0,false)
sample(720,720,1.125,0,90,true)
sample(1280,720,1.5,160,0,true)
sample(800,480,1,80,0,true)
sample(1024,600,1.25,112,0,true)

-- Cenario que o teste 0.0.32 nao simulava: SDL renderiza 640x480,
-- mas o painel tem 720x720 e o kernel estica a imagem no fullscreen.
w,h=640,480
local dsi="/sys/class/drm/card0-DSI-1"
local physical=files({
  ["/sys/class/graphics/fb0/mode"]="U:640x480p-60",
  [dsi.."/status"]="connected",
  [dsi.."/modes"]="720x720\n",
})
local pw,ph,ps=D.probe_physical(physical,modes({dsi}))
assert(pw==720 and ph==720 and ps==dsi.."/modes")
D.detect(graphics,window,nil,nil,physical,modes({dsi}))
assert(D.width==640 and D.height==480)
assert(D.label()=="720x720" and D.physical_source==dsi.."/modes")
near(D.scale,1.125)
near(D.scale_x,1)
near(D.scale_y,0.75)
near(D.x,0);near(D.y,60)
assert(D.needs_canvas())
local mx,my=D.to_logical(320,240)
near(mx,320);near(my,240)
assert(D.to_logical(320,25)==nil,"margem do painel nao e botao")
-- SDL volta ao framebuffer nativo: escala fisica agora e igual nos eixos.
w,h=720,720
D.detect(graphics,window,nil,nil,physical,modes({dsi}))
near(D.scale_x,1.125);near(D.scale_y,1.125)
near(D.y,90)

-- Apenas fb0/mode, ou fb0/modes e virtual_size quando DRM inexiste.
local fb=files({["/sys/class/graphics/fb0/mode"]="U:720x720p-60"})
pw,ph=D.probe_physical(fb,none)
assert(pw==720 and ph==720)
local backup=files({["/sys/class/graphics/fb0/modes"]="U:720x720p-60"})
pw,ph=D.probe_physical(backup,none)
assert(pw==720 and ph==720)
local virt=files({["/sys/class/graphics/fb0/virtual_size"]="720,720"})
pw,ph=D.probe_physical(virt,none)
assert(pw==720 and ph==720)
-- Nao selecionar conector desconectado.
local hdmi="/sys/class/drm/card0-HDMI-A-1"
pw,ph=D.probe_physical(files({[hdmi.."/status"]="disconnected",
 [hdmi.."/modes"]="1920x1080"}),modes({hdmi}))
assert(not pw and not ph)
-- Redimensionamento e fallback SDL.
D.detect(graphics,window,480,640,empty,none)
near(D.scale,0.75);near(D.scale_x,0.75);near(D.scale_y,0.75)
assert(D.x==0 and D.y==140)
D.detect({getDimensions=function()return 0,0 end},window,nil,nil,empty,none)
assert(D.label()=="800x480" and D.source=="love.window")
D.detect({}, {getDesktopDimensions=function()return 1024,600 end},nil,nil,empty,none)
assert(D.label()=="1024x600" and D.source=="desktop")
D.detect({}, {},nil,nil,empty,none)
assert(D.label()=="640x480" and D.source=="fallback" and not D.detected)
D.detect({getDimensions=function()error("SDL nao iniciou")end}, {},nil,nil,empty,none)
assert(D.label()=="640x480" and D.source=="fallback")
-- Conferir uso REAL do detector, antes e depois de abrir a janela.
local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local main=read("game/main.lua")
local conf=read("game/conf.lua")
local defs=read("game/ui/settings_defs.lua")
for _,word in ipairs({
  'local Display = require("core.display")',
  'function App.configure_display(width, height)',
  'function love.resize(w, h)',
  'lg.draw(cv, ox, oy, 0, sx, sy)',
  'lg.scale(Display.scale_x, Display.scale_y)',
  'Display.physical_source',
}) do
  assert(main:find(word,1,true), "falta integracao: "..word)
end
assert(conf:find('pcall(require, "core.display")',1,true))
assert(conf:find('t.window.width, t.window.height = w, h',1,true))
assert(defs:find('return display.label()',1,true))
print("Tela 720x720 real x SDL 640x480; fisico DRM, fb0, resize e 4 formatos: OK")
