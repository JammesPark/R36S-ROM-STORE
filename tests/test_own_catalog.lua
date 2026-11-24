-- Testes sem rede e sem janela LÖVE: leitura, validacao e recuperacao offline.
local raw = string.rep("Z", 128)
local unpacked = "catalogo_teste"
local decoded = {
  catalog_id = "r36s_own",
  categories = { {id = "gb", name = "Game Boy"} },
  ports = { {id = "own-gb-aabbcc", name = "Tetris", section = "games",
    category = "gb", system_id = "gb",
    download_url = "https://example.org/download/tetris.gb", cover = ""} },
}
local app = "/roms/ports/r36sromsstore"
local main_path = app .. "/catalogo_proprio.zlib"
local backup_path = app .. "/catalogo_proprio_ultimo_valido.zlib"
local disk = { [main_path] = raw }
package.loaded["config"] = { APP_DIR = app }
package.loaded["lib.util"] = {
  read_file = function(p) return disk[p] end,
  write_file = function(p, data) disk[p] = data; return true end,
}
package.loaded["lib.json"] = { decode = function(plain)
  assert(plain == "catalogo_teste", "JSON inesperado")
  return decoded
end }
love = { filesystem = { read = function() return nil end }, data = {
  decompress = function(kind, codec, blob)
    assert(kind == "string" and codec == "zlib" and blob == raw)
    return unpacked
  end,
} }
local original_rename, original_remove = os.rename, os.remove
os.rename = function(src, dst)
  if disk[src] == nil then return nil, "sem arquivo" end
  disk[dst], disk[src] = disk[src], nil
  return true
end
os.remove = function(path) disk[path] = nil; return true end
local Own = dofile("game/core/own_source.lua")
local data, source, bytes = Own.read()
assert(data == decoded and source == "own-local" and bytes == raw)
assert(Own.remember(bytes), "backup valido deve ser gravado")
assert(disk[backup_path] == raw)

-- Se o principal corromper, carregamos a ultima copia valida e restauramos.
disk[main_path] = "invalido"
local recovered, where, last = Own.read()
assert(recovered == decoded and where == "own-backup" and last == raw)
assert(Own.restore(last) and disk[main_path] == raw)

-- Backup ausente: rejeitar registros e fontes inseguras sem recorrer a outra API.
disk[backup_path] = nil
decoded = { catalog_id = "r36s_own", categories = { {id = "gb", name = "GB"} },
  ports = {
    {id = "duplicado", name = "A", section = "games", category = "gb",
      system_id = "gb", download_url = "https://example.org/a.gb"},
    {id = "duplicado", name = "B", section = "games", category = "gb",
      system_id = "gb", download_url = "https://example.org/b.gb"},
  }
}
assert(Own.read() == nil, "IDs duplicados devem ser rejeitados")
decoded.ports[2].id = "unico"
decoded.ports[1].download_url = "javascript:alert(1)"
assert(Own.read() == nil, "URL nao HTTP(S) deve ser rejeitada")
decoded.ports[1].download_url = "https://example.org/a.gb"
unpacked = string.rep("a", 16 * 1024 * 1024 + 1)
assert(Own.read() == nil, "JSON descompactado excessivo deve ser rejeitado")
unpacked = "catalogo_teste"

disk[main_path] = nil
local absent, why = Own.read()
assert(not absent and why:find("nenhuma copia valida"), "ausencia sem backup deve informar erro")
assert(disk[main_path] == nil, "nao recriar catalogo ficticio")
-- A atualizacao online rejeita amostras, mesmo se a estrutura local for valida.
local systems, ports = {}, {}
for i = 1, 50 do systems[i] = {id = "sys" .. i, name = "Sistema " .. i} end
for i = 1, 15652 do
  local sys = systems[(i - 1) % 50 + 1].id
  ports[i] = {id = "rom-" .. i, name = "Jogo " .. i, section = "games",
    category = sys, system_id = sys, download_url = "https://example.org/" .. i,
    cover = ""}
end
decoded = {catalog_id = "r36s_own", categories = systems, ports = ports}
assert(Own.decode_remote(raw) == decoded, "catalogo completo deve ser aceito")
ports[1].cover = "https://r36s-roms-covers.james-spanico.workers.dev/covers/sys1/test.jpg"
assert(Own.decode_remote(raw) == decoded, "capa do Worker deve ser aceita")
ports[1].cover = "https://example.org/test.jpg"
assert(Own.decode_remote(raw) == nil, "host de capa nao autorizado deve falhar")
ports[1].cover = "https://r36s-roms-covers.james-spanico.workers.dev/covers/sys2/test.jpg"
assert(Own.decode_remote(raw) == nil, "capa de outro sistema deve falhar")
ports[1].cover = ""
local last_port = table.remove(ports)
assert(Own.decode_remote(raw) == nil, "catalogo remoto parcial deve falhar")
ports[#ports+1] = last_port
assert(Own.commit_remote(raw), "copia validada deve ser gravada")
assert(disk[main_path] == raw and disk[backup_path] == raw)
local rename_before = os.rename
os.rename = function(src, dst) if dst == main_path then return nil, "falha simulada" end return rename_before(src, dst) end
assert(not Own.commit_remote(string.rep("X", 128)), "falha de gravacao deve ser informada")
assert(disk[main_path] == raw and disk[backup_path] == raw, "falha nao apaga copias validas")
os.rename = rename_before
print("OWN REMOTE: OK - integridade, limites, origem das capas e falha de gravacao")
os.rename, os.remove = original_rename, original_remove
print("OWN CATALOG: OK - validacao, backup, recuperacao e ausencia sem API")
