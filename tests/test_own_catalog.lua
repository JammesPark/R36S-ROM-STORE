-- Regressao do leitor de catalogo proprio (sem rede ou LÖVE fisico).
local raw=string.rep("Z",128)
local decoded={
  catalog_id="r36s_own",
  categories={{id="gb",name="Game Boy"}},
  ports={{id="own-gb-aabbcc",name="Tetris",section="games",category="gb",system_id="gb",
    download_url="https://example.org/download/tetris.gb",cover=""}},
}
local file=raw
local unpacked="catalogo_teste"
package.loaded["config"]={APP_DIR="/roms/ports/r36sromsstore"}
package.loaded["lib.util"]={read_file=function(path)
  assert(path=="/roms/ports/r36sromsstore/catalogo_proprio.zlib")
  return file
end}
package.loaded["lib.json"]={decode=function(text)
  if text~="catalogo_teste" then error("JSON corrompido") end
  return decoded
end}
love={filesystem={read=function() return nil end},
  data={decompress=function(kind,codec,bytes)
    assert(kind=="string" and codec=="zlib" and bytes==raw)
    return unpacked
  end}}
local reader=dofile("game/core/own_source.lua")
local parsed,source=reader.read()
assert(parsed==decoded and source=="own-local","arquivo proprio valido deve carregar")
local saved=decoded
decoded={catalog_id="r36s_own",categories={{id="gb",name="GB"}},
  ports={{id="duplicado",name="A",section="games",category="gb",system_id="gb",
      download_url="https://example.org/a.gb"},
    {id="duplicado",name="B",section="games",category="gb",system_id="gb",
      download_url="https://example.org/b.gb"}}}
assert(reader.read()==nil,"IDs duplicados devem ser rejeitados")
decoded=saved
decoded.ports[1].download_url="javascript:alert(1)"
assert(reader.read()==nil,"URL fora de HTTP(S) deve ser rejeitada")
decoded.ports[1].download_url="https://example.org/download/tetris.gb"
unpacked=string.rep("a",8*1024*1024+1)
assert(reader.read()==nil,"JSON descompactado excessivo deve ser rejeitado")
unpacked="catalogo_teste"
file=nil
local absent,err=reader.read()
assert(not absent and err:find("Arquivo ausente"),"sem arquivo proprio deve avisar")
print("OWN CATALOG: OK - validacao, integridade e ausencias")
