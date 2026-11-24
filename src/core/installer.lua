-- =============================================================================
--  Gerenciador da instalacao (lado da interface). Uma instalacao por vez.
-- =============================================================================
local L = require("lib.i18n").L
local C = require("config")
local U = require("lib.util")
local Manifest = require("core.manifest")
local PortStorage = require("core.portstorage")
local RomStorage = require("core.romstorage")

local I = { job = nil, seq = 0 }

local ERRORS = {
  no_ports_dir = L("A pasta de ports não foi encontrada: %s"),
  no_write = L("Sem permissão para gravar em: %s"),
  no_unzip = L("O comando 'unzip' não está disponível no sistema."),
  no_curl = L("Nem 'curl' nem 'wget' estão disponíveis no sistema."),
  no_space = L("Espaço insuficiente no cartão."),
  http_error = L("O servidor recusou o download (link inválido ou removido)."),
  net_error = L("Falha de conexão durante o download. Verifique o Wi-Fi e tente de novo."),
  empty_file = L("O download terminou, mas o arquivo veio vazio."),
  not_zip = L("O arquivo baixado não é um pacote válido (ZIP, RAR, 7z ou TAR)."),
  no_extractor = L("Não há extrator de %s disponível no console."),
  encrypted = L("Nenhuma senha salva abriu o arquivo compactado. Digite a senha no teclado do console."),
  incomplete_parts = L("Arquivo dividido incompleto ou primeira parte ausente: %s"),
  no_memory = L("Memória insuficiente para extrair este arquivo no console."),
  size_mismatch = L("Download incompleto: o tamanho do arquivo não confere."),
  checksum = L("Arquivo corrompido: a verificação (checksum) falhou."),
  bad_zip = L("O arquivo compactado está corrompido e não pôde ser extraído."),
  unsafe_zip = L("O pacote contém caminhos inseguros e foi recusado."),
  empty_pkg = L("O pacote não contém arquivos de port."),
  no_script = L("Pacote inválido: nenhum script .sh na raiz do port."),
  install_failed = L("Falha ao copiar para a pasta de ports: %s"),
  no_url = L("Este port ainda não tem link de download cadastrado."),
  busy = L("Já existe uma instalação em andamento."),
  no_python = L("Python 3 não encontrado: necessário para instalar ROMs com segurança."),
  unsupported_rom = L("Arquivo de ROM incompatível com o sistema: %s"),
  invalid_system = L("Sistema ou destino de ROM inválido: %s"),
  exists = L("Arquivo ou jogo já existe no destino: %s. Nenhum arquivo foi substituído."),
  internal = L("Erro interno durante a instalação."),
}

function I.error_text(code, detail)
  local msg = ERRORS[code] and require("lib.i18n").tr(ERRORS[code]) or (L("Erro: ") .. tostring(code))
  if msg:find("%%s") then msg = msg:format(detail or "") end
  if code == "no_space" and detail and detail:match("^%d+|%d+$") then
    local need, have = detail:match("^(%d+)|(%d+)$")
    msg = msg .. string.format(L("\nNecessário: %s   Livre: %s"), U.format_bytes(tonumber(need)), U.format_bytes(tonumber(have)))
  elseif code == "size_mismatch" and detail and detail:match("^%d+|%d+$") then
    local got, exp = detail:match("^(%d+)|(%d+)$")
    msg = msg .. string.format(L("\nRecebido: %s de %s"), U.format_bytes(tonumber(got)), U.format_bytes(tonumber(exp)))
  elseif (code == "not_zip" or code == "bad_zip" or code == "net_error" or code == "http_error" or code == "internal"
      or code == "unsupported_rom" or code == "invalid_system" or code == "exists" or code == "install_failed")
      and detail and detail ~= "" then
    msg = msg .. "\n(" .. U.safe_utf8(detail):sub(1, 90) .. ")"
  end
  return msg
end

function I.busy() return I.job ~= nil and not I.job.finished end

--- Inicia a instalacao de um port. Devolve false, erro se nao puder.
function I.start(p, opts)
  opts = opts or {}
  if I.busy() then return false, ERRORS.busy end
  if not opts.local_file and (not p.download_url or not p.download_url:match("^https?://")) then
    return false, ERRORS.no_url
  end
  local dest_dir = opts.dest_dir or C.PORTS_DIR
  if opts.mode == "rom" then
    if opts.rom_system ~= p.category_id or p.section ~= "games" then
      return false, ERRORS.invalid_system
    end
    local valid, details = RomStorage.validate(dest_dir, opts.rom_system)
    if not valid then return false, details end
    if not RomStorage.filename(p) then return false, ERRORS.unsupported_rom end
  elseif (opts.mode or "port") ~= "extract" then
    local valid, details = PortStorage.validate(dest_dir)
    if not valid then return false, details end
  end
  local AR = require("core.archives")
  local parts
  if opts.local_file then
    local first, found = AR.validate_parts(opts.local_file)
    if not first then return false, ERRORS.incomplete_parts .. ": " .. tostring(found or "") end
    parts = found
    if first ~= opts.local_file then
      opts.local_file = first
      p.id = "file:" .. first
    end
  end
  I.seq = I.seq + 1
  local j = {
    port = p,
    opts = opts,
    phase = "prepare",
    done = 0, total = p.size,
    speed = 0, eta = nil,
    t0 = love.timer.getTime(),
    samples = {},
    finished = false,
    result = nil,     -- "done" | "error" | "cancelled"
    confirm = nil,    -- lista de conflitos aguardando resposta
    out = "hub_inst_out_" .. I.seq,
    inn = "hub_inst_in_" .. I.seq,
  }
  j.out_ch = love.thread.getChannel(j.out)
  j.in_ch = love.thread.getChannel(j.inn)
  j.out_ch:clear(); j.in_ch:clear()
  j.thread = love.thread.newThread("threads/install_thread.lua")
  j.thread:start({ lang = require("lib.i18n").lang,
    out_channel = j.out, in_channel = j.inn,
    name = p.name, slug = p.slug,
    url = p.download_url,
    expected_size = p.size_exact and p.size or 0,
    sha256 = p.sha256, md5 = p.md5,
    ports_dir = dest_dir, tmp_dir = (opts.mode == "extract") and C.TMP_DIR
      or (opts.mode == "rom" and RomStorage.tmp_dir(dest_dir, opts.rom_system))
      or PortStorage.tmp_dir(dest_dir),
    local_file = opts.local_file, delete_source = opts.delete_source and true or false,
    mode = opts.mode or "port",
    rom_system = opts.rom_system,
    rom_filename = opts.mode == "rom" and RomStorage.filename(p) or nil,
    fetch_sh = C.FETCH_SH,
    margin = C.SPACE_MARGIN,
    protected = C.PROTECTED_NAMES,
    allow_no_script = p.allow_no_script,
    bundled_7z = C.APP_DIR .. "/bin/7zzs",
    secure_7z = C.APP_DIR .. "/bin/secure_7z.py",
    sevenzip = os.getenv("R36SBR_7Z") or "",
    preapproved = opts.preapproved and true or false,
    passwords = opts.password and { opts.password } or AR.passwords(),
    groups = AR.DEFAULT_PASSWORDS,
    parts = parts,
    multipart = parts and #parts > 1 or false,
  })
  I.job = j
  U.log("instalacao iniciada:", p.name, p.download_url)
  return true
end

local function update_speed(j, now)
  local s = j.samples
  s[#s + 1] = { now, j.done }
  while #s > 2 and now - s[1][1] > 4 do table.remove(s, 1) end
  if #s >= 2 and s[#s][1] > s[1][1] then
    j.speed = (s[#s][2] - s[1][2]) / (s[#s][1] - s[1][1])
    if j.total and j.total > 0 and j.speed > 0 then
      j.eta = (j.total - j.done) / j.speed
    else
      j.eta = nil
    end
  end
end

function I.update()
  local j = I.job
  if not j or j.finished then return end
  local err = j.thread:getError()
  if err then
    U.log("thread de instalacao falhou:", err)
    j.finished, j.result, j.error = true, "error", I.error_text("internal", err)
    return
  end
  local m = j.out_ch:pop()
  while m do
    if m.t == "phase" then
      j.phase = m.phase
      j.done = 0
      if m.total then j.total = m.total end
      if m.phase == "download" then j.samples = {}; j.speed = 0; j.eta = nil end
    elseif m.t == "progress" then
      j.phase = m.phase or j.phase
      j.done = m.done or 0
      if m.total then j.total = m.total end
      if j.phase == "download" then update_speed(j, love.timer.getTime()) end
    elseif m.t == "confirm" then
      j.confirm = m.items
    elseif m.t == "done" then
      -- ROMs usam registro proprio. Nao criar scripts nem entradas do PortMaster.
      if j.opts.mode ~= "rom" and not (j.opts and j.opts.local_file) then
        local prev = Manifest.data[j.port.id] and Manifest.data[j.port.id].gamelist
        Manifest.record(j.port, m.entries, j.opts.dest_dir or C.PORTS_DIR)
        I.apply_es_cover(j, m.entries, prev)
      end
      if j.opts.mode ~= "rom" then Manifest.rescan(true) end
      j.skipped_extract = m.skipped_extract
      j.finished, j.result, j.entries, j.deleted = true, "done", m.entries, m.deleted
    elseif m.t == "error" then
      j.finished, j.result = true, "error"
      j.error = I.error_text(m.code, m.detail)
      j.error_code = m.code
      if m.code == "encrypted" and j.opts and j.opts.password then
        j.error = L("Senha incorreta.")
      end
    elseif m.t == "cancelled" then
      j.finished, j.result = true, "cancelled"
    end
    m = j.out_ch:pop()
  end
end

--- capa do port na lista de Ports do EmulationStation (gamelist.xml)
function I.apply_es_cover(j, entries, prev)
  local p = j.port
  local ok, err = pcall(function()
    require("core.covers").fetch_file(p, function(file)
      local okc, info, why = pcall(require("core.esgamelist").add_port, p, entries, file,
        j.opts.dest_dir or C.PORTS_DIR)
      if okc and info then
        -- reinstalacao: a entrada criada antes continua sendo do hub
        if prev and (not prev.ports_dir or prev.ports_dir == (j.opts.dest_dir or C.PORTS_DIR))
            and type(prev.entries) == "table" then
          local seen = {}
          for _, e in ipairs(info.entries) do seen[e.script] = true end
          for _, e in ipairs(prev.entries) do if not seen[e.script] then info.entries[#info.entries + 1] = e end end
        end
        local rec = Manifest.data[p.id]
        if rec then rec.gamelist = info; Manifest.save() end
        j.es_cover = true
        U.log("gamelist.xml: capa de " .. tostring(p.name), #info.entries > 0 and info.entries[1].mode or "ja tinha imagem")
      else
        U.log("gamelist.xml: capa de " .. tostring(p.name) .. " nao aplicada:", tostring(okc and why or info))
      end
    end)
  end)
  if not ok then U.log("gamelist.xml: erro ao aplicar a capa:", tostring(err)) end
end

function I.cancel()
  local j = I.job
  if not j or j.finished then return end
  j.cancelling = true
  j.in_ch:push({ t = "cancel" })
end

function I.answer(yes)
  local j = I.job
  if not j or not j.confirm then return end
  j.confirm = nil
  j.in_ch:push({ t = "answer", yes = yes and true or false })
end

function I.clear()
  if I.job and I.job.finished then I.job = nil end
end

return I
