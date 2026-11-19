-- =============================================================================
--  Exclusao de um jogo instalado (Meus Ports, botao X)
--
--  Reaproveita a identificacao de ports ja existente (registro do hub + varredura
--  de /roms/ports) e so permite excluir quando os arquivos do jogo estao
--  identificados com SEGURANCA:
--    - registro do hub (o hub sabe exatamente o que instalou), ou
--    - itens declarados pelo PortMaster (port.json) ou por um arquivo .port, ou
--    - a pasta declarada no GAMEDIR= do proprio script.
--  Uma pasta reconhecida apenas pelo nome parecido NAO basta.
--  Nunca apaga: a pasta /roms/ports, PortMaster, runtimes/bibliotecas, o proprio
--  hub, pastas usadas por outro jogo ou qualquer coisa fora de /roms/ports.
-- =============================================================================
local L = require("lib.i18n").L
local C = require("config")
local U = require("lib.util")
local Scan = require("core.scan")
local Manifest = require("core.manifest")

local X = { job = nil, seq = 0 }

-- nomes que nunca sao apagados, mesmo que algum metadado os cite
local NEVER = {
  ["portmaster"] = true, ["portmaster.sh"] = true, ["r36sromsstore"] = true, ["r36s port hub.sh"] = true, ["r36sportsbr store.sh"] = true,
  ["gamelist.xml"] = true, ["images"] = true, ["videos"] = true, ["manuals"] = true,
  ["libs"] = true, ["runtimes"] = true, ["ports"] = true, ["bios"] = true, ["themes"] = true,
  ["tools"] = true, ["roms"] = true, ["roms2"] = true, ["."] = true, [".."] = true,
}

local function valid_name(n)
  return type(n) == "string" and n ~= "" and not n:find("/") and not n:find("%z") and not NEVER[n:lower()]
    and not C.PROTECTED_NAMES[n:lower()]
end

local function mounts()
  local t = {}
  local s = U.read_file("/proc/mounts") or ""
  for line in s:gmatch("[^\n]+") do
    local mp = line:match("^%S+%s+(%S+)")
    if mp then t[#t + 1] = (mp:gsub("\\040", " ")) end
  end
  return t
end

-- Cria o plano exclusivamente para o cartao escolhido, inclusive para ports
-- manuais, de PortMaster e de outros instaladores, sem depender do installed.json.
-- Nenhum alvo e apagado aqui: esta funcao e apenas leitura.
function X.plan(p, selected_dir)
  local Storage = require("core.portstorage")
  local dir = selected_dir or Manifest.installed_dir(p)
  local card = dir == "/roms/ports" and "sd1" or (dir == "/roms2/ports" and "sd2" or nil)
  if not card then return nil, L("Selecione SD1 ou SD2 para desinstalar.") end
  local sd = Storage.get(card)
  if not sd or not sd.readable then
    return nil, L("O cartao selecionado nao esta montado separadamente: ") .. card
  end
  if not U.exec_ok("test -w " .. U.shq(dir)) then
    return nil, L("Sem permissao para remover arquivos no ") .. card
  end
  local base = U.trim(U.capture("readlink -f " .. U.shq(dir) .. " 2>/dev/null") or "")
  if (base ~= "/roms/ports" and base ~= "/roms2/ports") or not U.is_dir(base) then
    return nil, L("Caminho de instalacao nao seguro. Nada foi apagado.")
  end
  local snap = Scan.snapshot(dir)
  if not snap then return nil, L("Nao foi possivel verificar os arquivos do cartao.") end

  local found, by = {}, "console"
  if p.is_local then
    -- O ID de ports locais contem o nome EXATO do .sh; nao usar a lista de
    -- itens do outro cartao para evitar excluir pastas diferentes.
    local script = type(p.id) == "string" and p.id:match("^local:(.+)$")
    if script and snap.by_script[script] then found = { script } end
  else
    found = Scan.find_in_snapshot(p, snap) or {}
  end
  local rec = Manifest.data[p.id]
  if rec and type(rec.entries) == "table" and (rec.ports_dir or C.PORTS_DIR) == dir then
    local recorded = {}
    local has_sh = false
    for _, n in ipairs(rec.entries) do
      if type(n) == "string" and snap.entries[n] then
        recorded[#recorded + 1] = n
        if n:lower():match("%.sh$") and snap.entries[n] == "file" then has_sh = true end
      end
    end
    if has_sh then found, by = recorded, "hub" end
  end
  if not found or #found == 0 then
    return nil, L("Nenhum script deste port foi localizado no ") .. card, { nothing = true }
  end
  local targets, set, scripts, evidence = {}, {}, {}, {}
  local function add(n)
    if type(n) == "string" and snap.entries[n] and not set[n] then
      set[n] = true
      targets[#targets + 1] = n
    end
  end
  for _, n in ipairs(found) do
    if type(n) == "string" and n:lower():match("%.sh$") and snap.entries[n] == "file" then
      scripts[#scripts + 1] = n
    end
  end
  if #scripts == 0 then
    return nil, L("O arquivo .sh nao foi identificado com seguranca. Nada foi apagado.")
  end
  if by == "hub" then
    for _, n in ipairs(found) do add(n) end
    evidence[#evidence + 1] = L("registro de instalacao da loja")
  end
  for _, sh in ipairs(scripts) do
    add(sh)
    local lp = snap.by_script[sh]
    if lp then
      if lp.pm_items then
        for _, n in ipairs(lp.pm_items) do add(n) end
        evidence[#evidence + 1] = "port.json PortMaster"
      elseif lp.port_items then
        for _, n in ipairs(lp.port_items) do add(n) end
        evidence[#evidence + 1] = L("arquivo .port")
      elseif lp.gamedir and snap.entries[lp.gamedir] == "dir" then
        add(lp.gamedir)
        evidence[#evidence + 1] = "GAMEDIR"
      elseif lp.refdir and snap.entries[lp.refdir] == "dir" then
        add(lp.refdir)
        evidence[#evidence + 1] = L("pasta citada no script")
      elseif lp.dir and snap.entries[lp.dir] == "dir" then
        add(lp.dir)
        evidence[#evidence + 1] = L("pasta correspondente ao .sh")
      end
    end
  end
  -- Registro e metadados podem conter nomes indevidos: validar TUDO antes
  -- de mostrar a confirmacao ou criar uma thread de remocao.
  local mts = mounts()
  for _, n in ipairs(targets) do
    if not valid_name(n) then
      return nil, L("Arquivo protegido ou inseguro: ") .. tostring(n)
    end
    local path = base .. "/" .. n
    if U.exec_ok("test -L " .. U.shq(path)) then
      return nil, L("Link simbolico nao pode ser removido por esta ferramenta: ") .. n
    end
    if snap.entries[n] == "dir" then
      for _, mp in ipairs(mts) do
        if mp == path or mp:sub(1, #path + 1) == path .. "/" then
          return nil, L("Pasta montada ou em uso: ") .. n
        end
      end
      for _, other in ipairs(snap.ports) do
        if not set[other.script] then
          local uses = other.dir == n or other.gamedir == n or other.refdir == n
          for _, it in ipairs(other.pm_items or other.port_items or {}) do
            if it == n then uses = true end
          end
          if uses then
            return nil, L("Pasta compartilhada com outro port: ") .. n
          end
        end
      end
      for id, other in pairs(Manifest.data) do
        if id ~= p.id and type(other) == "table" and (other.ports_dir or C.PORTS_DIR) == dir then
          for _, name in ipairs(other.entries or {}) do
            if name == n then return nil, L("Pasta registrada por outro port: ") .. n end
          end
        end
      end
    end
  end
  local sizes = {}
  for _, n in ipairs(targets) do
    local kb = tonumber((U.capture("timeout 4 du -sk " .. U.shq(base .. "/" .. n) .. " 2>/dev/null") or ""):match("^(%d+)"))
    sizes[n] = kb and kb * 1024 or nil
  end
  table.sort(targets, function(a, b)
    local da, db = snap.entries[a] == "dir", snap.entries[b] == "dir"
    if da ~= db then return not da end
    return a:lower() < b:lower()
  end)
  local has_dir = false
  local expected
  for _, n in ipairs(targets) do if snap.entries[n] == "dir" then has_dir = true end end
  for _, sh in ipairs(scripts) do
    local lp = snap.by_script[sh]
    expected = expected or (lp and (lp.gamedir or lp.refdir or lp.dir))
  end
  return { port = p, base = base, selected_dir = dir, scan = snap, targets = targets,
    sizes = sizes, evidence = evidence, scripts = scripts, set = set,
    missing_dir = not has_dir, expected_dir = expected,
    is_dir = function(n) return snap.entries[n] == "dir" end }
end

--- Pasta escolhida a mao para um port cujo .sh existe mas a pasta nao foi
--- localizada. So aceita uma pasta DIRETAMENTE dentro da pasta de ports, que
--- nao seja link, protegida, montada ou usada por outro jogo.
--- Devolve nome (relativo a pasta de ports) ou nil, motivo
function X.check_folder(plan, abs)
  if type(abs) ~= "string" or abs == "" then return nil, L("Nenhuma pasta escolhida.") end
  abs = abs:gsub("/+$", "")
  local name = abs:match("([^/]+)$")
  local parent = abs:match("^(.*)/[^/]+$") or ""
  if abs == "" or abs == "/" or not name then return nil, L("A raiz do cartão não pode ser apagada.") end
  if U.exec_ok("test -L " .. U.shq(abs)) then
    return nil, L("A pasta escolhida é um link simbólico. Por segurança, ela não é apagada.")
  end
  if not U.is_dir(abs) then return nil, L("A pasta escolhida não existe mais.") end
  local rp = U.trim(U.capture("readlink -f -- " .. U.shq(parent) .. " 2>/dev/null") or "")
  if rp ~= plan.base then
    return nil, L("Só uma pasta que esteja diretamente dentro da pasta de ports pode ser apagada: ") .. plan.base
  end
  if not valid_name(name) then
    return nil, L("A pasta \"") .. name .. L("\" é protegida (sistema, PortMaster, runtimes ou o próprio hub) e não pode ser apagada.")
  end
  local real = U.trim(U.capture("readlink -f -- " .. U.shq(abs) .. " 2>/dev/null") or "")
  if real == "" or real == plan.base or real:sub(1, #plan.base + 1) ~= plan.base .. "/" then
    return nil, L("A pasta escolhida fica fora da pasta de ports.")
  end
  for _, mp in ipairs(mounts()) do
    if mp == real or mp:sub(1, #real + 1) == real .. "/" then
      return nil, L("A pasta \"") .. name .. L("\" está em uso (há algo montado nela). Nada foi apagado.")
    end
  end
  for _, other in ipairs(plan.scan.ports) do
    if not plan.set[other.script] then
      local uses = other.dir == name or other.gamedir == name or other.refdir == name
      for _, it in ipairs(other.pm_items or other.port_items or {}) do if it == name then uses = true end end
      if uses then
        return nil, L("A pasta \"") .. name .. L("\" é usada por outro jogo (\"") .. other.script .. L("\"). Nada foi apagado.")
      end
    end
  end
  return name
end

--- acrescenta a pasta escolhida ao plano (depois de check_folder)
function X.add_folder(plan, name)
  if plan.set[name] then return end
  plan.set[name] = true
  plan.targets[#plan.targets + 1] = name
  plan.manual_dir = name
  plan.missing_dir = false
  plan.evidence[#plan.evidence + 1] = L("pasta escolhida manualmente")
  local out = U.capture("timeout 4 du -sk " .. U.shq(plan.base .. "/" .. name) .. " 2>/dev/null") or ""
  local kb = tonumber(out:match("^(%d+)"))
  plan.sizes[name] = kb and kb * 1024 or nil
  local is_dir = plan.is_dir
  plan.is_dir = function(n) return n == name or is_dir(n) end
end

--- limpa o registro de um jogo que nao existe mais no cartao
function X.clear_record(p)
  local had = Manifest.data[p.id] ~= nil
  if had and Manifest.data[p.id].gamelist then
    pcall(require("core.esgamelist").remove_port, Manifest.data[p.id].gamelist)
  end
  if had then Manifest.data[p.id] = nil; Manifest.save() end
  Manifest.invalidate()
  Manifest.rescan(true)
  return had
end

function X.busy() return X.job ~= nil and not X.job.finished end

function X.start(plan)
  if X.busy() then return false end
  X.seq = X.seq + 1
  local j = { plan = plan, finished = false, out = "r36sbr_del_out_" .. X.seq }
  j.ch = love.thread.getChannel(j.out)
  j.ch:clear()
  j.thread = love.thread.newThread("threads/delete_thread.lua")
  j.thread:start({ out_channel = j.out, base = plan.base, items = plan.targets })
  X.job = j
  U.log("excluindo:", plan.port.name, table.concat(plan.targets, ", "))
  return true
end

function X.update()
  local j = X.job
  if not j or j.finished then return end
  local err = j.thread:getError()
  if err then
    j.finished, j.ok, j.error = true, false, L("Erro interno: ") .. tostring(err)
    return
  end
  local m = j.ch:pop()
  while m do
    if m.t == "done" then
      j.finished, j.ok, j.failed = true, (#(m.failed or {}) == 0), m.failed or {}
      -- remove o registro do hub so se tudo foi apagado; atualiza a lista de instalados
      local p = j.plan.port
      -- desfaz a capa que o hub colocou no gamelist.xml (so o que ele criou)
      local rec = Manifest.data[p.id]
      if j.ok and rec and rec.gamelist then
        local ok, err = pcall(require("core.esgamelist").remove_port, rec.gamelist)
        if not ok then U.log("gamelist.xml: erro ao remover a capa:", tostring(err)) end
      end
      local rec = Manifest.data[p.id]
      if j.ok and rec and (rec.ports_dir or C.PORTS_DIR) == j.plan.selected_dir then
        Manifest.data[p.id] = nil
        Manifest.save()
      end
      Manifest.rescan(true)
      Manifest.refresh_locations()
    end
    m = j.ch:pop()
  end
end

function X.clear() if X.job and X.job.finished then X.job = nil end end

return X
