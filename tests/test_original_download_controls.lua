package.path="./src/?.lua;"..package.path
love={graphics={}}
local calls={}
local function hit(k)calls[k]=(calls[k] or 0)+1 end
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["ui.theme"]={c={}}
package.loaded["ui.gfx"]={}
package.loaded["lib.util"]={clamp=function(x,a,b)return math.max(a,math.min(x,b))end}
package.loaded["config"]={}
package.loaded["core.catalog"]={}
package.loaded["core.covers"]={}
package.loaded["ui.icons"]={}
package.loaded["core.runtimes"]={}
local e={name="Teste",state="downloading",job={phase="download",background=true}}
local D={list={e},background=true,history_count=function()return 1 end,clear_history=function()hit("history")end}
package.loaded["core.downloads"]=D
local I={job=e.job,cancel=function()hit("cancel")end}
package.loaded["core.installer"]=I
App={show_dialog=function(d)App.dialog=d end,toast=function()end,pop=function()hit("back")end,push=function(s)hit(s)end}
local S=require("ui.screens.downloads");S:enter()
S:action("a");assert(not e.job.background and not D.background)
for _,key in ipairs({"l2","r2","y","select"}) do S:action(key) end
assert(not App.dialog and not calls.wifi)
S:action("x");assert(App.dialog.title=="Limpar histórico?")
App.dialog.buttons[1].fn();assert(calls.history==1)
S:action("b");assert(calls.back==1)
e.job=nil;e.state="waiting";S:action("a");assert(App.dialog.title=="Tirar da fila?")
local O=require("ui.overlay");I.job={phase="download"}
O.install_action(App,"r2");assert(not I.job.background and not I.job.ask_cancel)
O.install_action(App,"y");assert(I.job.background and D.background)
O.install_action(App,"b");assert(I.job.ask_cancel)
package.loaded["core.wifijob"]={start=function(op) assert(op~="radio");hit(op);return {}end}
package.loaded["core.net"]={}
local W=require("ui.screens.wifi");W:enter()
W.status={nmcli=true,nm_running=true,radio=true,iface="wlan0"}
assert(#W:items()==1 and W:items()[1].kind=="scan")
W:action("r1");assert(#W:items()==0)
W:action("up");W:action("down");W:action("a")
assert(W.sel==1)
print("ORIGINAL CONTROLS: OK - atalhos restaurados, sem menu de pausa ou interruptor Wi-Fi")
