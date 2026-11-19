-- Testa migração offline de tema legado selecionado em uma versão anterior.
-- Em nova instalacao so Jedi/Sith podem aparecer; copiar apenas preferencia
-- ja salva, mantendo os outros 3 temas como opcionais no catalogo.
package.path="game/?.lua;game/?/init.lua;"..package.path
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={APP_DIR="/app"}
package.loaded["lib.util"]={
  clamp=function(v,a,b)return math.max(a,math.min(v,b))end,
  trim=function(s)return tostring(s or ""):match("^%s*(.-)%s*$")end,
  log=function()end,
}
local color={}
for _,k in ipairs({"bg0","bg1","bg2","bg3","line","text","dim","faint",
  "accent","accent2","yellow","green","red","orange","black","shadow"}) do
  color[k]="#123456"
end
package.loaded["ui.theme"]={
  parse_hex=function(s)if s=="#123456" then return {1,1,1} end end,
  apply_palette=function()end,
}
package.loaded["ui.gfx"]={build_background=function()end}
local json=require("lib.json")
local files,dirs={},{}
local function data(id)
  return json.encode({id=id,name=id,version="1.0.1",
    author="Lag do Lira (base visual adaptada)",colors=color,
    style={layout=id=="forcejedi" and "force" or nil}})
end
local function reset(saved)
  files,dirs={},{}
  dirs["themes"]=true
  dirs["themes/forcejedi"]=true
  dirs["themes/forcesith"]=true
  dirs["theme_updates"]=true
  dirs["user_themes"]=true
  files["themes/forcejedi/theme.json"]=data("forcejedi")
  files["themes/forcesith/theme.json"]=data("forcesith")
  for _,id in ipairs({"default","neongrid","wiiblue","pastel"}) do
    dirs["theme_updates/"..id]=true
    files["theme_updates/"..id.."/theme.json"]=data(id)
    files["theme_updates/"..id.."/preview.png"]="PNG_"..id
    files["theme_updates/"..id.."/logo_header.png"]="HEADER_"..id
  end
  if saved then files["theme.txt"]=saved end
end
local function diritems(root)
  local result,seen={},{}
  local prefix=root.."/"
  for _,registry in ipairs({files,dirs}) do
    for p in pairs(registry) do
      if p:sub(1,#prefix)==prefix then
        local n=p:sub(#prefix+1):match("^[^/]+")
        if n and not seen[n] then seen[n]=true;result[#result+1]=n end
      end
    end
  end
  table.sort(result);return result
end
love={filesystem={
  getInfo=function(p,k)
    local t=dirs[p] and "directory" or (files[p] and "file" or nil)
    if t and (not k or t==k) then return {type=t} end
  end,
  getDirectoryItems=diritems,
  read=function(p)return files[p]end,
  write=function(p,value)files[p]=value;return true end,
  createDirectory=function(p)dirs[p]=true;return true end,
}}
local Th=require("core.themes")
reset(nil)
assert(Th.init()==nil)
assert(Th.current=="forcejedi")
assert(#Th.list==2 and Th.list[1].id=="forcejedi" and Th.list[2].id=="forcesith",
  "instalacao nova deve conter apenas dois temas Force")
for _,id in ipairs({"default","neongrid","wiiblue","pastel"}) do
  assert(files["user_themes/"..id.."/theme.json"]==nil,
    "nao instalar tema legado sem escolha previa: "..id)
end

reset("neongrid")
assert(Th.init()==nil)
assert(Th.current=="neongrid","tema antigo ativo deve continuar")
assert(files["user_themes/neongrid/theme.json"]==files["theme_updates/neongrid/theme.json"])
assert(files["user_themes/neongrid/preview.png"]=="PNG_neongrid")
assert(files["user_themes/neongrid/logo_header.png"]=="HEADER_neongrid")
for _,id in ipairs({"default","wiiblue","pastel"}) do
  assert(not files["user_themes/"..id.."/theme.json"],"migracao indevida "..id)
end
local count=#Th.list
Th.scan()
assert(#Th.list==count,"migracao nao idempotente")
assert(Th.list[1].id=="forcejedi" and Th.list[2].id=="forcesith")
assert(Th.by_id.neongrid and Th.by_id.neongrid.builtin==false)

reset("default")
assert(Th.init()==nil and Th.current=="default",
  "tema Padrao do Lira selecionado tambem deve ser preservado")
assert(files["user_themes/default/theme.json"])

reset("wiiblue")
dirs["user_themes/wiiblue"]=true
files["user_themes/wiiblue/anotacao.txt"]="PRESERVAR"
Th.scan()
assert(files["user_themes/wiiblue/anotacao.txt"]=="PRESERVAR")
assert(not files["user_themes/wiiblue/theme.json"],
  "nao substituir pasta de tema personalizado sem manifesto")
print("Distribuicao Force x2 e migracao offline seletiva Lira x4: OK")
