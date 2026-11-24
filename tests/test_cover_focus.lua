package.path="./game/?.lua;"..package.path
local queue, active, canceled={},nil,0
love={timer={getTime=function()return 0 end},filesystem={createDirectory=function()end,getSaveDirectory=function()return "/save"end,getInfo=function()return nil end}}
package.loaded["config"]={APP_DIR="/app",COVER_CACHE_MAX=14}
package.loaded["lib.util"]={log=function()end}
package.loaded["core.fetcher"]={
get=function(kind,url,out,cb) queue[#queue+1]={url=url,cb=cb} end,
drop_covers=function()
  for _,q in ipairs(queue) do q.cb(false,nil,"cancelado");canceled=canceled+1 end
  queue={}
end}
local C=require("core.covers"); C.init()
local owner={}
local function item(i)return {slug="rom"..i,cover="https://example.org/"..i..".jpg"}end
C.focus_view(owner,"page1",item(1))
active=table.remove(queue,1)
C.get(item(2)); C.get(item(3))
assert(#queue==2)
C.focus_view(owner,"page50",item(300))
assert(canceled==2 and #queue==1 and queue[1].url=="https://example.org/300.jpg")
C.get(item(301))
assert(C.focus_view(owner,"page50",item(300))==false and #queue==2)
active.cb(true)
C.focus_view(owner,"page1",item(2))
assert(#queue==1 and queue[1].url=="https://example.org/2.jpg")
print("COVER FOCUS: OK - salto de pagina, selecao atual e retorno")
