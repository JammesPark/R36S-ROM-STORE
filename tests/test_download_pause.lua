package.path="./game/?.lua;"..package.path
local disk,job={},nil
love={timer={getTime=function()return 1 end},filesystem={read=function()return nil end,write=function()return true end}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={APP_DIR="/app"}
package.loaded["lib.util"]={write_file=function(p,s)disk[p]=s;return true end,read_file=function(p)return disk[p]end,log=function()end,clamp=function(x,a,b)return math.max(a,math.min(x,b))end}
package.loaded["core.catalog"]={catalog_source=function()return "r36s_own"end}
local I={busy=function()return false end,can_pause=function(j)return j and j.phase=="download"end,pause=function()return true end}
package.loaded["core.installer"]=I
I.start=function(p,o) I.job={phase="download",opts=o};return true end
local oldrename,oldremove=os.rename,os.remove
os.rename=function(a,b)disk[b]=disk[a];disk[a]=nil;return true end
os.remove=function(p)disk[p]=nil;return true end
local D=require("core.downloads")
local p={id="rom-1",slug="rom-1",name="Teste",section="games",category_id="gb",download_url="https://example.org/game.gb"}
assert(D.enqueue(p,{mode="rom",rom_system="gb",dest_dir="/roms/gb"}))
local e=D.pump()
assert(e and D.can_pause(e) and D.pause(e))
I.job.result="paused";I.job.done=100;I.job.total=1000
D.on_finished(I.job)
assert(e.state=="paused" and e.done==100 and D.percent(e)==10 and D.pending(p.id)==e)
assert(D.history_count()==0 and D.pump()==nil)
package.loaded["core.downloads"]=nil
D=require("core.downloads");D.load()
e=D.list[1];assert(e and e.state=="paused" and e.done==100 and e.opts.resume_download)
assert(D.resume(e) and D.pump()==e and I.job.opts.resume_download)
os.rename,os.remove=oldrename,oldremove
print("DOWNLOAD PAUSE: OK - fila persistente, retomada e progresso")
