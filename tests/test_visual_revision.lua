package.path="./game/?.lua;"..package.path
love={graphics={}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={}
local menu=require("ui.menu_entries").items()
local ids={};for _,v in ipairs(menu) do ids[#ids+1]=v.id end
assert(table.concat(ids,",")=="roms,bios,library,installed,downloads,favorites,esthemes,tools,settings,about,exit")
package.loaded["ui.theme"]={c={}}
package.loaded["ui.gfx"]={}
package.loaded["ui.icons"]={}
local cats={{id="manutencao",name="Manutenção",section="tools"}}
local tool={id="sd",name="SD",category_id="manutencao",category="Manutenção",builtin=true,screen="sdanalyzer"}
package.loaded["core.catalog"]={categories=cats,filter=function()return {}end}
package.loaded["core.tools"]={LIST={tool},for_filter=function()return {tool}end}
local opened
App={push=function(s,p)opened=s end,pop=function()opened="back"end}
local U=require("ui.screens.utilities");U:enter();assert(#U.cats==2)
U:action("down");assert(U.sel==2 and U.focus=="categories")
U:action("a");assert(U.focus=="rows")
U:action("a");assert(opened=="sdanalyzer")
U:action("b");assert(U.focus=="categories")
U:action("b");assert(opened=="back")
print("VISUAL REVISION: OK - ordem menu e navegacao utilitarios")
