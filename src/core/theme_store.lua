-- Loja de temas DA STORE (nao EmulationStation). Somente pacotes de dados.
-- Catalogo remoto em cache; temas incluidos nunca sao substituidos.
local C = require("config")
local U = require("lib.util")
local json = require("lib.json")
local Fetcher = require("core.fetcher")
local Themes = require("core.themes")
local M = { items = {}, source = "none", state = "idle", job = nil }
local CACHE = "theme_store_catalog.json"
local MAX_SIZE = 12 * 1024 * 1024

local function decode(raw)
  local ok, value = pcall(json.decode, raw or "")
  return ok and type(value) == "table" and value or nil
end
local function parse(raw)
  local body = decode(raw)
  if not body or type(body.themes) ~= "table" then return nil end
  local items, ids = {}, {}
  for _, a in ipairs(body.themes) do
    if type(a) == "table" and type(a.id) == "string"
        and a.id:match("^[%w_%-]+$") and #a.id <= 48 and not ids[a.id]
        and type(a.name) == "string" and #a.name < 90
        and type(a.url) == "string" and a.url:match("^https://[^%s]+%.zip$")
        and type(a.sha256) == "string" and #a.sha256 == 64 and a.sha256:match("^%x+$")
        and type(a.size) == "number" and a.size >= 100 and a.size <= MAX_SIZE
        and type(a.version) == "string" and a.version:match("^%d+%.%d+%.%d+$") then
      ids[a.id] = true
      items[#items + 1] = {
        id = a.id, name = a.name, version = a.version,
        description = type(a.description) == "string" and a.description:sub(1, 250) or "",
        author = type(a.author) == "string" and a.author:sub(1, 80) or "",
        url = a.url, size = math.floor(a.size), sha256 = a.sha256:lower(),
        preview_url = type(a.preview_url) == "string" and a.preview_url:match("^https://[^%s]+%.png$")
          and a.preview_url or nil,
      }
    end
  end
  return items
end

local function load_cache()
  local ok, data = pcall(love.filesystem.read, CACHE)
  local list = ok and parse(data) or nil
  if list then M.items, M.source = list, "cache" end
end

function M.refresh(cb)
  if M.state == "loading" then return end
  load_cache()
  local url = Themes.catalog_url()
  if not url or not url:match("^https://") then
    M.state = "error"
    if cb then cb(false, "Endereço HTTPS do catálogo não configurado") end
    return
  end
  M.state = "loading"
  Fetcher.get("themes", url, C.TMP_DIR .. "/theme_store_catalog.json", function(ok, path, why)
    local raw = ok and path and U.read_file(path) or nil
    if path then os.remove(path) end
    local list = raw and parse(raw) or nil
    if list then
      M.items, M.source, M.state = list, "online", "ready"
      pcall(love.filesystem.write, CACHE, raw)
      if cb then cb(true) end
    else
      M.state = "error"
      if cb then cb(false, why or "Catálogo remoto inválido") end
    end
  end, true)
end

local function numbers(v)
  local a,b,c = tostring(v or ""):match("^(%d+)%.(%d+)%.(%d+)")
  return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end
local function newer(remote, localv)
  local a,b,c = numbers(remote)
  local x,y,z = numbers(localv)
  if a ~= x then return a > x end
  if b ~= y then return b > y end
  return c > z
end

function M.status(item)
  local th = Themes.by_id and Themes.by_id[item.id]
  if not th then return "available" end
  if th.builtin then
    return newer(item.version, th.version) and "update" or "included"
  end
  return newer(item.version, th.version) and "update" or "installed"
end

function M.install(item)
  if M.job and not M.job.finished then return false, "Outro tema está sendo baixado" end
  if not item or (M.status(item) ~= "available" and M.status(item) ~= "update") then
    return false, "Tema já incluído ou instalado"
  end
  love.filesystem.createDirectory(Themes.USER_DIR)
  local out, inn = "r36sbr_theme_out", "r36sbr_theme_in"
  love.thread.getChannel(out):clear()
  love.thread.getChannel(inn):clear()
  M.job = { id = item.id, name = item.name, phase = "download", done = 0,
    total = item.size, error = nil, finished = false, status = "running",
    out = love.thread.getChannel(out), inn = love.thread.getChannel(inn) }
  M.job.thread = love.thread.newThread("threads/theme_store_thread.lua")
  M.job.thread:start({ id=item.id, version=item.version, url=item.url,
    size=item.size, sha256=item.sha256, save_dir=love.filesystem.getSaveDirectory(),
    fetch_sh=C.FETCH_SH, out=out, inn=inn })
  return true
end

function M.cancel()
  if M.job and not M.job.finished then M.job.inn:push("cancel") end
end

function M.update()
  local j = M.job
  if not j or j.finished then return end
  local err = j.thread:getError()
  if err then j.finished, j.status, j.error = true, "error", err; return end
  local m = j.out:pop()
  while m do
    if m.t == "phase" then j.phase = m.phase
    elseif m.t == "progress" then j.done, j.total = m.done or j.done, m.total or j.total
    elseif m.t == "done" then
      j.status, j.finished = "done", true
      Themes.scan()
      if Themes.current==j.id then
        -- Recarrega fundo, cores e arquivos do tema ativo sem reiniciar o Hub.
        Themes.apply(j.id,false)
      end
      if App and App.toast then App.toast("Tema " .. j.name .. " instalado e pronto.", "ok") end
    elseif m.t == "cancelled" then j.status, j.finished = "cancelled", true
    elseif m.t == "error" then
      j.status, j.finished, j.error = "error", true, m.msg
    end
    m = j.out:pop()
  end
end

-- Nao remove temas inclusos, em uso, nem pastas com conteudo desconhecido.
local ALLOWED = { ["theme.json"]=true, ["preview.png"]=true, ["logo_header.png"]=true,
  ["logo_menu.png"]=true, ["logo_splash.png"]=true, ["logo_about.png"]=true,
  ["background_v4.png"]=true, ["selected_tiles_v4.png"]=true }
function M.remove(id)
  local th = Themes.by_id and Themes.by_id[id]
  if not th or th.builtin then return false, "Tema incluso não pode ser removido" end
  if id == Themes.current then return false, "Escolha outro tema antes de remover este" end
  if type(id) ~= "string" or not id:match("^[%w_%-]+$") then return false, "ID inválido" end
  local dir = Themes.USER_DIR .. "/" .. id
  if th.dir ~= dir then return false, "Pasta do tema não confere" end
  local names = love.filesystem.getDirectoryItems(dir)
  for _, n in ipairs(names) do
    if not ALLOWED[n] or love.filesystem.getInfo(dir .. "/" .. n, "file") == nil then
      return false, "Pasta contém arquivos desconhecidos; remoção cancelada"
    end
  end
  for _, n in ipairs(names) do
    if not love.filesystem.remove(dir .. "/" .. n) then return false, "Falha ao remover " .. n end
  end
  if not love.filesystem.remove(dir) then return false, "Pasta não pôde ser removida" end
  Themes.scan()
  return true
end

return M
