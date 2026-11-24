-- =============================================================================
--  R36S ROMS STORE HUB - thread de instalacao
--  Roda fora da thread principal para nao travar a interface.
--  Etapas: espaco -> download -> verificacao -> extracao (pasta temporaria)
--          -> analise da estrutura -> confirmacao de sobrescrita -> instalacao
--  Comunicacao: canal de saida (mensagens para a interface) e canal de entrada
--  (cancelar / resposta da confirmacao).
-- =============================================================================
require("love.timer")

local job = ...
require("love.filesystem")
local I18N = require("lib.i18n")
I18N.set(job.lang or "pt-BR")
local L = I18N.L
local OUT = love.thread.getChannel(job.out_channel)
local IN = love.thread.getChannel(job.in_channel)

local function shq(s) return "'" .. tostring(s or ""):gsub("'", "'\\''") .. "'" end
local function ok(r) return r == 0 or r == true end
local function sh(cmd) return ok(os.execute(cmd)) end
local function capture(cmd)
  local h = io.popen(cmd)
  if not h then return "" end
  local s = h:read("*a") or ""
  h:close()
  return s
end
local function log(...)
  local t = {}
  for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end
  print("[install] " .. table.concat(t, " "))
  io.stdout:flush()
end
local function send(msg) OUT:push(msg) end
local function fsize(p)
  local f = io.open(p, "rb")
  if not f then return nil end
  local s = f:seek("end")
  f:close()
  return s
end
local function read_all(p)
  local f = io.open(p, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

-- O arquivo parcial pausado fica fora da limpeza job_* na abertura.
local resumable = job.mode == "rom" and not job.local_file
local WORK = job.tmp_dir .. (resumable and "/rom_resume_" or "/job_") .. job.slug
local ZIP = WORK .. "/download.zip"
local PART = ZIP .. ".part"
local STAGE = WORK .. "/stage"
local PIDF = WORK .. "/dl.pid"
local RCF = WORK .. "/dl.rc"
local STOP = WORK .. "/dl.stop"
local MARK = WORK .. "/resume.url"

local cancelled, paused = false, false
local extract_7z
local function check_cancel()
  local m = IN:pop()
  while m do
    if m.t == "cancel" then cancelled = true end
    if m.t == "pause" and resumable then paused = true end
    m = IN:pop()
  end
  return cancelled
end

local function cleanup()
  sh("rm -rf " .. shq(WORK) .. " 2>/dev/null")
end

local function fail(code, detail)
  log("ERRO", code, detail or "")
  cleanup()
  send({ t = "error", code = code, detail = detail or "" })
end

local function cancel_done()
  log("cancelado pelo usuario")
  cleanup()
  send({ t = "cancelled" })
end

local function free_bytes(path)
  local out = capture("df -Pk " .. shq(path) .. " 2>/dev/null | tail -n 1")
  local avail = out:match("^%S+%s+%d+%s+%d+%s+(%d+)")
  return avail and tonumber(avail) * 1024 or nil
end

local function lower(s) return (s or ""):lower() end

-- ---------------------------------------------------------------------------
-- Extrator para RAR e 7z. Prefere o 7-Zip incluso (bin/7zzs, aarch64 estatico),
-- copiado para /tmp porque o cartao pode nao permitir executar binarios.
local function find_7z()
  local cands = {}
  if job.sevenzip and job.sevenzip ~= "" then cands[#cands + 1] = job.sevenzip end
  local tmpbin = "/tmp/r36sromsstore-7zzs"
  if job.bundled_7z and sh("test -f " .. shq(job.bundled_7z)) then
    sh("cp -f " .. shq(job.bundled_7z) .. " " .. shq(tmpbin) .. " 2>/dev/null && chmod 755 " .. shq(tmpbin))
    cands[#cands + 1] = tmpbin
  end
  for _, n in ipairs({ "7zz", "7zzs", "7z", "7za" }) do
    local pth = capture("command -v " .. n .. " 2>/dev/null"):match("^(%S+)")
    if pth then cands[#cands + 1] = pth end
  end
  for _, c in ipairs(cands) do
    if sh(shq(c) .. " i >/dev/null 2>&1") then return c end
  end
  return nil
end

-- senha que abriu o arquivo (nil = sem senha). Nunca vai para o log.
local PWD = nil
local TARF = ""   -- opcao de compressao do tar ("", "z", "J" ou "j")
-- O helper recebe a senha em /dev/shm por arquivo privado 0600, le e apaga
-- imediatamente; o 7-Zip recebe '-p' interativamente via terminal PTY.
-- Nunca passar senha nos argumentos do processo ou nos logs.
local function open_7z(exe, action, args, pw)
  local cmd, secret
  if pw then
    if type(job.secure_7z) ~= "string" or not sh("test -f " .. shq(job.secure_7z))
        or not sh("command -v python3 >/dev/null 2>&1") then
      return nil
    end
    secret = capture("mktemp /dev/shm/r36sbr-password.XXXXXX 2>/dev/null"):match("^(%S+)")
      or capture("mktemp /tmp/r36sbr-password.XXXXXX 2>/dev/null"):match("^(%S+)")
    if not secret then return nil end
    local sf = io.open(secret, "wb")
    if not sf then os.remove(secret); return nil end
    sf:write(pw, "\n")
    sf:close()
    cmd = "python3 " .. shq(job.secure_7z) .. " " .. shq(secret)
      .. " " .. shq(exe) .. " " .. action .. " " .. args
  else
    cmd = shq(exe) .. " " .. action .. " -p- " .. args
  end
  local h = io.popen(cmd .. " 2>&1; echo __PHX:$?")
  if not h then
    if secret then os.remove(secret) end
    return nil
  end
  return h, function() if secret then os.remove(secret) end end
end
local function call_7z(exe, action, args, pw)
  local h, done = open_7z(exe, action, args, pw)
  if not h then return "__PHX:127" end
  local out=h:read("*a") or ""
  h:close()
  done()
  return out
end

extract_7z = function(fmt)
  local X = find_7z()
  local unrar = (not X and fmt == "rar") and capture("command -v unrar 2>/dev/null"):match("^(%S+)") or nil
  if not X and not unrar then fail("no_extractor", fmt:upper()); return false end

  local entries, unpacked = 0, 0
  if X then
    log("extrator:", X)
    -- lista tecnica: caminhos, tamanhos, pastas, criptografia
    local function lst(pw) return call_7z(X, "l", "-slt -ba " .. shq(ZIP), pw) end
    local listing = lst(nil)
    local lcode = tonumber(listing:match("__PHX:(%d+)")) or 2
    local pwlist = job.passwords or {}
    if lcode > 1 and (listing:find("Wrong password") or listing:find("Can not open encrypted")) then
      -- nomes tambem criptografados: so lista com a senha certa
      local found = false
      for i, pw in ipairs(pwlist) do
        local l2 = lst(pw)
        local c2 = tonumber(l2:match("__PHX:(%d+)")) or 2
        if c2 <= 1 and not l2:find("Wrong password") then
          PWD, listing, lcode, found = pw, l2, c2, true
          log("arquivo com senha: senha salva n." .. i .. " funcionou")
          break
        end
      end
      if not found then fail("encrypted"); return false end
    elseif listing:find("Encrypted = %+") then
      -- conteudo criptografado: testa a senha num arquivo pequeno do pacote
      local test, tsz
      for block in (listing .. "\n\n"):gmatch("(Path = .-)\n\n") do
        if block:find("\nEncrypted = %+") and not block:find("\nFolder = %+") then
          local sz = tonumber(block:match("\nSize = (%d+)")) or 0
          if not tsz or sz < tsz then test, tsz = block:match("^Path = ([^\n]*)"), sz end
        end
      end
      local found = false
      for i, pw in ipairs(pwlist) do
        local testout = call_7z(X, "t", "-bso0 -bse0 -bsp0 " .. shq(ZIP)
          .. (test and (" " .. shq(test)) or ""), pw)
        local code = tonumber(testout:match("__PHX:(%d+)")) or 2
        if code == 0 or code == 1 then
          PWD, found = pw, true
          log("arquivo com senha: senha salva n." .. i .. " funcionou")
          break
        end
      end
      if not found then fail("encrypted"); return false end
    end
    if lcode > 1 then fail("bad_zip", (listing:match("ERROR: ([^\n]+)") or ""):sub(1, 80)); return false end
    for block in (listing .. "\n\n"):gmatch("(Path = .-)\n\n") do
      local path = block:match("^Path = ([^\n]*)")
      if path and path ~= "" then
        entries = entries + 1
        path = path:gsub("\\", "/")
        if path:sub(1, 1) == "/" or path:find("^%a:") or path:find("%.%./") or path:find("/%.%.$") or path == ".." then
          fail("unsafe_zip", path); return false
        end
        unpacked = unpacked + (tonumber(block:match("\nSize = (%d+)")) or 0)
      end
    end
  else
    log("extrator: unrar", unrar)
    local listing = capture(shq(unrar) .. " lb -p- " .. shq(ZIP) .. " 2>/dev/null")
    if listing == "" then
      -- O unrar exige senha em argumentos: nao permitir vazamento via ps.
      fail("no_extractor", "7-Zip/Python3 necessario para RAR com senha")
      return false
    end
    for line in listing:gmatch("[^\n]+") do
      entries = entries + 1
      if line:sub(1, 1) == "/" or line:find("%.%./") then fail("unsafe_zip", line); return false end
    end
  end
  if entries == 0 then fail("bad_zip"); return false end

  local avail = free_bytes(job.ports_dir)
  if avail and avail < unpacked + job.margin then
    fail("no_space", string.format("%d|%d", unpacked + job.margin, avail)); return false
  end

  send({ t = "phase", phase = "extract", total = entries })
  local h, cleanup_password
  if X then
    -- -mmt1 limita uso de RAM/CPU; senha via PTY protegido quando necessaria.
    h, cleanup_password = open_7z(X, "x", "-y -mmt1 -bb1 -bso1 -bse1 -bsp0 -o"
      .. shq(STAGE) .. " " .. shq(ZIP), PWD)
  else
    h = io.popen("cd " .. shq(STAGE) .. " && " .. shq(unrar)
      .. " x -o+ -y -p- " .. shq(ZIP) .. " 2>&1; echo __PHX:$?")
  end
  local count, code, lastpct, errl = 0, nil, -1, nil
  if h then
    for line in h:lines() do
      local c = line:match("^__PHX:(%d+)")
      if c then code = tonumber(c)
      else
        if line:match("^%- ") or line:match("^Extracting%s") or line:match("^Creating%s") then
          count = count + 1
        elseif not errl and (line:find("ERROR") or line:find("Error")) then
          errl = line
        end
        local pct = math.floor(count / entries * 100)
        if pct ~= lastpct then
          send({ t = "progress", phase = "extract", done = math.min(count, entries), total = entries })
          lastpct = pct
        end
        if count % 25 == 0 and check_cancel() then break end
      end
    end
    h:close()
  end
  if cleanup_password then cleanup_password() end
  if cancelled then cancel_done(); return false end
  -- 7-Zip: 0 = ok, 1 = aviso; 2 = erro fatal; 8 = sem memoria. unrar: 0 = ok
  if code == nil or code > 1 then
    if errl and (errl:find("[Ww]rong password") or errl:find("encrypted")) then fail("encrypted"); return false end
    if errl and errl:lower():find("space") then fail("no_space", ""); return false end
    if code == 8 then fail("no_memory"); return false end
    fail("bad_zip", (errl or (L("codigo ") .. tostring(code))):sub(1, 80)); return false
  end
  return true
end

-- ---------------------------------------------------------------------------
local function run()
  log("iniciando:", job.name, "->", job.ports_dir)

  -- 0) preparacao -----------------------------------------------------------
  send({ t = "phase", phase = "prepare" })
  -- Pastas de ROM pertencem ao sistema selecionado, nunca a /ports.
  if job.mode == "rom" then
    local roots = { ["/roms/"] = true, ["/roms2/"] = true }
    local base, folder = job.ports_dir:match("^(/roms2?/)([%w_%-]+)$")
    if not (roots[base] and folder and job.rom_system) then
      return fail("invalid_system", job.ports_dir)
    end
  end
  if not sh("test -d " .. shq(job.ports_dir)) then
    if job.mode ~= "rom" and job.ports_dir ~= "/roms/ports" and job.ports_dir ~= "/roms2/ports" then
      return fail("no_ports_dir", job.ports_dir)
    end
    if not sh("mkdir -p " .. shq(job.ports_dir)) then return fail("no_ports_dir", job.ports_dir) end
  end
  if not sh("test -w " .. shq(job.ports_dir)) then
    return fail("no_write", job.ports_dir)
  end
  local preserve = resumable and job.resume_download and read_all(MARK) == job.url .. "\n" .. job.ports_dir
  if not preserve then cleanup() end
  os.remove(MARK); os.remove(STOP)
  if not sh("mkdir -p " .. shq(STAGE)) then
    return fail("no_write", job.tmp_dir)
  end

  local expected, got
  if job.local_file then
    -- arquivo que ja esta no cartao (Gerenciador de arquivos): sem download
    PART = job.local_file
    got = fsize(PART) or 0
    log("arquivo local:", PART, got, "bytes")
  else

  -- tamanho esperado: o que o SERVIDOR informa vale mais que o do catalogo.
  -- Catalogos costumam trazer o tamanho arredondado (ex.: 1.6 GB em bytes) e
  -- isso fazia um download completo ser recusado como "incompleto".
  local catalog_size = tonumber(job.expected_size)
  if catalog_size and catalog_size <= 0 then catalog_size = nil end
  local h = capture("sh " .. shq(job.fetch_sh) .. " head " .. shq(job.url) .. " 2>/dev/null")
  local server_size = tonumber(h:match("(%d+)"))
  if server_size and server_size <= 0 then server_size = nil end
  if server_size and catalog_size and server_size ~= catalog_size then
    log("tamanho do catalogo (" .. catalog_size .. ") difere do servidor (" .. server_size .. "): usando o do servidor")
  end
  expected = server_size or catalog_size
  job.server_size = server_size

  -- 1) espaco para o ZIP ----------------------------------------------------
  local avail = free_bytes(job.ports_dir)
  if expected and avail and avail < math.max(0, expected - (preserve and (fsize(PART) or 0) or 0)) + job.margin then
    return fail("no_space", string.format("%d|%d", expected + job.margin, avail))
  end
  if check_cancel() then return cancel_done() end

  -- 2) download (em segundo plano, com acompanhamento) ---------------------
  send({ t = "phase", phase = "download", total = expected })
  if not preserve then os.remove(PART) end
  os.remove(RCF); os.remove(PIDF); os.remove(STOP)
  sh("sh " .. shq(job.fetch_sh) .. " get " .. shq(job.url) .. " " .. shq(PART) .. " "
    .. shq(PIDF) .. " " .. shq(RCF) .. " 0 " .. shq(STOP) .. " >" .. shq(WORK .. "/fetch.log") .. " 2>&1 &")

  local last_push = -1
  local rc
  while true do
    love.timer.sleep(0.25)
    check_cancel()
    if cancelled or paused then
      -- O fetch.sh verifica STOP antes de cada tentativa. Aguardar RC antes
      -- de preservar/remover arquivos para nao deixar escritor ativo.
      local flag=io.open(STOP,"wb")
      if flag then flag:write("1"); flag:close() end
      local pid=(read_all(PIDF) or ""):match("^%s*(%d+)%s*$")
      if pid and tonumber(pid)>1 then sh("kill " .. pid .. " 2>/dev/null") end
    end
    local s=read_all(RCF)
    if s and s:match("^%s*%d+%s*$") then rc=tonumber(s); break end
    local done = fsize(PART) or 0
    if done ~= last_push then
      send({ t = "progress", phase = "download", done = done, total = expected })
      last_push = done
    end
  end

  got = fsize(PART) or 0
  send({ t = "progress", phase = "download", done = got, total = expected })
  if cancelled then return cancel_done() end
  if paused then
    local f=io.open(MARK,"wb")
    if not f then return fail("no_write",WORK) end
    local written=f:write(job.url .. "\n" .. job.ports_dir)
    local closed=f:close()
    if not written or not closed then return fail("no_write",WORK) end
    os.remove(STOP); os.remove(PIDF); os.remove(RCF)
    send({t="paused",done=got,total=expected})
    return
  end
  if rc ~= 0 then
    local flog = read_all(WORK .. "/fetch.log") or ""
    log("fetch rc=", rc, flog)
    if rc == 22 then return fail("http_error", flog:match("error:%s*([^\n]+)") or "") end
    if rc == 127 then return fail("no_curl") end
    if rc == 23 then return fail("no_space", "") end
    return fail("net_error", tostring(rc))
  end
  end -- fim do download

  -- 3) verificacao ----------------------------------------------------------
  send({ t = "phase", phase = "verify" })
  if got <= 0 then return fail("empty_file") end
  local f = io.open(PART, "rb")
  local head = f and f:read(512) or ""
  if f then f:close() end
  -- formato pela assinatura do arquivo (nao pela extensao do link)
  local fmt
  if head:sub(1, 2) == "PK" then fmt = "zip"
  elseif head:sub(1, 7) == "Rar!\26\7\0" or head:sub(1, 8) == "Rar!\26\7\1\0" then fmt = "rar"
  elseif head:sub(1, 6) == "7z\188\175\39\28" then fmt = "7z"
  elseif head:sub(258, 262) == "ustar" then fmt = "tar"; TARF = ""            -- .tar
  elseif head:sub(1, 2) == "\31\139" then fmt = "tar"; TARF = "z"            -- .tar.gz / .tgz
  elseif head:sub(1, 6) == "\253\55\122\88\90\0" then fmt = "tar"; TARF = "J" -- .tar.xz
  elseif head:sub(1, 3) == "BZh" then fmt = "tar"; TARF = "j"                -- .tar.bz2
  end
  if not fmt and job.mode == "rom" then
    local low = lower(head):gsub("^%s+", "")
    if low:find("^<!doct") or low:find("^<html") or low:find("^<%?xml")
        or low:sub(1,1)=="{" or low:sub(1,1)=="[" then
      return fail("not_zip", "Resposta HTML/JSON/XML, não uma ROM")
    end
    fmt = "rom_direct"
  end
  if not fmt then
    local low = lower(head):gsub("^%s+", "")
    local what = "desconhecido"
    if low:find("^<!doct") or low:find("^<html") then
      what = (head:match("<[Tt][Ii][Tt][Ll][Ee]>%s*(.-)%s*</") or L("página HTML")):sub(1, 60)
    elseif low:sub(1, 1) == "{" or low:sub(1, 1) == "[" then
      what = L("resposta JSON")
    end
    return fail("not_zip", what)
  end
  log("formato do pacote:", fmt)
  if job.server_size and got ~= job.server_size then
    -- o servidor informou o tamanho e o arquivo veio diferente: download incompleto
    return fail("size_mismatch", string.format("%d|%d", got, job.server_size))
  elseif not job.local_file and not job.server_size and expected and got ~= expected then
    -- sem tamanho do servidor: o download terminou sem erro (curl/wget), mas o
    -- tamanho difere do catalogo, que pode estar arredondado. O hash (se houver)
    -- e a extracao (que falha com arquivo cortado), logo abaixo, conferem.
    log("aviso: tamanho baixado " .. got .. " difere do catalogo " .. expected .. " (servidor nao informou o tamanho)")
  end
  if job.sha256 and job.sha256 ~= "" then
    local sum = capture("sha256sum " .. shq(PART) .. " 2>/dev/null"):match("^(%x+)")
    if not sum then
      log("sha256sum indisponivel; pulando verificacao")
    elseif lower(sum) ~= lower(job.sha256) then
      return fail("checksum")
    end
  elseif job.md5 and job.md5 ~= "" then
    local sum = capture("md5sum " .. shq(PART) .. " 2>/dev/null"):match("^(%x+)")
    if sum and lower(sum) ~= lower(job.md5) then return fail("checksum") end
  end
  if job.local_file then
    ZIP = PART      -- usa o arquivo no lugar (so e excluido apos sucesso)
  elseif not os.rename(PART, ZIP) then
    return fail("no_write", WORK)
  end
  if check_cancel() then return cancel_done() end

  -- Modo ROM: instala arquivo isolado ou pacote de disco sem exigir script .sh.
  -- O helper dentro do game.love faz extracao segura e recusa sobrescrita.
  if job.mode == "rom" then
    if not sh("command -v python3 >/dev/null 2>&1") then return fail("no_python") end
    local helper = love.filesystem.read("threads/rom_install.py")
    if not helper then return fail("internal", "rom_install.py não encontrado") end
    local helper_path = WORK .. "/rom_install.py"
    local f = io.open(helper_path, "wb")
    if not f then return fail("no_write", helper_path) end
    f:write(helper); f:close()
    local cancel_flag = WORK .. "/rom_cancel"
    local seven = ""
    if fmt == "7z" or fmt == "rar" then seven = find_7z() or "" end
    local cmd = "python3 -u " .. shq(helper_path)
      .. " --source " .. shq(ZIP) .. " --stage " .. shq(STAGE)
      .. " --dest " .. shq(job.ports_dir)
      .. " --system " .. shq(job.rom_system)
      .. " --filename " .. shq(job.rom_filename)
      .. " --slug " .. shq((job.slug or ""):sub(1,110))
      .. " --format " .. shq(fmt) .. " --margin " .. tostring(job.margin or 0)
      .. " --sevenzip " .. shq(seven) .. " --cancel " .. shq(cancel_flag)
    local pipe = io.popen(cmd .. " 2>&1; echo __ROM_EXIT:$?")
    if not pipe then return fail("internal", "Não foi possível iniciar instalador de ROM") end
    local code, detail, installed, skipped, exitcode
    for line in pipe:lines() do
      local phase,total=line:match("^PHASE|([%w_]+)|(%d+)$")
      local p,d,t=line:match("^PROGRESS|([%w_]+)|(%d+)|(%d+)$")
      if phase then send({t="phase",phase=phase,total=tonumber(total)})
      elseif p then send({t="progress",phase=p,done=tonumber(d),total=tonumber(t)})
      elseif line:sub(1,5)=="DONE|" then
        installed,skipped=line:match("^DONE|([^|]+)|([01])$")
      elseif line:sub(1,6)=="ERROR|" then
        code,detail=line:match("^ERROR|([^|]+)|?(.*)$")
      elseif line:find("^__ROM_EXIT:") then exitcode=tonumber(line:match("(%d+)$"))
      else log("ROM helper:", line:sub(1,140)) end
      if not installed and check_cancel() then
        local cf=io.open(cancel_flag,"wb")
        if cf then cf:write("1");cf:close() end
      end
    end
    pipe:close()
    if cancelled or code=="cancelled" then return cancel_done() end
    if exitcode ~= 0 or not installed then return fail(code or "internal",detail or "Falha no instalador de ROM") end
    cleanup()
    sh("sync")
    send({t="done",entries={installed},skipped_extract=skipped=="1"})
    return
  end

  -- ZIP com senha ou dividido em partes: o 7-Zip (incluso no hub) cuida, como
  -- no PC. O unzip nao abre ZIP dividido nem testa varias senhas.
  local zip_pw = false
  if fmt == "zip" then
    if job.multipart then
      if find_7z() then fmt = "zip7" else return fail("no_extractor", "ZIP") end
    elseif sh("unzip -Z -v " .. shq(ZIP) .. " 2>/dev/null | grep -qiE 'file security status:[[:space:]]+encrypted'") then
      if find_7z() then fmt = "zip7" else zip_pw = true end
    end
  end
  if fmt == "zip" then
    if not sh("command -v unzip >/dev/null 2>&1") then return fail("no_unzip") end
    if zip_pw then
      -- 7-Zip/Python3 evitam expor a senha no ps (unzip -P exporia).
      return fail("no_extractor", "7-Zip necessario para ZIP com senha")
    end
    -- lista do ZIP: tamanho descompactado, quantidade de itens, caminhos perigosos
    local listing = capture("unzip -Z1 " .. shq(ZIP) .. " 2>/dev/null")
    local entries = 0
    for line in listing:gmatch("[^\n]+") do
      entries = entries + 1
      if line:sub(1, 1) == "/" or line:find("%.%./") or line:find("/%.%.$") or line == ".." then
        return fail("unsafe_zip", line)
      end
    end
    if entries == 0 then return fail("bad_zip") end
    local summary = capture("unzip -l " .. shq(ZIP) .. " 2>/dev/null | tail -n 1")
    local unpacked = tonumber(summary:match("^%s*(%d+)")) or 0

    -- 4) espaco para extrair ---------------------------------------------------
    local avail = free_bytes(job.ports_dir)
    if avail and avail < unpacked + job.margin then
      return fail("no_space", string.format("%d|%d", unpacked + job.margin, avail))
    end

    -- 5) extracao para a pasta temporaria ------------------------------------
    send({ t = "phase", phase = "extract", total = entries })
    local h = io.popen("unzip -o " .. shq(ZIP) .. " -d " .. shq(STAGE) .. " 2>&1; echo __PHX:$?")
    local count, code, lastpct = 0, nil, -1
    local errlines = {}
    if h then
      for line in h:lines() do
        local c = line:match("^__PHX:(%d+)")
        if c then
          code = tonumber(c)
        else
          if line:match("^%s+inflating:") or line:match("^%s+extracting:") or line:match("^%s+creating:")
              or line:match("^%s+linking:") then
            count = count + 1
          elseif line:lower():find("error") or line:lower():find("bad") then
            errlines[#errlines + 1] = line
          end
          local pct = math.floor(count / entries * 100)
          if pct ~= lastpct then
            send({ t = "progress", phase = "extract", done = count, total = entries })
            lastpct = pct
          end
          if count % 25 == 0 and check_cancel() then break end
        end
      end
      h:close()
    end
    if cancelled then return cancel_done() end
    -- unzip: 0 = ok, 1 = avisos (ok); >1 = erro (arquivo corrompido, disco cheio...)
    if code == nil or code > 1 then
      local detail = errlines[1] or (L("codigo ") .. tostring(code))
      if code == 50 then return fail("no_space", "") end
      return fail("bad_zip", detail)
    end
  elseif fmt == "tar" then
    -- TAR (.tar, .tar.gz, .tar.xz, .tar.bz2): o tar do sistema
    if not sh("command -v tar >/dev/null 2>&1") then return fail("no_extractor", "TAR") end
    -- lista: quantidade de itens, tamanho descompactado e caminhos perigosos
    local listing = capture("tar -tv" .. TARF .. "f " .. shq(ZIP) .. " 2>/dev/null")
    local entries, unpacked = 0, 0
    for line in listing:gmatch("[^\n]+") do
      -- "-rwxr-xr-x user/grupo 1234 2024-01-01 12:00 caminho" (links: "a -> b")
      local size, name = line:match("^%S+%s+%S+%s+(%d+)%s+%S+%s+%S+%s+(.+)$")
      if name then
        entries = entries + 1
        unpacked = unpacked + (tonumber(size) or 0)
        name = name:gsub(" %-> .*$", ""):gsub(" link to .*$", "")
        if line:sub(1,1) == "l" or line:sub(1,1) == "h" then
          return fail("unsafe_zip", "TAR: link nao permitido")
        end
        if name:sub(1, 1) == "/" or name:find("%.%./") or name:find("/%.%.$") or name == ".." then
          return fail("unsafe_zip", name)
        end
      end
    end
    if entries == 0 then return fail("bad_zip", "TAR") end
    local avail = free_bytes(job.ports_dir)
    if avail and avail < unpacked + job.margin then
      return fail("no_space", string.format("%d|%d", unpacked + job.margin, avail))
    end
    send({ t = "phase", phase = "extract", total = entries })
    local h = io.popen("tar -xv" .. TARF .. "f " .. shq(ZIP) .. " -C " .. shq(STAGE) .. " 2>&1; echo __PHX:$?")
    local count, code, lastpct = 0, nil, -1
    local errlines = {}
    if h then
      for line in h:lines() do
        local c = line:match("^__PHX:(%d+)")
        if c then
          code = tonumber(c)
        else
          if line:lower():find("^tar:") then errlines[#errlines + 1] = line else count = count + 1 end
          local pct = math.floor(math.min(count, entries) / entries * 100)
          if pct ~= lastpct then
            send({ t = "progress", phase = "extract", done = math.min(count, entries), total = entries })
            lastpct = pct
          end
          if count % 25 == 0 and check_cancel() then break end
        end
      end
      h:close()
    end
    if cancelled then return cancel_done() end
    if code ~= 0 then
      local detail = errlines[1] or (L("codigo ") .. tostring(code))
      if detail:find("No space") then return fail("no_space", "") end
      return fail("bad_zip", detail)
    end
  else
    -- RAR / 7z: extrator 7-Zip (incluso no hub) ou o do sistema
    local ok7, err7 = extract_7z(fmt == "zip7" and "zip" or fmt)
    if not ok7 then return end
  end

  -- 6) analise da estrutura ------------------------------------------------
  send({ t = "phase", phase = "analyze" })
  local JUNK = { ["__macosx"] = true, [".ds_store"] = true, ["thumbs.db"] = true, ["desktop.ini"] = true }

  local function list(dir)
    local items = {}
    local out = capture("cd " .. shq(dir) .. " && for f in * .[!.]* ..?*; do "
      .. "[ -e \"$f\" ] || [ -L \"$f\" ] || continue; "
      .. "if [ -d \"$f\" ] && [ ! -L \"$f\" ]; then echo \"D:$f\"; else echo \"F:$f\"; fi; done")
    for line in out:gmatch("[^\n]+") do
      local kind, name = line:match("^([DF]):(.+)$")
      if name and not JUNK[lower(name)] then
        items[#items + 1] = { name = name, dir = (kind == "D") }
      end
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    return items
  end
  local function has_script(items)
    for _, it in ipairs(items) do
      if not it.dir and lower(it.name):match("%.sh$") then return true end
    end
    return false
  end

  -- Remove pastas "embrulho" para nao criar diretorios duplicados:
  --   roms/ports/Jogo.sh  ->  Jogo.sh
  --   ports/Jogo.sh       ->  Jogo.sh
  --   Jogo/Jogo.sh + Jogo/jogo/  ->  Jogo.sh + jogo/   (so se nao houver .sh na raiz)
  local root = STAGE
  for _ = 1, (job.mode == "extract" and 0 or 4) do
    local items = list(root)
    if #items == 1 and items[1].dir then
      local n = lower(items[1].name)
      local inner = root .. "/" .. items[1].name
      if n == "roms" or n == "roms2" or n == "ports" then
        root = inner
      elseif not has_script(items) and has_script(list(inner)) then
        root = inner
      else
        break
      end
    else
      break
    end
  end

  local items = list(root)
  if #items == 0 then return fail("empty_pkg") end

  -- porthub.txt (creditos do port: desenvolvedor, grupo, versao...) ao lado do
  -- .sh: o hub le e guarda dentro da pasta do jogo, para nao ficar solto na
  -- pasta ports (cada port traria o seu e um apagaria o do outro)
  local porthub_txt
  if job.mode ~= "extract" then
    local keep = {}
    local dirs = {}
    for _, it in ipairs(items) do if it.dir then dirs[#dirs + 1] = it.name end end
    for _, it in ipairs(items) do
      if not it.dir and lower(it.name) == "porthub.txt" then
        porthub_txt = read_all(root .. "/" .. it.name)
        if #dirs == 1 then
          sh("mv -f " .. shq(root .. "/" .. it.name) .. " " .. shq(root .. "/" .. dirs[1] .. "/porthub.txt"))
        else
          os.remove(root .. "/" .. it.name)
        end
        log("porthub.txt encontrado no pacote")
      else
        keep[#keep + 1] = it
      end
    end
    items = keep
  end
  if job.mode ~= "extract" and not has_script(items) and not job.allow_no_script then
    return fail("no_script")
  end

  -- Itens protegidos (PortMaster, o proprio hub, gamelist.xml) sao ignorados
  local install, skipped = {}, {}
  for _, it in ipairs(items) do
    if job.mode ~= "extract" and job.protected[lower(it.name)] then
      skipped[#skipped + 1] = it.name
    else
      install[#install + 1] = it
    end
  end
  if #install == 0 then return fail("empty_pkg") end

  -- 7) conflitos com o que ja esta instalado ------------------------------
  local conflicts = {}
  for _, it in ipairs(install) do
    if sh("test -e " .. shq(job.ports_dir .. "/" .. it.name) .. " -o -L " .. shq(job.ports_dir .. "/" .. it.name)) then
      conflicts[#conflicts + 1] = it.name
      it.exists = true
    end
  end
  if #conflicts > 0 and job.preapproved then
    log("substituicao ja confirmada pelo usuario:", table.concat(conflicts, ", "))
  elseif #conflicts > 0 then
    send({ t = "confirm", items = conflicts })
    local answer
    while answer == nil do
      local m = IN:demand(0.5)
      if m then
        if m.t == "answer" then answer = m.yes and true or false
        elseif m.t == "cancel" then answer = false end
      end
    end
    if not answer then return cancel_done() end
  end

  -- 8) instalacao -------------------------------------------------------------
  send({ t = "phase", phase = "install", total = #install })
  local installed = {}
  for i, it in ipairs(install) do
    local src = root .. "/" .. it.name
    local dst = job.ports_dir .. "/" .. it.name
    local okmv
    if it.exists and it.dir and sh("test -d " .. shq(dst) .. " -a ! -L " .. shq(dst)) then
      -- Atualizacao: mescla, mantendo arquivos extras do usuario (saves, dados do jogo)
      okmv = sh("cp -a " .. shq(src) .. "/. " .. shq(dst) .. "/ 2>/dev/null || cp -rf "
        .. shq(src) .. "/. " .. shq(dst) .. "/")
    else
      if it.exists then sh("rm -rf " .. shq(dst)) end
      okmv = sh("mv -f " .. shq(src) .. " " .. shq(dst))
    end
    if not okmv then
      return fail("install_failed", it.name)
    end
    installed[#installed + 1] = it.name
    send({ t = "progress", phase = "install", done = i, total = #install })
  end

  -- scripts executaveis
  for _, name in ipairs(installed) do
    if lower(name):match("%.sh$") then
      sh("chmod +x " .. shq(job.ports_dir .. "/" .. name) .. " 2>/dev/null")
    end
  end
  -- RAR/7z feitos no Windows nao guardam a permissao de execucao:
  -- devolve +x aos scripts .sh e aos binarios ELF dentro das pastas do port
  if fmt ~= "zip" and job.mode ~= "extract" then
    for _, name in ipairs(installed) do
      local d = job.ports_dir .. "/" .. name
      if sh("test -d " .. shq(d) .. " -a ! -L " .. shq(d)) then
        -- pastas precisam de permissao de acesso (x) para o usuario do console
        sh("find " .. shq(d) .. " -type d -exec chmod u+rwx,go+rx {} + 2>/dev/null")
        sh("find " .. shq(d) .. " -type f \\( -name '*.sh' -o ! -name '*.*' -o -name '*.bin' -o -name '*.aarch64' -o -name '*.arm64' -o -name '*.elf' \\) "
          .. "-exec sh -c 'for f; do case \"$f\" in *.sh) chmod +x \"$f\";; *) [ \"$(head -c 4 \"$f\" 2>/dev/null)\" = \"$(printf \"\\177ELF\")\" ] && chmod +x \"$f\";; esac; done' sh {} + 2>/dev/null")
      end
    end
  end
  sh("sync")

  -- 9) limpeza (remove o ZIP temporario e a pasta de trabalho) ----------------
  cleanup()
  local deleted = false
  if job.local_file and job.delete_source then
    deleted = os.remove(job.local_file) and true or false
    -- arquivo em partes: as outras partes saem junto
    for _, ptn in ipairs(job.parts or {}) do
      if ptn ~= job.local_file then os.remove(ptn) end
    end
    log(deleted and L("arquivo compactado excluido:") or L("nao foi possivel excluir:"), job.local_file)
  end
  log("instalado:", table.concat(installed, ", "))
  -- origem: a senha dos grupos de ports e o proprio nome do grupo
  local source
  if PWD then
    for _, g in ipairs(job.groups or {}) do if g == PWD then source = g end end
  end
  send({ t = "done", entries = installed, skipped = skipped, deleted = deleted, source = source, porthub = porthub_txt })
end

local okrun, err = pcall(run)
if not okrun then
  log("falha interna:", err)
  pcall(cleanup)
  send({ t = "error", code = "internal", detail = tostring(err) })
end
