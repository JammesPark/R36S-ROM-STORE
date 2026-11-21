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
os.rename, os.remove = original_rename, original_remove
print("OWN CATALOG: OK - validacao, backup, recuperacao e ausencia sem API")
