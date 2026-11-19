package.path="game/?.lua;game/?/init.lua;"..package.path
local db={}
love={filesystem={
 read=function(k)return db[k] end,
 write=function(k,v)db[k]=v;return true end,
 getSaveDirectory=function()return "/tmp/r36sbr-test-ratings" end}}
local old=os.rename;os.rename=function()return false end
package.loaded["lib.json"]={
 encode=function(t)
  local rows={}
  for _,c in ipairs({"lira","r36sbr"}) do
   for id,v in pairs(t[c]) do rows[#rows+1]=c..":"..id..":"..v end
  end
  table.sort(rows);return table.concat(rows,";")
 end,
 decode=function(s)
  local t={lira={},r36sbr={}}
  for c,id,v in tostring(s):gmatch("([%w]+):([%w_-]+):([%w]+)") do t[c][id]=v end
  return t
 end}
package.loaded["core.catalog"]={catalog_source=function()return "r36sbr" end}
local R=require("core.ratings")
local p={id="aestheta"}
assert(R.get(p)==nil)
assert(R.counts(p).up==0 and R.counts(p).down==0)
assert(select(1,R.set(p,"up","r36sbr")))
assert(R.get(p,"r36sbr")=="up" and R.get(p,"lira")==nil)
assert(R.counts(p,"r36sbr").up==1 and R.counts(p,"r36sbr").down==0)
assert(select(1,R.set(p,"down","lira")))
assert(select(1,R.set(p,"down","r36sbr")))
assert(select(1,R.set(p,"down","r36sbr")))
assert(R.get(p,"r36sbr")==nil)
assert(R.counts(p,"r36sbr").up==0 and R.counts(p,"r36sbr").down==0)
assert(select(1,R.set(p,"up","r36sbr")))
R.load()
assert(R.get(p,"r36sbr")=="up" and R.get(p,"lira")=="down")
assert(R.get({id="aestheta",builtin=true},"r36sbr")==nil)
assert(not select(1,R.set(p,"neutral","r36sbr")))
os.rename=old
print("Votos locais offline, troca, remocao, isolamento e persistencia: OK")
