-- Regressao: glifos premium da Central (sem imagens antigas), todos os temas,
-- e Force Nexus Sith imediatamente apos Jedi sem reinstalar arquivos.
package.path="src/?.lua;src/?/init.lua;"..package.path

local calls,pushes={},0
local mock={}
for _,method in ipairs({"setColor","setLineWidth","rectangle","circle","arc","polygon",
  "line","translate","scale"}) do
  mock[method]=function(...) calls[#calls+1]={op=method,args={...}} end
end
mock.push=function(mode) assert(mode=="all"); pushes=pushes+1 end
mock.pop=function() pushes=pushes-1;assert(pushes>=0) end
love={graphics=mock,filesystem={}}
local I=require("ui.central_icons")
local ids={"games","bios","tools","search","favs","news","downloads","ranking"}
for _,size in ipairs({28,56}) do
  for _,id in ipairs(ids) do
    calls={}
    assert(I.has(id),id.." sem arte")
    assert(I.draw(id,14,16,size,{0.3,0.65,1}),id.." nao desenhou")
    assert(pushes==0,"pilha graphics desequilibrada: "..id)
    assert(#calls>=10,"icone vazio ou inacabado: "..id)
    assert(not I.has("missing-id"))
  end
end

-- Stub minimo do registro de temas. A logica real de M.scan e executada.
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={APP_DIR="/app"}
package.loaded["lib.util"]={
  clamp=function(n,a,b)return math.min(b,math.max(a,n))end,
  trim=function(s)return s end,
  log=function()end,
}
local colors={bg0="#1",bg1="#1",bg2="#1",bg3="#1",line="#1",text="#1",
  dim="#1",faint="#1",accent="#1",accent2="#1",yellow="#1",green="#1",
  red="#1",orange="#1",black="#1",shadow="#1"}
package.loaded["lib.json"]={decode=function(s)
  local id=s:match("ID=([^;]+)")
  return {id=id,name=id,version="1.0.0",colors=colors}
end}
package.loaded["ui.theme"]={parse_hex=function(v)return v and {1,1,1} or nil end}
local installed=true
function love.filesystem.getInfo(path,mode)
  if mode=="directory" then
    if path=="themes/forcejedi" or path=="themes/default" or
      path=="themes/pastel" or path=="user_themes" then return {type="directory"} end
    if path=="user_themes/forcesith" and installed then return {type="directory"} end
  end
end
function love.filesystem.getDirectoryItems(path)
  if path=="themes" then return {"default","pastel","forcejedi"} end
  if path=="user_themes" then
    if installed then return {"other","forcesith"} end
    return {"other"}
  end
  return {}
end
function love.filesystem.read(path)
  local id=path:match("/([^/]+)/theme%.json$")
  if id then return "ID="..id..";" end
end
local Th=require("core.themes")
Th.scan()
local names={}
for _,th in ipairs(Th.list) do names[#names+1]=th.id end
assert(names[1]=="forcejedi",table.concat(names,","))
assert(names[2]=="forcesith",table.concat(names,","))
assert(Th.by_id["forcejedi"] and Th.by_id["forcesith"], "ids nao preservados")
installed=false
Th.scan()
assert(Th.list[1].id=="forcejedi" and Th.list[2].id=="default",
  "sem Sith opcional, o primeiro tema carregado vem depois do Jedi")
print("Icones Central 28/56 e ordem Jedi > Sith (opcional) em todos os temas: OK")
