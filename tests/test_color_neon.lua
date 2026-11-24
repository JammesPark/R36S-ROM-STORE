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
-- Destaque e painel de catalogo nao tem atalhos selecionaveis.
XD.action(S,self,"down");assert(self.xd_zone=="left" and self.xd_left==1)
XD.action(S,self,"right");assert(self.xd_zone=="right" and self.xd_right==1)
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="esthemes")
XD.action(S,self,"down");assert(self.xd_right==7 and self.xd_shortcut==1)
XD.action(S,self,"a");assert(opened=="downloads")
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="favorites")
XD.action(S,self,"down");XD.action(S,self,"a");assert(opened=="installed")
XD.action(S,self,"down");assert(self.xd_shortcut==3)
XD.action(S,self,"r1");assert(self.delta==1)
XD.action(S,self,"right");XD.action(S,self,"a");assert(opened=="about")
XD.action(S,self,"right");XD.action(S,self,"a");assert(opened=="exit")
XD.action(S,self,"left");XD.action(S,self,"left");assert(self.xd_right==7)
XD.action(S,self,"up");XD.action(S,self,"a");assert(opened=="favorites")
XD.action(S,self,"up");XD.action(S,self,"a");assert(opened=="downloads")
XD.action(S,self,"up");XD.action(S,self,"a");assert(opened=="esthemes")
local expected={"roms","bios","tools","esthemes","library","settings","shortcuts","about","exit"}
assert(#self.xd_tiles==#expected)
for i,id in ipairs(expected) do assert(self.xd_tiles[i].id==id) end
print("COLOR NEON: OK - paletas independentes, menu e atalhos Matrix")

-- Preferencias independentes: exercita o modulo real de temas com armazenamento simulado.
local prefs={}
package.loaded["core.prefs"]={get=function(k)return prefs[k] end,set=function(k,v)prefs[k]=v end}
package.loaded["lib.util"]={trim=function(v)return v end,log=function()end}
package.loaded["ui.gfx"]={build_background=function()end}
local persisted="neongrid"
love.filesystem={read=function()return persisted end,write=function(_,v)persisted=v;return true end}
package.loaded["core.themes"]=nil
local Themes=require("core.themes")
local pulse={colors={accent=T.hex("#FF4F8B")},buttons={},style={}}
local matrix={colors={accent=T.hex("#4CD964")},buttons={},style={layout="xdash"}}
Themes.by_id={default=pulse,neongrid=matrix}
Themes.scan=function()end
local applied
T.apply_palette=function(c)applied=c end
prefs.ui_color="red"
Themes.init()
assert(Themes.current=="neongrid" and Themes.color_id()=="red")
assert(prefs.ui_color==nil and prefs.ui_color_neongrid=="red")
assert(Themes.apply("default",true) and Themes.color_id()=="original")
assert(applied.accent[1]==pulse.colors.accent[1])
assert(Themes.set_color("blue"))
assert(Themes.apply("neongrid",true) and Themes.color_id()=="red")
assert(Themes.set_color("original"))
assert(applied.accent[2]==matrix.colors.accent[2])
assert(Themes.apply("default",true) and Themes.color_id()=="blue")
assert(not Themes.set_color("bad") and Themes.color_id()=="blue")
Themes.init()
assert(Themes.current=="default" and Themes.color_id()=="blue")
print("THEME COLORS: OK - migracao, isolamento, persistencia e paletas originais")
