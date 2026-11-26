package.path="./src/?.lua;"..package.path
love={graphics={}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["ui.theme"]={}
package.loaded["ui.gfx"]={}
package.loaded["lib.util"]={}
package.loaded["core.covers"]={}
package.loaded["core.osdetect"]={}
package.loaded["core.esthemes"]={}
package.loaded["core.esgallery"]={}
local S=require("ui.screens.esthemes")
local inst=setmetatable({secondary="all",items={},sel=1},{__index=S})
local downloads=0
local current=inst
local f=assert(io.open("src/main.lua"))
local main=f:read("*a");f:close()
-- Exercise the actual START dispatch block with mocked application state.
local block=assert(main:match('(  if act == "start" then\n.-\n  end)\n  if App.dialog then'))
local dispatch=assert(loadstring("return function(act)\n"..block.."\nend"))()
local env={App={current=function()return current end,open_downloads=function()downloads=downloads+1 end},
Installer={},Runtimes={},Uninstall={}}
setfenv(dispatch,env)
dispatch("start")
assert(inst.options and inst.options.sel==1 and downloads==0,"START must open theme options")
current={}
dispatch("start")
assert(downloads==1,"START must open downloads on other screens")
current=inst;inst.options=nil
env.Installer.job={background=true}
dispatch("start")
assert(inst.options and downloads==1,"background download must not intercept theme options")
inst.options=nil;env.Installer.job={background=false}
dispatch("start")
assert(not inst.options and downloads==2,"foreground progress retains original routing")
print("PASS START routing: theme options, background, and global downloads")

-- All installed origins must expose the removal action, including protected themes.
local ES=require("core.esthemes")
ES.state_loc=function()return "installed" end
ES.update_available=function()return false,nil end
for _,origin in ipairs({"user","thememaster","hub","firmware"}) do
 local th={id="local:"..origin,name="Theme",is_local=true,loc={origin=origin,xml_ok=true,readable=true}}
 local buttons=inst:view_buttons(th)
 local remove=false
 for _,b in ipairs(buttons) do if b.id=="remove" then remove=true end end
 assert(remove,"missing remove for "..origin)
end
print("PASS visible remove action for all installed origins")
