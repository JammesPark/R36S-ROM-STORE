-- R36S ROMS STORE Experimental: catalogo proprio e recuperacao offline.
-- Fonte propria local/remota; copia valida fica ao lado do arquivo.
local json = require("lib.json")
local U = require("lib.util")
local C = require("config")
local Own = {}
local MAX_ZLIB = 4 * 1024 * 1024
local MAX_JSON = 16 * 1024 * 1024
Own.path = C.APP_DIR .. "/catalogo_proprio.zlib"
Own.backup_path = C.APP_DIR .. "/catalogo_proprio_ultimo_valido.zlib"

local function valid(data)
  if type(data) ~= "table" or data.catalog_id ~= "r36s_own"
      or type(data.categories) ~= "table" or type(data.ports) ~= "table"
      or #data.categories < 1 or #data.categories > 100
      or #data.ports < 1 or #data.ports > 50000 then
    return false, "Estrutura do catalogo proprio invalida"
  end
  local systems = {}
  for _, cat in ipairs(data.categories) do
    if type(cat) ~= "table" or type(cat.id) ~= "string"
        or not cat.id:match("^[%w%-]+$") or systems[cat.id] then
      return false, "Sistema invalido ou duplicado no catalogo"
    end
    systems[cat.id] = true
  end
  local ids, urls = {}, {}
  for _, g in ipairs(data.ports) do
    if type(g) ~= "table" or type(g.id) ~= "string" or #g.id > 128
        or ids[g.id] or type(g.name) ~= "string" or #g.name > 240
        or g.name == "" or g.section ~= "games"
        or not systems[g.system_id] or g.category ~= g.system_id
        or type(g.download_url) ~= "string" or #g.download_url > 2048
        or not g.download_url:match("^https?://[%w%.%-]+/")
        or g.download_url:find("[%c%s]") or g.download_url:find("@", 1, true)
        or urls[g.download_url] then
      return false, "Registro de ROM invalido, duplicado ou com URL insegura"
    end
    ids[g.id] = true
    urls[g.download_url] = true
  end
  return true
end

local function decode(bytes)
  if type(bytes) ~= "string" or #bytes < 100 or #bytes > MAX_ZLIB then
    return nil, "Tamanho invalido do catalogo compactado"
  end
  local ok, plain = pcall(love.data.decompress, "string", "zlib", bytes)
  if not ok or type(plain) ~= "string" or #plain > MAX_JSON then
    return nil, "Falha na descompactacao do catalogo"
  end
  local decoded, data = pcall(json.decode, plain)
  if not decoded then return nil, "JSON do catalogo invalido" end
  local good, err = valid(data)
  if not good then return nil, err end
  return data
end

local function save_atomic(path, bytes)
  if type(bytes) ~= "string" then return false end
  local tmp = path .. ".tmp"
  if not U.write_file(tmp, bytes) then return false end
  if U.read_file(tmp) ~= bytes then os.remove(tmp); return false end
  local ok = os.rename(tmp, path)
  if not ok then os.remove(tmp) end
  return ok and true or false
end

-- A rede nunca pode substituir o catalogo por uma amostra incompleta.
-- Os limites minimos correspondem a primeira colecao experimental aprovada.
function Own.decode_remote(bytes)
  local data, err = decode(bytes)
  if not data then return nil, err end
  if #data.categories < 50 or #data.ports < 15652 then
    return nil, "Catalogo remoto incompleto (minimo: 50 sistemas e 15652 registros)"
  end
  for _, g in ipairs(data.ports) do
    local cover = g.cover
    if cover ~= nil and cover ~= "" then
      if type(cover) ~= "string" or #cover > 512 or cover:find("..", 1, true)
          or not cover:match("^https://r36s%-roms%-covers%.james%-spanico%.workers%.dev/covers/[a-z0-9_%-]+/[a-z0-9_%.%-]+%.jpg$") then
        return nil, "URL de capa remota invalida"
      end
      local sys = cover:match("/covers/([^/]+)/")
      -- O catalogo preserva os IDs originais; as pastas de midia usam aliases do ES.
      local aliases = {fbneo = "fba", neocd = "neogeocd", sgfx = "supergrafx",
        wonderswancol = "wonderswancolor"}
      if sys ~= g.system_id and sys ~= aliases[g.system_id] then
        return nil, "Capa de outro sistema"
      end
    end
  end
  return data
end

-- So chamar apos decode_remote e normalizacao integral pelo Catalog.
-- O principal so muda apos gravacao e verificacao da copia temporaria.
function Own.commit_remote(bytes)
  if not save_atomic(Own.path, bytes) then return false end
  if not save_atomic(Own.backup_path, bytes) then
    U.log("catalogo proprio: backup anterior preservado; falha ao gravar novo backup")
  end
  return true
end

-- So chamar depois que o parser normalizado aprovou todos os registros.
function Own.remember(bytes)
  -- Na abertura normal nao descompactar 12 mil registros uma segunda vez.
  if U.read_file(Own.backup_path) == bytes then return true end
  if not decode(bytes) then return false end
  return save_atomic(Own.backup_path, bytes)
end

function Own.restore(bytes)
  if not decode(bytes) then return false end
  return save_atomic(Own.path, bytes)
end

function Own.read()
  local bytes = U.read_file(Own.path)
  local primary_err = "Arquivo principal ausente"
  if bytes then
    local data, err = decode(bytes)
    if data then return data, "own-local", bytes end
    primary_err = "Arquivo principal invalido: " .. tostring(err)
  end

  -- A ultima versao aprovada tem prioridade sobre qualquer amostra embutida.
  local backup = U.read_file(Own.backup_path)
  if backup then
    local data = decode(backup)
    if data then return data, "own-backup", backup end
  end

  -- Opcional: edicoes futuras podem embutir o proprio catalogo no game.love.
  local ok, bundled = pcall(love.filesystem.read, "catalog/catalogo_proprio.zlib")
  if ok and type(bundled) == "string" then
    local data = decode(bundled)
    if data then return data, "own-embedded", bundled end
  end
  return nil, primary_err .. "; nenhuma copia valida encontrada"
end

return Own
