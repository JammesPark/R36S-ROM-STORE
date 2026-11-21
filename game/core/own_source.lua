-- Catalogo proprio opcional, independente da API GameStoreBR.
-- O arquivo e instalado separadamente em <pasta da loja>/catalogo_proprio.zlib.
local json=require("lib.json")
local U=require("lib.util")
local C=require("config")
local Own={}
local MAX_ZLIB=4*1024*1024
local MAX_JSON=16*1024*1024 -- permite metadados de capa e sinopses verificadas
local FILE="catalogo_proprio.zlib"
Own.path=C.APP_DIR.."/"..FILE

local function valid(data)
  if type(data)~="table" or data.catalog_id~="r36s_own"
      or type(data.categories)~="table" or type(data.ports)~="table"
      or #data.categories<1 or #data.categories>100
      or #data.ports<1 or #data.ports>50000 then
    return false,"Estrutura do catalogo proprio invalida"
  end
  local systems={}
  for _,cat in ipairs(data.categories) do
    if type(cat)~="table" or type(cat.id)~="string"
        or not cat.id:match("^[%w%-]+$") or systems[cat.id] then
      return false,"Sistema invalido no catalogo"
    end
    systems[cat.id]=true
  end
  local ids,urls={},{}
  for _,g in ipairs(data.ports) do
    if type(g)~="table" or type(g.id)~="string" or #g.id>128
        or ids[g.id] or type(g.name)~="string" or #g.name>240
        or g.name=="" or g.section~="games"
        or not systems[g.system_id] or g.category~=g.system_id
        or type(g.download_url)~="string" or #g.download_url>2048
        or not g.download_url:match("^https?://[%w%.%-]+/")
        or g.download_url:find("[%c%s]") or g.download_url:find("@",1,true)
        or urls[g.download_url] then
      return false,"Registro de ROM invalido"
    end
    ids[g.id]=true
    urls[g.download_url]=true
  end
  return true
end

function Own.read()
  local bytes=U.read_file(Own.path)
  local origin="own-local"
  if not bytes then
    local ok,b=pcall(love.filesystem.read,"catalog/catalogo_proprio.zlib")
    if ok then bytes=b;origin="own-embedded" end
  end
  if type(bytes)~="string" then
    return nil,"Arquivo ausente: "..Own.path
  end
  if #bytes<100 or #bytes>MAX_ZLIB then
    return nil,"Tamanho invalido de catalogo compactado"
  end
  local ok,plain=pcall(love.data.decompress,"string","zlib",bytes)
  if not ok or type(plain)~="string" or #plain>MAX_JSON then
    return nil,"Falha na descompactacao do catalogo proprio"
  end
  local decoded,table_or_error=pcall(json.decode,plain)
  if not decoded then return nil,"JSON do catalogo invalido" end
  local data=table_or_error
  local correct,err=valid(data)
  if not correct then return nil,err end
  return data,origin
end

return Own
