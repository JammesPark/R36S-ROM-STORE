-- Atualizacao direta v0.0.33-beta -> v0.6.0-beta, inclusive saltando versoes.
package.path="game/?.lua;game/?/init.lua;"..package.path
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["config"]={VERSION_NUM="0.0.33-beta"}
package.loaded["lib.util"]={}
package.loaded["lib.json"]={decode=function()return nil end}
package.loaded["core.fetcher"]={}
package.loaded["core.updater.manager"]={}
local Rules=require("core.updater.rules")
local Update=require("core.update")
assert(Rules.valid_version("0.6.0-beta"))
assert(Rules.compare("0.6.0-beta","0.0.33-beta")>0)
assert(Rules.compare("0.6.0-beta","0.5.4-beta")>0)
assert(Rules.compare("0.6.0-beta","0.6.0-beta")==0)
local full="https://example.com/update_full.zip"
local inc="https://example.com/update.zip"
local feed={
  version="0.6.0-beta",url="https://example.com/install.zip",size=999,
  full_url=full,full_size=999,full_sha256=string.rep("a",64),
  incremental_url=inc,incremental_size=100,incremental_sha256=string.rep("b",64),
  incremental_min_version="0.0.33",incremental_max_version="0.0.33"
}
assert(Update.select_package(feed,"0.0.33-beta").url==inc)
for _,prior in ipairs({"0.0.20-beta","0.0.29-beta","0.0.32-beta"}) do
  local p=assert(Update.select_package(feed,prior))
  assert(p.url==full and p.package_kind=="full",prior)
end
assert(Rules.compat({version="0.6.0-beta"},"0.0.33-beta"))
print("Migracao 0.0.33 -> 0.6.0-beta e atualizacoes cumulativas: OK")
