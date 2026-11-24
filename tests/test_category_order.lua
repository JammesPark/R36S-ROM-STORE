package.path = "./game/?.lua;./game/?/init.lua;" .. package.path
local Catalog = require("core.catalog")
local result, err = Catalog.parse({categories={{id="z",name="Zulu"},{id="cps3",name="CPS3"},{id="a",name="alpha"},{id="cps1",name="CPS1"}},ports={}})
assert(result, tostring(err))
local games={}
for _, c in ipairs(result.categories) do if c.section=="games" then games[#games+1]=c.id end end
assert(table.concat(games,",")=="a,cps1,cps3,z", "ordem dos sistemas: "..table.concat(games,","))
print("CATEGORY ORDER: OK")
