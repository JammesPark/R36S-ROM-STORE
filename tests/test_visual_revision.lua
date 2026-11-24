package.path="./src/?.lua;"..package.path
love={graphics={}}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={}
local menu=require("ui.menu_entries").items()
local ids={};for _,v in ipairs(menu) do ids[#ids+1]=v.id end
assert(table.concat(ids,",")=="roms,bios,library,installed,downloads,favorites,esthemes,tools,settings,about,exit")
package.loaded["ui.theme"]={c={}}
package.loaded["ui.gfx"]={}
package.loaded["ui.icons"]={}
package.loaded["core.favorites"]={}
local cats={{id="manutencao",name="Manutenção",section="tools"}}
local tool={id="sd",name="SD",short="Análise do cartão",category_id="manutencao",category="Manutenção",builtin=true,screen="sdanalyzer"}
package.loaded["core.catalog"]={categories=cats,filter=function()return {}end}
package.loaded["core.tools"]={LIST={tool},for_filter=function()return {tool}end}
local opened
App={push=function(s,p)opened=s end,pop=function()opened="back"end}
local U=require("ui.screens.utilities");U:enter();assert(#U.cats==3 and U.cats[3].id=="installed")
U:action("down");assert(U.sel==2 and U.focus=="categories")
U:action("a");assert(U.focus=="rows")
U:action("a");assert(opened=="sdanalyzer")
U:action("b");assert(U.focus=="categories")
U:action("b");assert(opened=="back")
local P=require("ui.side_panel")
assert(P.DX==220 and P.DW==406 and P.FOOT_Y==P.LIST_Y+P.VISIBLE*(P.ROW_H+P.GAP)+4)
local calls={}
P.sidebar=function(cats,sel,top,focused) calls.sidebar=focused;return top end
P.summary=function(cat) calls.summary=cat.id end
P.heading=function(cat) calls.heading=cat.id end
P.row=function(y) calls.row=y end
P.scrollbar=function() end
P.description=function(cat,label) calls.description=label end
package.loaded["ui.gfx"].header=function()end
package.loaded["ui.gfx"].hints=function()end
package.loaded["ui.gfx"].text_fit=function()end
package.loaded["ui.theme"].f={}
package.loaded["ui.icons"].draw=function()end
U:enter();U:draw();assert(calls.sidebar==true and calls.summary=="all")
U:action("a");U:draw();assert(calls.sidebar==false and calls.heading=="all" and calls.row==P.LIST_Y and calls.description=="SD")
print("VISUAL REVISION: OK - ordem menu, navegacao e layout compartilhado")
