-- A-Z / Recentes e alternancia X sem abrir janela do LÖVE.
package.path="src/?.lua;src/?/init.lua;"..package.path
package.loaded["lib.i18n"]={L=function(s)return s end,tr=function(s)return s end}
package.loaded["ui.theme"]={c={}}
package.loaded["lib.util"]={}
package.loaded["config"]={}
local prefs={list_sort="catalog"}
package.loaded["core.prefs"]={get=function(k)return prefs[k] end,set=function(k,v)prefs[k]=v end}
package.loaded["core.clock"]={}
package.loaded["core.catalog"]={added_day=function(p)
  local s=p.added
  if not s or not s:match("^%d%d%d%d%-%d%d%-%d%d$") then return nil end
  local clean=s:gsub("%-","")
  return tonumber(clean)
end}
App={status=function()return "none" end}
local X=require("ui.settings_extra")
assert(X.cycle_view_sort()=="name")
assert(X.cycle_view_sort()=="recent")
local items={{name="Antigo",added="2024-01-01"},{name="Novo",added="2026-11-17"},
  {name="Sem data"},{name="Medio",added="2026-01-05"}}
X.sort_ports(items,"list_sort")
assert(items[1].name=="Novo" and items[2].name=="Medio"
   and items[3].name=="Antigo" and items[4].name=="Sem data")
assert(X.cycle_view_sort()=="catalog")
assert(X.cycle_view_sort()=="name")
X.sort_ports(items,"list_sort")
assert(items[1].name=="Antigo" and items[4].name=="Sem data")
print("Ordenacao A-Z/Recentes, datas ausentes e ciclo com X: OK")
