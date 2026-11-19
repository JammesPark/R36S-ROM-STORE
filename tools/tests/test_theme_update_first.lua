-- Confirma que "BAIXAR NOVOS TEMAS" fica sempre no topo da tela Temas.
-- Teste de logica sem janela LÖVE nem hardware do console.
package.path = "game/?.lua;game/?/init.lua;" .. package.path
love = {graphics = {}}
package.loaded["lib.i18n"] = {L = function(s) return s end}
package.loaded["ui.theme"] = {}
package.loaded["ui.gfx"] = {}
package.loaded["lib.util"] = {clamp=function(n,a,b)return math.min(b,math.max(a,n))end}
local th = {current="forcesith",list={},by_id={},calls=0}
function th.scan() th.calls=th.calls+1 end
function th.apply() return true end
package.loaded["core.themes"] = th
local S = require("ui.screens.themes")
local opened = {}
App = {push=function(v) opened[#opened+1]=v end, pop=function() end, toast=function() end}
for _, n in ipairs({0,1,5,9}) do
  th.list={}
  for i=1,n do th.list[i]={id=i==n and "forcesith" or ("theme"..i),name="Tema"..i,colors={}} end
  S:enter()
  assert(#S.items==n+1, "quantidade incorreta")
  assert(S.items[1].download == true, "atualizador de temas nao esta em primeiro")
  assert(S.sel==1 and S.scroll==0, "tela deve abrir na primeira posicao")
  for i=1,n do assert(S.items[i+1].theme==th.list[i], "ordem dos temas alterada") end
  S:action("a")
  assert(opened[#opened]=="theme_store", "botao A deve abrir o atualizador de temas")
  S:action("down")
  if n>0 then assert(S.sel==2, "segundo item deve ser primeiro tema") end
  S:resume()
  assert(S.items[1].download and S.sel==1 and S.scroll==0, "atalho deve voltar para o topo apos retornar")
end
print("Atualizador de temas fixo na primeira posicao: OK")
