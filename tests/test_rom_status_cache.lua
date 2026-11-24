package.path="./game/?.lua;"..package.path
local reads, checks, now=0,0,0
love={filesystem={read=function() reads=reads+1;return "data" end},timer={getTime=function()return now end}}
package.loaded["lib.json"]={decode=function()return {installed={dest_dir="/roms/gb",system="gb",entries={"game.gb"},card="SD1"}}end}
package.loaded["lib.util"]={exists=function()checks=checks+1;return true end}
package.loaded["core.romstorage"]={validate=function()return true end}
local R=require("core.rom_installed")
for i=1,15000 do assert(not R.get("missing"..i)) end
assert(reads==1 and checks==0)
for i=1,120 do assert(R.get("installed")) end
assert(checks==1)
now=6;assert(R.get("installed"));assert(checks==2)
R.invalidate();assert(R.get("installed"));assert(reads==2)
print("ROM STATUS CACHE: OK - 15000 ausentes sem consultas ao disco por ROM")
