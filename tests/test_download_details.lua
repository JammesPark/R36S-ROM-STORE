package.path="./src/?.lua;"..package.path
package.loaded["lib.i18n"]={L=function(s)return s end,tr=function(s)return s end}
package.loaded["lib.util"]={clamp=function(x,a,b)return math.max(a,math.min(x,b)) end,format_bytes=tostring,format_speed=tostring,format_time=tostring}
package.loaded["core.installer"]={}
package.loaded["ui.theme"]={c={}}
package.loaded["ui.gfx"]={}
package.loaded["core.covers"]={}
package.loaded["ui.icons"]={}
local p={id="rom",name="ROM"}
local C={by_id={rom=p}};package.loaded["core.catalog"]=C
local saved
love={graphics={},filesystem={write=function(k,v)saved=v end,read=function()return saved end}}
local D=require("core.downloads")
local opened,params,installed
App={show_dialog=function(d)App.dialog=d end,push=function(s,p)opened,params=s,p end,install=function(p)installed=p end,toast=function()end}
local S=require("ui.screens.downloads")
local function select(e)
 D.list={e};S:enter();App.dialog=nil;S:action("y");assert(App.dialog.title=="Informações");return App.dialog.buttons
end
for _,state in ipairs({"done","error","cancelled","waiting","downloading"}) do
 D.list={{pid="rom",name="ROM",state=state,section="games"}};S:enter();App.dialog=nil;opened=nil
 S:action("a");assert(opened=="details" and params.port==p and not App.dialog)
end
for _,state in ipairs({"done","error","cancelled"}) do
 local b=select({pid="rom",name="ROM",state=state,section="games"})
 b[1].fn();assert(opened=="details" and params.port==p)
 b[2].fn();assert(installed==p)
end
D.list={{pid="estheme:owner/theme",name="Tema",state="done",section="themes"}};S:enter();App.dialog=nil;S:action("a");assert(opened=="esthemes" and params.download_key=="owner/theme" and not App.dialog)
local b=select({pid="estheme:owner/theme",name="Tema",state="done",section="themes"})
b[1].fn();assert(opened=="esthemes" and params.download_key=="owner/theme")
b[2].fn();assert(params.download_retry)
for id,screen in pairs({bios_package="bios",portmaster_app="pmmanager"}) do
 local b=select({pid=id,name=id,state="done",section="tools"});b[1].fn();assert(opened==screen)
end
local b=select({pid="unknown",name="Antigo",state="done"});assert(#b==1)
local b=select({pid="local",name="Arquivo",state="error",local_operation=true});b[1].fn();assert(opened=="files")
D.list={{pid="rom",name="ROM",state="waiting",opts={local_file="/roms/private.zip"}}}
D.cancel(D.list[1]);assert(saved and not saved:find("private.zip",1,true))
D.list={};D.load();assert(D.list[1].local_operation and D.target(D.list[1],C)=="files")
print("PASS history information, reopen, safe retry, theme/BIOS/PortMaster routing and local privacy")
