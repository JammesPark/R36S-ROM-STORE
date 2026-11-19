-- =============================================================================
--  Registro dos ports instalados pelo hub (installed.json no diretorio de dados)
--  Tambem detecta ports instalados por fora (PortMaster/KMP/manual) pelo nome
--  do script .sh, do mesmo jeito que o KMP faz.
-- =============================================================================
local L = require("lib.i18n").L
local json = require("lib.json")
local U = require("lib.util")
local C = require("config")
local Scan = require("core.scan")

local M = { data = {}, cache = {} }
local FILE = "installed.json"

function M.load()
  local ok, text = pcall(love.filesystem.read, FILE)
  if ok and text then
    local d = json.decode(text)
    if type(d) == "table" then M.data = d end
  end
  M.cache = {}
end

function M.save()
  pcall(love.filesystem.write, FILE, json.encode(M.data, true))
end

-- O registro guarda o cartao escolhido (versoes antigas sem esse campo
-- continuam usando a pasta de ports ativa).
local function record_dir(rec)
  local dir = type(rec) == "table" and rec.ports_dir or nil
  if dir == "/roms/ports" or dir == "/roms2/ports" then return dir end
  return C.PORTS_DIR
end

function M.record(p, entries, ports_dir)
  M.data[p.id] = {
    name = p.name,
    version = p.version,
    entries = entries,
    ports_dir = ports_dir or C.PORTS_DIR,
    date = os.date("%Y-%m-%d %H:%M"),
  }
  M.save()
  M.cache[p.id] = nil
end

--- Situacao do port no console: "none" | "installed" | "update"
--- Usa o registro do hub e, se nao houver, a varredura de /roms/ports
--- (reconhece ports instalados pelo PortMaster, KMP ou copia manual).
function M.status(p)
  if p.is_local then
    M.cache[p.id] = M.cache[p.id] or { st = "installed", found = p.local_items, by = "console" }
    return "installed"
  end
  local c = M.cache[p.id]
  if c then return c.st end
  local st, found, by = "none", nil, nil
  local rec = M.data[p.id]
  if rec and type(rec.entries) == "table" then
    local f = {}
    local dir = record_dir(rec)
    for _, e in ipairs(rec.entries) do
      if type(e) == "string" and not e:find("/", 1, true) and not e:find("..", 1, true)
          and U.exists(dir .. "/" .. e) then f[#f + 1] = e end
    end
    if #f > 0 then
      st, found, by = "installed", f, "hub"
      if p.version ~= "" and rec.version and rec.version ~= "" and rec.version ~= p.version then st = "update" end
    end
  end
  if st == "none" and M.storage_scans then
    local cards = M.location_cards(p)
    local active = C.PORTS_DIR == "/roms2/ports" and "sd2" or "sd1"
    local chosen = cards[active] and active or (cards.sd1 and "sd1" or (cards.sd2 and "sd2" or nil))
    if chosen then
      found = Scan.find_in_snapshot(p, M.storage_scans[chosen])
      if not found then
        local recdir = chosen == "sd1" and "/roms/ports" or "/roms2/ports"
        local r = M.data[p.id]
        if r and record_dir(r) == recdir then
          found = {}
          for _, name in ipairs(r.entries or {}) do
            if type(name) == "string" and not name:find("/", 1, true) and U.exists(recdir .. "/" .. name) then
              found[#found + 1] = name
            end
          end
        end
      end
      st, by = "installed", "console"
    end
  end
  if st == "none" then
    local ver
    found, ver = Scan.find(p)
    if found then
      st, by = "installed", "console"
      -- so marca atualizacao quando a versao instalada e conhecida
      if ver and ver ~= "" and p.version ~= "" and ver ~= p.version then st = "update" end
      M.console_versions = M.console_versions or {}
      M.console_versions[p.id] = ver
    end
  end
  M.cache[p.id] = { st = st, found = found, by = by }
  return st
end

-- Consulta pontual: confere o port no SD1 ou SD2 isoladamente, antes de
-- iniciar o download. Detecta tanto registros do Hub quanto instalacoes
-- manuais/PortMaster/KMP identificaveis pelos scripts ou metadados.
-- Devolve itens, versao e origem, ou nil quando nao ha evidencia suficiente.
function M.on_card(p, dir)
  if dir ~= "/roms/ports" and dir ~= "/roms2/ports" then return nil end
  if not U.is_dir(dir) then return nil end
  local rec = M.data[p.id]
  if rec and record_dir(rec) == dir and type(rec.entries) == "table" then
    local found = {}
    for _, e in ipairs(rec.entries) do
      if type(e) == "string" and e ~= "" and not e:find("/", 1, true)
          and not e:find("..", 1, true) and U.exists(dir .. "/" .. e) then
        found[#found + 1] = e
      end
    end
    if #found > 0 then return found, rec.version, "hub" end
  end
  local found, version = Scan.find_in_dir(p, dir)
  if found and #found > 0 then return found, version, "console" end
  return nil
end

-- Inventarios lidos de cada cartão ao abrir/retornar a Meus Ports.
-- Não depende exclusivamente do installed.json: detecta também scripts
-- registrados pelo PortMaster e cópias manuais reconhecíveis.
function M.refresh_locations()
  local Storage = require("core.portstorage")
  local scans = {}
  for _, card in ipairs({ "sd1", "sd2" }) do
    local d = Storage.get(card)
    if d and d.readable then scans[card] = Scan.snapshot(d.path) end
  end
  M.storage_scans = scans
  M.location_cache = {}
  M.cache = {}
end

function M.location_cards(p)
  if p.is_local then return p.local_cards or {} end
  if not M.storage_scans then return {} end
  M.location_cache = M.location_cache or {}
  if M.location_cache[p.id] then return M.location_cache[p.id] end
  local cards = {}
  local rec = M.data[p.id]
  for _, card in ipairs({ "sd1", "sd2" }) do
    local snap = M.storage_scans[card]
    local dir = card == "sd1" and "/roms/ports" or "/roms2/ports"
    if snap then
      local found = Scan.find_in_snapshot(p, snap)
      if found and #found > 0 then cards[card] = true end
      if not cards[card] and rec and record_dir(rec) == dir and type(rec.entries) == "table" then
        for _, name in ipairs(rec.entries) do
          if type(name) == "string" and name ~= "" and not name:find("/", 1, true)
              and not name:find("..", 1, true) and U.exists(dir .. "/" .. name) then
            cards[card] = true; break
          end
        end
      end
    end
  end
  M.location_cache[p.id] = cards
  return cards
end

function M.location_label(p)
  local cards = M.location_cards(p)
  if cards.sd1 and cards.sd2 then return "SD1 + SD2" end
  if cards.sd1 then return "SD1" end
  if cards.sd2 then return "SD2" end
  return nil
end

--- Pasta de ports em que o hub instalou este jogo; sem registro, pasta ativa.
function M.installed_dir(p)
  if p.is_local and p.local_cards then
    if p.local_cards.sd1 then return "/roms/ports" end
    if p.local_cards.sd2 then return "/roms2/ports" end
  end
  local rec = M.data[p.id]
  if rec then
    local dir = record_dir(rec)
    if not M.storage_scans then return dir end
    local cards = M.location_cards(p)
    local card = dir == "/roms2/ports" and "sd2" or "sd1"
    if cards[card] then return dir end
    -- Um registro antigo pode apontar para um cartão já removido.
  end
  if M.storage_scans then
    local cards = M.location_cards(p)
    if cards.sd1 and C.PORTS_DIR == "/roms/ports" then return "/roms/ports" end
    if cards.sd2 and C.PORTS_DIR == "/roms2/ports" then return "/roms2/ports" end
    if cards.sd1 then return "/roms/ports" end
    if cards.sd2 then return "/roms2/ports" end
  end
  return C.PORTS_DIR
end

--- Itens encontrados no console para este port (lista de nomes) e a origem
function M.found(p)
  M.status(p)
  local c = M.cache[p.id]
  return c and c.found, c and c.by
end

function M.installed_version(p)
  local rec = M.data[p.id]
  if rec and rec.version and rec.version ~= "" then return rec.version end
  return M.console_versions and M.console_versions[p.id] or nil
end

--- Ports do cartao que NAO correspondem a nenhum port do catalogo
--- (instalados pelo PortMaster, KMP ou manualmente). Viram itens "locais".
function M.local_ports(catalog_ports)
  -- Meus Ports: une os scripts de SD1 e SD2 sem duplicar o mesmo
  -- port, mas guarda a localização de cada cópia separadamente.
  if M.storage_scans then
    local used = { sd1 = {}, sd2 = {} }
    for _, p in ipairs(catalog_ports) do
      for _, card in ipairs({ "sd1", "sd2" }) do
        local items = Scan.find_in_snapshot(p, M.storage_scans[card])
        for _, name in ipairs(items or {}) do
          if name:lower():match("%.sh$") then used[card][name:lower()] = true end
          local snap = M.storage_scans[card]
          for _, lp in ipairs(snap and snap.ports or {}) do
            if lp.dir == name or lp.script == name then
              used[card][lp.script:lower()] = true
            end
          end
        end
      end
    end
    local grouped, order = {}, {}
    for _, card in ipairs({ "sd1", "sd2" }) do
      local snap = M.storage_scans[card]
      for _, lp in ipairs(snap and snap.ports or {}) do
        if not used[card][lp.script:lower()] then
          local key = lp.script:lower()
          local group = grouped[key]
          if not group then
            group = { source = lp, cards = {} }
            grouped[key] = group
            order[#order + 1] = key
          end
          group.cards[card] = true
        end
      end
    end
    local result = {}
    for _, key in ipairs(order) do
      local group = grouped[key]
      local lp = group.source
      local desc = L("Port encontrado no cartão SD, instalado fora da loja (") .. lp.source .. ").\n\n"
        .. L("Script: ") .. lp.script .. (lp.dir and (L("\nPasta: ") .. lp.dir) or "")
        .. L("\n\nEle não está no catálogo da loja, por isso não pode ser baixado ou atualizado por aqui.")
      result[#result + 1] = {
        id = "local:" .. lp.script,
        slug = U.slug("local_" .. lp.script),
        is_local = true, local_cards = group.cards,
        name = lp.title,
        short = L("Instalado no console • ") .. lp.source,
        description = desc,
        category = L("No console"),
        category_id = "_local", section = "games",
        version = lp.version or "", size_label = "—",
        download_url = "", cover = lp.cover or "", author = "", notes = "",
        install_check = {}, local_items = lp.items,
      }
    end
    return result
  end

  local used = {}
  for _, p in ipairs(catalog_ports) do
    if M.status(p) ~= "none" then
      local f = M.found(p)
      for _, n in ipairs(f or {}) do used[n] = true end
    end
  end
  local out = {}
  for _, lp in ipairs(Scan.ports) do
    if not used[lp.script] then
      local desc = L("Port encontrado no cartão SD, instalado fora da loja (") .. lp.source .. ").\n\n"
        .. L("Script: ") .. lp.script .. (lp.dir and (L("\nPasta: ") .. lp.dir) or "")
        .. L("\n\nEle não está no catálogo da loja, por isso não pode ser baixado ou atualizado por aqui.")
      out[#out + 1] = {
        id = "local:" .. lp.script,
        slug = U.slug("local_" .. lp.script),
        is_local = true,
        name = lp.title,
        short = L("Instalado no console • ") .. lp.source,
        description = desc,
        category = L("No console"),
        category_id = "_local",
        version = lp.version or "",
        size_label = "—",
        download_url = "",
        cover = lp.cover or "",
        author = "", notes = "",
        install_check = {}, local_items = lp.items,
      }
    end
  end
  return out
end

function M.invalidate() M.cache = {}; M.storage_scans = nil; M.location_cache = {} end

--- Reexamina a pasta de ports (depois de instalar, ao voltar para a loja etc.)
function M.rescan(force)
  local before = Scan.time
  Scan.refresh(force)
  if Scan.time ~= before then M.cache = {} end
end

return M
