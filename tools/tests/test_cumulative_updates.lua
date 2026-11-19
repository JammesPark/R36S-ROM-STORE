-- Valida o roteamento cumulativo sem abrir a janela LÖVE.
package.path = "game/?.lua;game/?/init.lua;" .. package.path
package.loaded["lib.i18n"] = { L = function(s) return s end }
package.loaded["config"] = { VERSION_NUM = "0.0.13-beta" }
package.loaded["lib.util"] = {}
package.loaded["lib.json"] = { decode = function() return nil end }
package.loaded["core.fetcher"] = {}
package.loaded["core.updater.manager"] = {}
local U = require("core.update")
local FULL = "https://github.com/test/releases/download/v0.0.14-beta/full.zip"
local INC = "https://github.com/test/releases/download/v0.0.14-beta/inc.zip"
local function feed()
  return {
    version = "0.0.14-beta",
    url = FULL, size = 12000, sha256 = ("a"):rep(64),
    full_url = FULL, full_size = 12000, full_sha256 = ("a"):rep(64),
    incremental_url = INC, incremental_size = 3000, incremental_sha256 = ("b"):rep(64),
    incremental_min_version = "0.0.13", incremental_max_version = "0.0.13",
  }
end
for _, current in ipairs({"0.0.10-beta", "0.0.11-beta", "0.0.12-beta"}) do
  local got, err = U.select_package(feed(), current)
  assert(got and got.url == FULL and got.package_kind == "full", current .. ": " .. tostring(err))
  assert(got.min_version == nil and got.max_version == nil)
  assert(got.sha256 == ("a"):rep(64) and got.size == 12000)
end
local normal = assert(U.select_package(feed(), "0.0.13-beta"))
assert(normal.url == INC and normal.package_kind == "incremental")
assert(normal.sha256 == ("b"):rep(64) and normal.size == 3000)
local legacy = feed()
legacy.url, legacy.sha256, legacy.size = INC, ("b"):rep(64), 3000
legacy.incremental_url, legacy.incremental_sha256, legacy.incremental_size = nil,nil,nil
legacy.incremental_min_version, legacy.incremental_max_version = nil,nil
legacy.min_version, legacy.max_version = "0.0.13","0.0.13"
local fixed = assert(U.select_package(legacy,"0.0.10-beta"))
assert(fixed.url == FULL and fixed.min_version == nil)
local blocked = {url=INC, min_version="0.0.13", max_version="0.0.13"}
local none, err = U.select_package(blocked, "0.0.10-beta")
assert(none == nil and err)
local generic = assert(U.select_package({url=FULL}, "0.0.10-beta"))
assert(generic.package_kind == "unspecified")
print("Atualizador cumulativo: 0.0.10/11/12 -> completo; 0.0.13 -> incremental; fallback e bloqueio OK")
