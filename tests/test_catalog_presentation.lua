package.path="./game/?.lua;"..package.path
local P=require("core.catalog_presentation")
for _,ext in ipairs({"mgw","rom","mx2","unf","pak","sc","sap"}) do
  assert(P.title("Jogo."..ext,"https://example.org/Jogo."..ext)=="Jogo",ext)
end
assert(P.title("Abadia.ROM","https://example.org/Abadia.rom")=="Abadia")
assert(P.title("Gun.Smoke","https://example.org/game.zip")=="Gun.Smoke")
assert(P.title("Game 2.0","https://example.org/game.zip")=="Game 2.0")
assert(P.title("Game.rom","https://example.org/game.zip")=="Game.rom")
local c={{id="coleco",name="COLECO",section="games"},{id="cps2",name="CPS2",section="games"},{id="dreamcast",name="DREAMCAST",section="games"},{id="cps1",name="CPS1",section="games",count=0},{id="cps3",name="CPS3",section="games",count=0},{id="tool",name="A",section="tools"}}
local s=P.systems(c)
assert(#s==5 and s[1].id=="coleco" and s[2].id=="cps1" and s[3].id=="cps2" and s[4].id=="cps3" and s[5].id=="dreamcast")
assert(c[4].id=="cps1","original nao alterado")
print("CATALOG PRESENTATION: OK - extensoes reais e CPS1/2/3 inclusive vazios")
