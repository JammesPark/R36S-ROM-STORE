package.path='./src/?.lua;./src/?/init.lua;'..package.path
local M=require('core.esthemes_unified')
local json=require('lib.json')
local f=assert(io.open('src/catalog/themegallery_metadata.json'))
local extra=json.decode(f:read('*a'));f:close()
assert(#extra==53)
local total=0
for _,g in ipairs(extra) do assert(#g.previews>=1 and #g.previews<=3);total=total+#g.previews end
assert(total==149)
local function t(id,name,compat,res,collection)
 return {id=id,name=name,project_url='https://github.com/test/'..id,download_url='https://github.com/test/'..id..'/archive/HEAD.zip',compat=compat,res=res,collection=collection}
end
local themes={t('a','Alpha',{arkos='compativel'},{['640x480']='yes'}),
 t('b','Beta',{arkos='experimental'},{['640x480']='no'}),
 t('c','Gamma',{arkos='experimental'},{}),t('d','Delta',{},{}),t('e','Collection',{arkos='experimental'},{},'test')}
assert(M.status(themes[1],'arkos','640x480')=='compativel')
assert(M.status(themes[2],'arkos','640x480')=='incompatible')
assert(not M.can_install(themes[2],'arkos','640x480'))
assert(M.can_install(themes[4],'arkos','640x480'))
assert(M.needs_confirmation(themes[4],'arkos','640x480'))
assert(not M.can_install(themes[4],nil,'640x480'))
themes[4].compat.arkos='incompatible';assert(not M.can_install(themes[4],'arkos','640x480'));themes[4].compat.arkos=nil
themes[4].download_audit={url=themes[4].download_url,status='missing'};assert(not M.can_install(themes[4],'arkos','640x480'));themes[4].download_audit=nil
local opts={mode='all',os='arkos',size='640x480',favorites={},installed=function()return false end}
assert(#M.select(themes,opts)==5)
opts.mode='compat';assert(#M.select(themes,opts)==1)
opts.mode='all';opts.secondary='collections';assert(#M.select(themes,opts)==1)
opts.secondary='all';opts.query='beta';assert(#M.select(themes,opts)==1)
opts.query='';opts.mode='favorites';opts.favorites[M.key(themes[1])]=true;assert(#M.select(themes,opts)==1)
local list={{id='albedo',project_url=extra[1].project_url,compat={arkos='compativel'},res={}}}
M.merge_extra(list,extra);assert(#list==53);assert(list[1].gallery_size=='17.9MB');assert(list[1].cover==extra[1].previews[1]);assert(#list[1].previews==3);assert(list[2].cover==extra[2].previews[1]);assert(list[2].src=='themegallery' and M.can_install(list[2],'arkos','640x480') and M.needs_confirmation(list[2],'arkos','640x480'))
M.merge_extra(list,extra);assert(#list==53)
print('PASS unified gallery: 53 metadata rows, no duplicate repositories, filters, compatibility gate')

local x={id='uncovered',project_url='https://github.com/Owner/Repo',cover=''}
M.apply_previews({x},{['owner/repo']={url='https://example.org/screenshot.png'}})
assert(x.cover=='https://example.org/screenshot.png')
local original=list[1].cover
M.apply_previews(list,{[M.key(list[1])]={url='https://example.org/other.png'}})
assert(list[1].cover==original)
print('PASS verified preview index and local image priority')

-- Shared FIFO: unknown themes require explicit confirmation, don't interrupt ROMs,
-- are deduplicated, can be cancelled, and are completed by the global poller.
local tick=10
love={filesystem={read=function()return nil end,write=function()return true end},timer={getTime=function()tick=tick+1;return tick end}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["lib.util"]={clamp=function(x,a,b)return math.min(b,math.max(a,x)) end}
local I={busy=function()return false end,start=function()return true end}
I.start=function()I.job={phase="download",done=0,total=100};return true end
package.loaded["core.installer"]=I
package.loaded["core.catalog"]={catalog_source=function()return "test" end}
local E={update=function()end}
E.start_install=function(th,dir,os,folder,size,confirmed)assert(confirmed);E.job={phase="download",done=10,total=100,speed=10,thread={isRunning=function()return false end}};return true end
E.cancel=function()E.job.finished=true;E.job.cancelled=true end
package.loaded["core.esthemes"]=E
local D=require("core.downloads")
assert(D.enqueue({id="rom",name="ROM",section="games"},{}))
local r=D.pump();assert(r.pid=="rom")
assert(not D.enqueue_theme(themes[4],"/themes","arkos","delta","640x480",false,false))
assert(D.enqueue_theme(themes[4],"/themes","arkos","delta","640x480",true,false))
assert(not D.enqueue_theme(themes[4],"/themes","arkos","delta","640x480",true,false))
assert(D.waiting_count()==1 and D.pump()==nil and not E.job)
D.on_finished({download_entry=r,result="done"})
local e=D.pump();assert(e.theme==themes[4] and e.job)
D.update_theme();assert(e.done==10 and e.speed==10 and e.eta==9)
D.cancel(e);D.update_theme();assert(e.state=="cancelled" and not E.job)
assert(D.enqueue_theme(themes[4],"/themes","arkos","delta","640x480",true,false))
e=D.pump();E.job.finished=true;E.job.ok=true;D.update_theme()
assert(e.state=="done" and not E.job and E.install_revision==2)
print("PASS theme confirmation, shared FIFO, duplicate prevention, real progress, cancellation and completion")

-- Curated upstream entries retain the legacy ThemeGallery IDs and merge without duplicates.
local cf=assert(io.open("src/catalog/es_themes.json"))
local curated=json.decode(cf:read("*a")).themes;cf:close()
local selected={}
for _,th in ipairs(curated) do
  if th.author=="jovemlcxx" and (th.folder=="es-theme-switch2-fcamod" or th.folder=="es-theme-steamdeck" or th.folder=="es-theme-xmb-fcamod") then
    assert(th.id=="tg-jovemlcxx--"..th.folder and th.updated~="" and #th.upstream_commit==40)
    assert(th.download_url==th.project_url.."/archive/refs/heads/main.zip")
    selected[#selected+1]=th
  end
end
assert(#selected==3)
M.merge_extra(selected,extra)
local counts={}
for _,th in ipairs(selected) do local k=M.key(th);counts[k]=(counts[k] or 0)+1 end
for _,slug in ipairs({"es-theme-switch2-fcamod","es-theme-steamdeck","es-theme-xmb-fcamod"}) do assert(counts["jovemlcxx/"..slug]==1) end
print("PASS upstream Switch 2, Steam Deck and XMB entries, stable IDs and deduplication")

opts.mode="updates";opts.has_update=function(th)return th.id=="a" end;assert(#M.select(themes,opts)==1)
print("PASS updates filter")
