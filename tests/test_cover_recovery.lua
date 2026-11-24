package.path = "./game/?.lua;./game/?/init.lua;" .. package.path
local now, files, calls, logs = 0, {}, {}, {}
love = {timer = {getTime = function() return now end},
  filesystem = {createDirectory = function() end, getSaveDirectory = function() return "/save" end,
    getInfo = function(p) return files[p] and {type="file"} or nil end,
    remove = function(p) files[p] = nil; return true end},
  graphics = {newImage = function(p)
    assert(files[p] == "valid", "corrupt")
    return {setFilter=function() end, release=function() end}
  end}}
package.loaded["config"] = {APP_DIR="/app", COVER_CACHE_MAX=14}
package.loaded["lib.util"] = {log=function(...) logs[#logs+1]={...} end}
package.loaded["core.fetcher"] = {get=function(kind,url,out,cb) calls[#calls+1]={out=out,cb=cb} end, drop_covers=function() end}
local C = require("core.covers")
C.init()
local p = {slug="test",cover="https://r36s-roms-covers.james-spanico.workers.dev/covers/gb/test.jpg"}
assert(C.get(p)==nil and #calls==1)
C.reset_pending()
C.get(p); assert(#calls==1,"nao duplicar download ativo")
calls[1].cb(false,nil,"rc=28")
C.get(p); assert(#calls==1,"sem repetir a cada frame")
now=11; C.get(p); assert(#calls==2,"retry automatico")
local file=calls[2].out:gsub("^/save/","")
files[file]="bad"; calls[2].cb(true)
assert(C.get(p)==nil and files[file]==nil,"remover cache corrompido")
now=22; C.get(p); assert(#calls==3,"novo download apos cache invalido")
files[file]="valid"; calls[3].cb(true)
assert(C.get(p) and #calls==3,"capa carregada")
package.loaded["core.covers"]=nil
C=require("core.covers"); C.init()
assert(C.get(p) and #calls==3,"cache persistente apos reabrir")
print("COVER RECOVERY: OK - retry, cache invalido, duplicatas e reabertura")
