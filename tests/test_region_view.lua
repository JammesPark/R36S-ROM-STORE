-- Teste de selos, nomes de exibicao e botoes L2/R2 (sem janela LÖVE).
package.path = "./game/?.lua;./game/?/init.lua;" .. package.path
local now = 1
love = { timer = { getTime = function() return now end } }
local f = { getWidth = function(_, s) return #s * 6 end }
package.loaded["ui.theme"] = {
  hex = function(s) return s end,
  c = { bg1 = "#11142a", accent2 = "#38d6ff" },
  f = { small = f },
}
package.loaded["ui.gfx"] = {
  rect = function() end, frame = function() end, text_fit = function() end
}
local Region = require("ui.region")
local labels = { JP = "#FF738A", CN = "#FFC065", TW = "#58E0A6", HK = "#B9A1FF" }
for code, color in pairs(labels) do
  local p = {section="games", name="Puzzle Bobble (Japan) ["..code.."]", region_tag=code}
  local orig=p.name
  assert(Region.code(p)==code and Region.color(code)==color)
  assert(Region.display_name(p)=="Puzzle Bobble (Japan)" or code=="JP")
  if code=="JP" then assert(Region.display_name(p)=="Puzzle Bobble") end
  assert(p.name==orig, "Nome original deve permanecer intacto")
  assert(Region.draw_region(p, 0, 0)>0)
end
assert(Region.code({section="games",name="Sem regiao"})==nil)
assert(Region.code({section="tools",name="Ferramenta [JP]"})==nil)
assert(Region.display_name({section="games",name="Jogo (China) [CN]"})=="Jogo")
assert(Region.display_name({section="games",name="Jogo (Taiwan) [TW]"})=="Jogo")
assert(Region.display_name({section="games",name="Jogo (Hong Kong) [HK]"})=="Jogo")
local Input = require("core.input")
local acts={}
Input.handler=function(a) acts[#acts+1]=a end
Input.gamepadpressed(nil,"lefttrigger")
assert(acts[#acts]=="l2")
Input.gamepadreleased(nil,"lefttrigger")
now=now+0.2
Input.gamepadpressed(nil,"righttrigger")
assert(acts[#acts]=="r2")
Input.gamepadreleased(nil,"righttrigger")
now=now+0.2
Input.gamepadaxis(nil,"triggerleft",0.8)
assert(acts[#acts]=="l2")
Input.gamepadaxis(nil,"triggerleft",0)
now=now+0.2
Input.gamepadaxis(nil,"triggerright",0.8)
assert(acts[#acts]=="r2")
print("REGION AND TRIGGERS: OK (4 cores, nomes intactos, L2/R2 botao/eixo)")
