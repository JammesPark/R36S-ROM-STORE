-- Teste de comportamento REAL da sincronizacao de temas no inicio do LÖVE.
-- Simula love.filesystem: copia somente temas opcionais previamente instalados,
-- preserva extras, bloqueia downgrade e nao confirma versao em copia parcial.
package.path = "src/?.lua;src/?/init.lua;" .. package.path
package.loaded["lib.i18n"] = {L=function(s) return s end}
package.loaded["config"] = {}
package.loaded["lib.util"] = {
  clamp=function(v,a,b) return math.max(a,math.min(v,b)) end,
  log=function() end, trim=function(s) return s:match("^%s*(.-)%s*$") end,
}
package.loaded["ui.theme"] = {
  parse_hex=function(s) if type(s)=="string" and s:match("^#%x%x%x%x%x%x$") then return {1,1,1,1} end end,
}
local json=require("lib.json")
local colors={}
for _,k in ipairs({"bg0","bg1","bg2","bg3","line","text","dim","faint",
  "accent","accent2","yellow","green","red","orange","black","shadow"}) do
  colors[k]="#123456"
end
local function manifest(id,v)
  return json.encode({id=id,version=v,name=id,colors=colors,style={background="modern",layout="force"}})
end
local names={"background_v4.png","selected_tiles_v4.png","preview.png",
  "logo_header.png","logo_menu.png","logo_about.png","logo_splash.png"}
local files,dirs,denied={},{},{}
local function reset(installed_version, bundled_version, with_extra)
  files,denied={},{}
  dirs={["themes"]=true,["theme_updates"]=true,["theme_updates/forcesith"]=true,
    ["user_themes"]=true}
  files["theme_updates/forcesith/theme.json"]=manifest("forcesith",bundled_version)
  for _,name in ipairs(names) do files["theme_updates/forcesith/"..name]="NEW/"..name end
  if installed_version then
    dirs["user_themes/forcesith"]=true
    files["user_themes/forcesith/theme.json"]=manifest("forcesith",installed_version)
    for _,name in ipairs(names) do files["user_themes/forcesith/"..name]="OLD/"..name end
    if with_extra then files["user_themes/forcesith/custom_notes.txt"]="PRESERVAR" end
  end
  dirs["user_themes/custom"]=true
  files["user_themes/custom/theme.json"]=manifest("custom","5.0.0")
  files["user_themes/custom/art.png"]="PERSONALIZADO"
end
love={filesystem={
  getInfo=function(p,typ)
    local t=dirs[p] and "directory" or (files[p] and "file" or nil)
    if t and (not typ or typ==t) then return {type=t} end
  end,
  getDirectoryItems=function(root)
    local a,seen={},{}
    local pre=root.."/"
    for p in pairs(files) do
      if p:sub(1,#pre)==pre then
        local name=p:sub(#pre+1):match("^[^/]+")
        if name and not seen[name] then seen[name]=true;a[#a+1]=name end
      end
    end
    for p in pairs(dirs) do
      if p:sub(1,#pre)==pre then
        local name=p:sub(#pre+1):match("^[^/]+")
        if name and not seen[name] then seen[name]=true;a[#a+1]=name end
      end
    end
    table.sort(a)
    return a
  end,
  read=function(p) return files[p] end,
  write=function(p,data)
    if denied[p] then return false end
    files[p]=data
    return true
  end,
}}
local Themes=require("core.themes")
local function scan() Themes.scan() end
reset("1.0.11","1.0.12",true)
scan()
assert(json.decode(files["user_themes/forcesith/theme.json"]).version=="1.0.12",
  "Tema instalado nao foi atualizado")
for _,name in ipairs(names) do
  assert(files["user_themes/forcesith/"..name]=="NEW/"..name,
    "Asset nao atualizado: "..name)
end
assert(files["user_themes/forcesith/custom_notes.txt"]=="PRESERVAR","Arquivo extra perdido")
assert(files["user_themes/custom/art.png"]=="PERSONALIZADO","Tema customizado perdido")
assert(Themes.by_id.forcesith and Themes.by_id.forcesith.version=="1.0.12")
reset(nil,"1.0.12",false)
scan()
assert(files["user_themes/forcesith/theme.json"]==nil and
  not dirs["user_themes/forcesith"],"Instalou opcional sem permissao")
reset("1.0.13","1.0.12",false)
scan()
assert(json.decode(files["user_themes/forcesith/theme.json"]).version=="1.0.13",
  "Rebaixou tema instalado")
reset("1.0.11","1.0.12",false)
denied["user_themes/forcesith/preview.png"]=true
scan()
assert(json.decode(files["user_themes/forcesith/theme.json"]).version=="1.0.11",
  "Confirmou upgrade mesmo com falha de escrita")
denied={}
scan()
assert(json.decode(files["user_themes/forcesith/theme.json"]).version=="1.0.12",
  "Falha de escrita nao foi recuperada no novo scan")
print("Tema opcional: atualização quando instalado, 7 assets, preservação, opt-in, downgrade e retry OK")
