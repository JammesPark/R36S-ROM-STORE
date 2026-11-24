package.path="./game/?.lua;"..package.path
local radio, nm, calls=true,false,0
package.loaded["lib.util"]={
 exec_ok=function(cmd) if cmd:find("nmcli",1,true) then return nm end return true end,
 trim=function(s)return (s:gsub("^%s+",""):gsub("%s+$",""))end,
 shq=function(s)return "'"..s.."'"end,
 capture=function(cmd)
   if cmd:find("/sys/class/rfkill",1,true) then return (radio and "0 0\n" or "1 0\n") end
   if cmd:find("rfkill block wifi",1,true) then radio=false;calls=calls+1;return "__EXIT:0"end
   if cmd:find("rfkill unblock wifi",1,true) then radio=true;calls=calls+1;return "__EXIT:0"end
   if cmd:find("RUNNING general",1,true) then return "running\n__EXIT:0"end
   if cmd:find("radio wifi off",1,true) then radio=false;calls=calls+1;return "__EXIT:0"end
   if cmd:find("radio wifi on",1,true) then radio=true;calls=calls+1;return "__EXIT:0"end
   if cmd:find("radio wifi",1,true) then return (radio and "enabled" or "disabled").."\n__EXIT:0"end
   return "__EXIT:0"
 end
}
package.loaded["core.net"]={status=function()return {}end}
local W=require("core.wifi")
assert(W.status().radio_backend=="rfkill")
assert(W.radio(false) and not W.status().radio)
assert(W.radio(true) and W.status().radio)
nm=true
assert(W.status().radio_backend=="nmcli")
assert(W.radio(false) and not W.status().radio)
assert(W.radio(true) and W.status().radio and calls==4)
print("WIFI RADIO: OK - nmcli e rfkill sem interface visivel")
