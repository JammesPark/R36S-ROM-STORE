-- Testes de TAR, senhas, multipartes e pendencias SD1/SD2 sem interface LÖVE.
package.path="src/?.lua;src/?/init.lua;"..package.path
local files = {
  ["/roms/ports"] = {
    "rar.part1.rar", "rar.part2.rar", "game.zip", "game.z01", "game.z02",
    "broken.part1.rar", "broken.part3.rar", "pack.7z.001", "pack.7z.002",
    "good.zip", "bad.rar",
  },
  ["/roms2/ports"] = {"second.zip", "second.tar.gz"},
}
local function isfile(path)
  local dir,name=path:match("^(.*)/([^/]+)$")
  for _,n in ipairs(files[dir] or {}) do if n==name then return true end end
  return false
end
local util={
  shq=function(s) return "'"..tostring(s):gsub("'","'\\''").."'" end,
  exists=isfile,
  is_dir=function(path) return files[path]~=nil end,
  file_size=function(path) return isfile(path) and 1024 or 0 end,
  safe_utf8=function(s)return s end,
  slug=function(s)return tostring(s):lower():gsub("[^%w]","_") end,
  read_file=function(path)
    if path=="/app/senhas.txt" then return "# comentario\r\nminhasenha\n\n outra  \r\n" end
  end,
}
util.capture=function(cmd)
  for dir,names in pairs(files) do
    if cmd:find("ls -1A",1,true) and cmd:find(dir,1,true) then
      return table.concat(names,"\n").."\n"
    end
    if cmd:find("stat -L",1,true) and cmd:find(dir,1,true) then
      local items={}
      for _,n in ipairs(names) do items[#items+1]="regular file|1024|1780000000|"..n end
      return table.concat(items,"\n").."\n"
    end
  end
  if cmd:find("unzip -Z1",1,true) then return "Jogo.sh\njogo/data\n" end
  if cmd:find("tar -t",1,true) then return "Jogo.sh\njogo/data\n" end
  return ""
end
package.loaded["lib.util"]=util
package.loaded["config"]={APP_DIR="/app",PORTS_DIR="/roms/ports"}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["core.portstorage"]={
  get=function(card)
    return {path=card=="sd1" and "/roms/ports" or "/roms2/ports",
            readable=true,card=card}
  end,
}
local A=require("core.archives")
assert(A.tar_kind("X.tar")=="TAR")
assert(A.tar_kind("X.TAR.GZ")=="TAR.GZ")
assert(A.tar_kind("X.tar.xz")=="TAR.XZ")
assert(A.tar_kind("X.TBZ2")=="TAR.BZ2")
local pw=A.passwords()
assert(pw[1]=="R36S ROMS STORE" and pw[2]=="R36XBR")
assert(pw[3]=="minhasenha" and pw[4]=="outra")
assert(A.is_saved("minhasenha") and not A.is_saved("desconhecida"))
local parts=A.parts("/roms/ports/rar.part2.rar")
assert(#parts==2 and parts[1]=="/roms/ports/rar.part1.rar")
local first, group=A.validate_parts("/roms/ports/rar.part2.rar")
assert(first==parts[1] and #group==2)
assert(A.total_size(first)==2048)
first,group=A.validate_parts("/roms/ports/broken.part3.rar")
assert(first==nil and type(group)=="string", "parte do meio ausente")
local z=A.parts("/roms/ports/game.z02")
assert(#z==3 and z[1]=="/roms/ports/game.z01" and z[3]=="/roms/ports/game.zip")
assert(A.first_part("/roms/ports/game.z02")=="/roms/ports/game.zip")
assert(A.validate_parts("/roms/ports/game.z02")=="/roms/ports/game.zip")
assert(A.first_part("/roms/ports/pack.7z.002")=="/roms/ports/pack.7z.001")
assert(A.is_extra_part("rar.part2.rar") and A.is_extra_part("game.z01"))
assert(not A.is_extra_part("game.zip"))
local PP=require("core.pendports")
local items=PP.scan()
local on={sd1=0,sd2=0}
for _,it in ipairs(items) do on[it.card]=on[it.card]+1 end
assert(on.sd1>=1 and on.sd2==2,"SD1/SD2 pendentes deveriam aparecer")
local second
for _,it in ipairs(items) do if it.name=="second.zip" then second=it end end
assert(second and second.dir=="/roms2/ports")
App={install=function(p,opts)
  assert(opts.dest_dir=="/roms2/ports" and opts.local_file==second.path)
  assert(opts.delete_source and opts.mode=="port")
end}
PP.install(second)
print("Arquivos TAR, senhas, partes incompletas, ZIP z01 e SD1/SD2: OK")
