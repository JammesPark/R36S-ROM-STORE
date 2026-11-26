-- Testes do atualizador: saltos cumulativos e confirmacao do boot.
package.path = "src/?.lua;src/?/init.lua;" .. package.path
package.loaded["lib.i18n"] = { L = function(x) return x end }
package.loaded["config"] = {
  VERSION_NUM = "0.0.30-beta", VERSION = "0.0.30-beta",
  APP_DIR = "/fake/roms/ports/r36sromsstore",
}
local mock_manifest = {
  format = 1, name = "R36S ROM STORE", type = "full",
  version = "0.0.30-beta",
  files = {
    { path = "r36sromsstore/game.love", size = 42, sha256 = string.rep("a",64) },
    { path = "R36S ROM STORE.sh", size = 3, sha256 = string.rep("b",64) },
  }
}
package.loaded["lib.json"] = { decode = function() return mock_manifest end }
local events = {}
package.loaded["lib.util"] = {
  read_file = function() return nil end,
  log = function(...) table.insert(events, "log") end,
}
package.loaded["core.updater.formats"] = {}
local journal, cleared = nil, false
package.loaded["core.updater.backup"] = {
  journal_read = function() return journal end,
  journal_clear = function() cleared = true; journal = nil end,
}
package.loaded["core.updater.history"] = {}
package.loaded["core.updater.folder"] = { ensure_dir = function() end }
love = { filesystem = {
  read = function() return nil end,
  remove = function() return true end,
}}
local R = require("core.updater.rules")
assert(R.valid_version("0.0.30"))
assert(R.valid_version("0.0.30-beta"))
assert(not R.valid_version("0.0.30-evil"))
local manifest, err = R.parse_manifest("{}")
assert(manifest, tostring(err))
for _, old in ipairs({
  "0.0.4-beta","0.0.7-beta","0.0.10-beta","0.0.21-beta",
  "0.0.27-beta","0.0.28-beta","0.0.29-beta",
}) do
  assert(R.compare("0.0.30", old) > 0, old)
  assert(R.compat(manifest, old), "FULL deve aceitar salto: "..old)
end
assert(R.IGNORED_ROOT["README.md"] and R.IGNORED_ROOT["NOTICE.md"])
assert(R.IGNORED_ROOT["LICENSE"] and R.IGNORED_ROOT["CHANGELOG.md"])
-- O pacote enviado usa a versao numerica. O jogo usa o sufixo -beta.
local Manager = require("core.updater.manager")
for _, target in ipairs({"0.0.30", "0.0.30-beta"}) do
  cleared = false
  journal = {state="booting",to=target}
  local notice = Manager.on_boot()
  assert(cleared and journal == nil, "versao entregue deve ser confirmada: "..target)
end
-- Nao confirmar nem descartar um diario de outra versao.
cleared = false
journal = {state="booting",to="0.0.31"}
local notice = Manager.on_boot()
assert(not cleared and journal and notice and notice[2]=="warn")
print("Saltos 0.0.4 ate 0.0.29 e confirmacao 0.0.30(-beta): OK")
