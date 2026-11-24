package.path="./game/?.lua;"..package.path
local T=require("ui.theme")
local P=require("ui.color_schemes")
local original={bg0=T.hex("#07100A"),accent=T.hex("#4CD964"),green=T.hex("#4CD964"),red=T.hex("#FF4D6A")}
local style={layout="xdash",list="grid",card={fill=T.hex("#1E2220")}}
for _,p in ipairs(P.LIST) do
 local c,s=P.resolve(original,style,p.id)
 assert(s.layout=="xdash" and s.list=="grid")
 assert(c.green[2]==original.green[2] and c.red[1]==original.red[1])
 if p.id~="original" then assert(c.accent[1]==T.hex(p.accent)[1] and s.focus[1]==c.accent[1]) end
end
assert(original.accent[1]==T.hex("#4CD964")[1] and style.focus==nil)
assert(P.step("original",-1,true)=="cyan" and P.step("cyan",1,true)=="original")
assert(not P.valid("bad") and P.label("bad")=="Original")
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={}
package.loaded["lib.util"]={}
package.loaded["ui.gfx"]={}
package.loaded["core.catalog"]={}
package.loaded["core.covers"]={}
package.loaded["ui.icons"]={}
package.loaded["core.updnotice"]={pending=function()return false end}
love={graphics={}}
local opened
App={push=function(s,p)opened=s end}
local XD=require("ui.xdash")
local S={open=function(id)opened=id end,feat_go=function(self,d)self.delta=d end}
local self={featured={{id="test"}},feat_i=1}
XD.action(S,self,"a");assert(opened=="roms")
XD.action(S,self,"left");assert(self.xd_zone=="left" and self.xd_left==1)
XD.action(S,self,"a");assert(opened=="details")
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="installed")
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="favorites")
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="downloads")
XD.action(S,self,"r1");assert(self.delta==1)
XD.action(S,self,"right");assert(self.xd_zone=="right")
local found=false;for _,it in ipairs(self.xd_tiles) do assert(it.id~="installed");if it.id=="esthemes" then found=true end end
assert(found and #self.xd_tiles==8)
print("COLOR NEON: OK - paletas independentes, menu e atalhos")
