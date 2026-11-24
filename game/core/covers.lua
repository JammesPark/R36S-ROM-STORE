-- =============================================================================
--  Capas: download sob demanda, cache em disco e poucas imagens na memoria
-- =============================================================================
local C = require("config")
local U = require("lib.util")
local Fetcher = require("core.fetcher")

local Covers = { mem = {}, order = {}, state = {}, retry_at = {}, failures = {}, dir = "covers" }
local function failed(key, reason)
  local n = math.min(4, (Covers.failures[key] or 0) + 1)
  Covers.failures[key] = n
  Covers.retry_at[key] = love.timer.getTime() + 10 * 2 ^ (n - 1)
  Covers.state[key] = "failed"
  U.log("capa: tentativa falhou", key, tostring(reason))
end
local function ready(key)
  Covers.retry_at[key], Covers.failures[key] = nil, nil
end

function Covers.init()
  love.filesystem.createDirectory(Covers.dir)
  Covers.abs_dir = love.filesystem.getSaveDirectory() .. "/" .. Covers.dir
end

local function hash(s)
  local h = 5381
  for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
  return string.format("%08x", h)
end

local function file_name(p) return p.slug .. "_" .. hash(p.cover) .. ".img" end
local function file_for(p) return Covers.dir .. "/" .. file_name(p) end

local function touch(key)
  for i, k in ipairs(Covers.order) do
    if k == key then table.remove(Covers.order, i); break end
  end
  table.insert(Covers.order, key)
  while #Covers.order > C.COVER_CACHE_MAX do
    local old = table.remove(Covers.order, 1)
    local img = Covers.mem[old]
    if img and img.release then img:release() end
    Covers.mem[old] = nil
    if Covers.state[old] == "ready" then Covers.state[old] = "disk" end
  end
end

local function load_image(key, path_in_save, abs)
  local ok, img = pcall(function()
    if abs then
      local data = U.read_file(abs)
      if not data then error("sem arquivo") end
      local fd = love.filesystem.newFileData(data, "cover")
      return love.graphics.newImage(love.image.newImageData(fd))
    end
    return love.graphics.newImage(path_in_save)
  end)
  if ok and img then
    img:setFilter("linear", "linear")
    Covers.mem[key] = img
    Covers.state[key] = "ready"
    ready(key)
    touch(key)
    return img
  end
  U.log("capa invalida:", key, tostring(img))
  failed(key, "imagem invalida")
  return nil
end

--- Devolve a imagem (ou nil enquanto carrega/sem capa). Nunca bloqueia na rede.
function Covers.get(p)
  if not p or type(p.cover) ~= "string" or p.cover == "" then return nil end
  -- A imagem em memoria tambem depende da URL; atualizacoes de capa nao ficam presas ao slug.
  local key = file_name(p)
  local img = Covers.mem[key]
  if img then touch(key); return img end
  local st = Covers.state[key]
  if st == "loading" then return nil end
  if st == "failed" and love.timer.getTime() < (Covers.retry_at[key] or 0) then return nil end

  -- capa local (caminho relativo a pasta do app)
  if not p.cover:match("^https?://") then
    local abs = p.cover:sub(1, 1) == "/" and p.cover or (C.APP_DIR .. "/" .. p.cover)
    if p.cover:sub(1, 1) ~= "/" and love.filesystem.getInfo(p.cover) then return load_image(key, p.cover) end
    if U.read_file(abs) then return load_image(key, nil, abs) end
    failed(key, "arquivo local ausente")
    return nil
  end

  local f = file_for(p)
  if love.filesystem.getInfo(f) then
    local cached = load_image(key, f)
    if cached then return cached end
    love.filesystem.remove(f)
    return nil
  end

  Covers.state[key] = "loading"
  Fetcher.get("cover", p.cover, Covers.abs_dir .. "/" .. file_name(p), function(ok, _, reason)
    if ok then
      Covers.state[key] = "disk"
      ready(key)
    elseif reason == "cancelado" then
      Covers.state[key] = nil
    else
      failed(key, reason)
    end
  end)
  return nil
end

--- caminho absoluto da capa ja baixada (ou nil)
function Covers.disk_file(p)
  if not p or not p.cover or p.cover == "" then return nil end
  if not p.cover:match("^https?://") then
    local abs = p.cover:sub(1, 1) == "/" and p.cover or (C.APP_DIR .. "/" .. p.cover)
    return U.file_size(abs) and abs or nil
  end
  if love.filesystem.getInfo(file_for(p)) then return Covers.abs_dir .. "/" .. file_name(p) end
  return nil
end

--- garante a capa em disco e chama cb(caminho ou nil)
function Covers.fetch_file(p, cb)
  local f = Covers.disk_file(p)
  if f or not p or not p.cover or not p.cover:match("^https?://") then cb(f); return end
  Fetcher.get("cover", p.cover, Covers.abs_dir .. "/" .. file_name(p), function(ok)
    if ok then Covers.state[file_name(p)] = "disk" end
    cb(ok and Covers.disk_file(p) or nil)
  end)
end

function Covers.is_loading(p)
  return p and p.cover and Covers.state[file_name(p)] == "loading"
end

--- Ao trocar de catalogo/tela: libera pedidos pendentes
function Covers.reset_pending()
  Covers.focus_owner, Covers.focus_token = nil, nil
  Fetcher.drop_covers()
  -- Os callbacks dos pedidos cancelados limpam o estado; manter o download ativo.
end

-- A fila de tela deve seguir a posicao atual, nao as paginas ja abandonadas.
-- Preserva o download em andamento e o cache; cancela apenas pedidos visuais na fila.
function Covers.focus_view(owner, token, selected)
  if Covers.focus_owner == owner and Covers.focus_token == token then return false end
  Fetcher.drop_covers()
  Covers.focus_owner, Covers.focus_token = owner, token
  if selected and not selected.builtin then Covers.get(selected) end
  return true
end

--- Apaga as capas baixadas (serao baixadas de novo quando aparecerem)
function Covers.clear_disk()
  for _, f in ipairs(love.filesystem.getDirectoryItems(Covers.dir)) do
    love.filesystem.remove(Covers.dir .. "/" .. f)
  end
  for k, img in pairs(Covers.mem) do if img.release then img:release() end end
  Covers.mem, Covers.order, Covers.state, Covers.retry_at, Covers.failures = {}, {}, {}, {}, {}
end

-- ---------------------------------------------------------------------------
-- Baixar todas as capas do catalogo (Configuracoes > Armazenamento)
-- Uma capa por vez, na mesma fila das capas da tela (tipo proprio, para que a
-- troca de tela nao cancele o lote). So capas da internet que ainda nao estao
-- no console. Cancelar: termina a capa em andamento e para.
Covers.bulk = nil

--- ports do catalogo com capa da internet que ainda nao foi baixada
function Covers.missing(ports)
  local list = {}
  for _, p in ipairs(ports or {}) do
    if p.cover and p.cover:match("^https?://") and not Covers.disk_file(p) then list[#list + 1] = p end
  end
  return list
end

--- inicia o lote. on_done(job) ao terminar ou cancelar
function Covers.bulk_start(ports, on_done)
  if Covers.bulk then return false end
  local list = Covers.missing(ports)
  local job = { list = list, total = #list, i = 0, ok = 0, failed = 0, cancel = false, on_done = on_done }
  Covers.bulk = job
  local function step()
    if job.cancel or job.i >= job.total then
      Covers.bulk = nil
      job.finished = true
      U.log("capas: lote terminado", job.ok, "ok,", job.failed, "falhas de", job.total, job.cancel and "(cancelado)" or "")
      if job.on_done then pcall(job.on_done, job) end
      return
    end
    job.i = job.i + 1
    local p = job.list[job.i]
    job.cur = p
    if Covers.disk_file(p) then job.ok = job.ok + 1; return step() end
    Fetcher.get("cover_all", p.cover, Covers.abs_dir .. "/" .. file_name(p), function(ok)
      if ok then
        job.ok = job.ok + 1
        if Covers.state[file_name(p)] ~= "ready" then Covers.state[file_name(p)] = "disk" end
      else
        job.failed = job.failed + 1
      end
      step()
    end)
  end
  step()
  return true
end

function Covers.bulk_cancel()
  if Covers.bulk then Covers.bulk.cancel = true end
end

--- Tentar de novo capas que falharam (ex.: depois de reconectar)
function Covers.retry_failed()
  for k, v in pairs(Covers.state) do
    if v == "failed" then Covers.state[k], Covers.retry_at[k], Covers.failures[k] = nil, nil, nil end
  end
end

return Covers
