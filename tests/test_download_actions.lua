package.path="./game/?.lua;"..package.path
local calls={}
local function hit(k)calls[k]=(calls[k] or 0)+1 end
love={graphics={}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["ui.theme"]={c={}}
package.loaded["ui.gfx"]={}
package.loaded["lib.util"]={clamp=function(x,a,b)return math.max(a,math.min(x,b))end,format_bytes=tostring}
package.loaded["config"]={}
package.loaded["core.catalog"]={}
package.loaded["core.covers"]={}
package.loaded["ui.icons"]={}
package.loaded["core.runtimes"]={}
local e={name="ROM teste",state="downloading",job={phase="download",background=true},done=100,total=1000}
local D={list={e},background=true,history_count=function()return 1 end,clear_history=function()hit("history")end,
 can_pause=function(q)return q and q.state=="downloading" and q.job and not q.job.pausing end,
 pause=function()hit("pause");return true end,resume=function()hit("resume");return true end,
 cancel=function()hit("cancel");return true end,percent=function()return 10 end}
package.loaded["core.downloads"]=D
local I={job=e.job,can_pause=function(j)return j and j.phase=="download" end,pause=function()hit("overlay_pause");return true end}
package.loaded["core.installer"]=I
App={show_dialog=function(d)App.dialog=d end,toast=function()end,pop=function()hit("back")end,push=function(s)hit(s)end}
local S=require("ui.screens.downloads");S:enter()
local function button(name)
 for _,b in ipairs(App.dialog.buttons)do if b.label==name then return b end end
end
S:action("a");assert(e.job.background==false and D.background==false)
S:action("r2");assert(calls.pause==1)
S:action("y");assert(calls.pause==1)
S:action("l2");assert(App.dialog.list and button("Pausar") and button("Cancelar") and button("Ver progresso"))
button("Pausar").fn();assert(calls.pause==2)
e.job.phase="install";S:action("l2");assert(not button("Cancelar"))
e.job=nil;e.state="paused"
S:action("r2");assert(calls.resume==1)
S:action("a");assert(button("Retomar") and button("Cancelar"))
button("Retomar").fn();assert(calls.resume==2)
S:action("l2");button("Cancelar").fn();assert(App.dialog.sel==2 and calls.cancel==nil)
button("CANCELAR DOWNLOAD").fn();assert(calls.cancel==1)
S:action("x");assert(App.dialog.title=="Limpar histórico?");button("LIMPAR").fn();assert(calls.history==1)
S:action("select");assert(calls.wifi==1)
S:action("b");assert(calls.back==1)
e.state="waiting";S:action("a");assert(App.dialog.title=="Tirar da fila?")
local O=require("ui.overlay");I.job={phase="download"}
O.install_action(App,"x");assert(not calls.overlay_pause)
O.install_action(App,"r2");assert(calls.overlay_pause==1)
O.install_action(App,"y");assert(I.job.background and D.background)
O.install_action(App,"b");assert(I.job.ask_cancel)
print("DOWNLOAD ACTIONS: OK - R2 pausa, L2 menu, X historico, A/B/Y originais")
