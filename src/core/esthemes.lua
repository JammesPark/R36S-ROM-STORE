-- =============================================================================
--  Loja de Temas do EmulationStation (Ferramentas de sistema)
--  Catalogo JSON separado do app: link em config.lua (C.ES_THEMES_URL) ou em
--  <pasta do app>/es_themes_url.txt. Sem link, usa a copia que acompanha o app
--  (catalog/es_themes.json). O ultimo catalogo online fica em cache.
--  Instalacao: thread propria (threads/estheme_thread.lua), com confirmacao.
-- =============================================================================
local L = require("lib.i18n").L
local C = require("config")
local U = require("lib.util")
local json = require("lib.json")
local Fetcher = require("core.fetcher")
local OS = require("core.osdetect")
local Scan = require("core.esthemes_scan")
local Gal = require("core.esgallery")
local Unified = require("core.esthemes_unified")

local M = { themes = {}, systems = {}, installed = {}, source = "nenhum" }
local CACHE = "es_themes_cache.json"
local INSTALLED = "es_themes_installed.json"

function M.catalog_url()
  local s = U.read_file(C.APP_DIR .. "/es_themes_url.txt")
  if s then
    s = U.trim(s:match("^[^\r\n]*") or "")
    if s:match("^https?://") then return s end
  end
  if C.ES_THEMES_URL and C.ES_THEMES_URL:match("^https?://") then return C.ES_THEMES_URL end
  return nil
end

local VALID_STATUS = { testado = true, compativel = true, experimental = true, incompativel = true, incompatible = true, no = true }

local function parse(text)
  local d = json.decode(text or "")
  if type(d) ~= "table" or type(d.themes) ~= "table" then return nil, L("catálogo inválido") end
  local list = {}
  for _, t in ipairs(d.themes) do
    -- so entra tema com link direto http(s), pasta segura e compatibilidade declarada
    if type(t) == "table" and type(t.id) == "string" and type(t.name) == "string"
        and type(t.download_url) == "string" and t.download_url:match("^https?://")
        and type(t.folder) == "string" and t.folder:match("^[%w%._%-]+$") and t.folder ~= "." and t.folder ~= ".."
        and type(t.compat) == "table" then
      local compat = {}
      for os_id, st in pairs(t.compat) do
        if VALID_STATUS[st] then compat[os_id] = st end
      end
      t.compat = compat
      t.slug = "estheme-" .. U.slug(t.id)
      t.cover = type(t.preview) == "string" and t.preview or ""
      list[#list + 1] = t
    end
  end
  return { themes = list, systems = type(d.systems) == "table" and d.systems or {}, updated = d.updated or "",
    legend = d.status_legend or {}, weight_legend = d.weight_legend or {} }
end

local function apply(res, source)
  M.base, M.systems, M.updated, M.source = res.themes, res.systems, res.updated, source
  M.weight_legend = res.weight_legend
  M.merge()
end

-- ---------------------------------------------------------------------------
-- Catalogo do hub + fontes do ThemeMaster (galeria e colecoes do GitHub).
-- O catalogo do hub vem primeiro (tem dados conferidos); a galeria acrescenta a
-- compatibilidade por tamanho de tela e os temas que faltam; as colecoes entram
-- por ultimo, sem repetir nenhum repositorio.
local GAL_COMPAT = { arkos = "experimental", darkos = "experimental", darkosre = "experimental" }
local COLL_COMPAT = {} -- coleção GitHub não comprova compatibilidade com firmware

function M.merge()
  local data = Gal.data or Gal.load_cache() or { gallery = {}, collections = {} }
  local list, seen, ids = {}, {}, {}
  local gal_by = {}
  for _, g in ipairs(data.gallery or {}) do gal_by[(g.owner .. "/" .. g.repo):lower()] = g end
  for _, th in ipairs(M.base or {}) do
    local key = Scan.repo_of(th.project_url)
    local g = key and gal_by[key]
    th.res = g and g.res or (th.resolution and { [th.resolution] = "yes" } or {})
    th.src = g and "catalog+gallery" or "catalog"
    if key then seen[key] = true end
    ids[th.id] = true
    list[#list + 1] = th
  end
  local function new_id(repo, owner)
    local id = ids[repo] and (owner .. "-" .. repo) or repo
    ids[id] = true
    return id
  end
  for _, g in ipairs(data.gallery or {}) do
    local key = (g.owner .. "/" .. g.repo):lower()
    if not seen[key] then
      seen[key] = true
      local id = new_id(g.repo, g.owner)
      local okres = {}
      for _, sz in ipairs(Gal.SIZES) do if g.res[sz] == "yes" then okres[#okres + 1] = sz end end
      list[#list + 1] = { id = id, name = g.name, author = g.owner, project_url = g.url,
        download_url = g.url .. "/archive/HEAD.zip", folder = g.repo, preview = g.preview, cover = g.preview or "",
        slug = "estheme-" .. U.slug(id), compat = GAL_COMPAT, res = g.res, src = "gallery",
        description = string.format(L("Tema de EmulationStation por %s, da galeria OGA (a mesma do ThemeMaster). Funciona em: %s."),
          g.owner, #okres > 0 and table.concat(okres, ", ") or L("nenhuma tela confirmada")) }
    end
  end
  for _, user in ipairs(Gal.collections(M.tm)) do
    for _, r in ipairs((data.collections or {})[user] or {}) do
      local key = (r.owner .. "/" .. r.repo):lower()
      if not seen[key] then
        seen[key] = true
        local id = new_id(r.repo, r.owner)
        local name = r.repo:gsub("^es%-theme%-", ""):gsub("[_%-]+", " ")
        list[#list + 1] = { id = id, name = name, author = r.owner, project_url = r.url,
          download_url = r.url .. "/archive/" .. (r.branch and ("refs/heads/" .. r.branch) or "HEAD") .. ".zip",
          folder = r.repo, cover = "", slug = "estheme-" .. U.slug(id), compat = COLL_COMPAT, res = {},
          src = "collection", collection = user, updated = r.updated,
          description = (r.description and (r.description .. "\n") or "")
            .. string.format(L("Repositório da coleção %s do GitHub (modo coleções do ThemeMaster). Sem teste de tela informado."), user) }
      end
    end
  end
  local ok,raw=pcall(love.filesystem.read,"catalog/themegallery_metadata.json")
  local extra=ok and raw and json.decode(raw) or nil
  M.themes=Unified.merge_extra(list,type(extra)=="table" and extra or {})
  local okidx,rawidx=pcall(love.filesystem.read,"catalog/es_theme_preview_index.json")
  local idx=okidx and rawidx and json.decode(rawidx) or nil
  Unified.apply_previews(M.themes,type(idx)=="table" and idx or {})
end

--- atualiza as fontes do ThemeMaster (controlado: no maximo a cada 6 h)
function M.refresh_gallery(force, on_done)
  Gal.refresh(M.tm, force, function(st)
    M.gallery_state = st
    M.merge()
    if M.loc then M.match() end
    if on_done then on_done(st) end
  end)
end

function M.gallery_time() return Gal.data and Gal.data.time end
function M.has_gallery() return Gal.data and type(Gal.data.gallery) == "table" and #Gal.data.gallery > 0 end

function M.load_installed()
  local ok, text = pcall(love.filesystem.read, INSTALLED)
  local d = ok and text and json.decode(text) or nil
  M.installed = type(d) == "table" and d or {}
end

local function save_installed()
  pcall(love.filesystem.write, INSTALLED, json.encode(M.installed))
end

--- carrega o catalogo: online (se configurado) > cache > copia do app
function M.load(on_done, force)
  M.load_installed()
  local url = M.catalog_url()
  local function local_fallback()
    local okc, ctext = pcall(love.filesystem.read, CACHE)
    local res = okc and ctext and parse(ctext)
    if res and url then apply(res, "cache"); return end
    local okb, btext = pcall(love.filesystem.read, "catalog/es_themes.json")
    res = okb and btext and parse(btext)
    if res then apply(res, "embutido") else M.base, M.source = {}, "nenhum"; M.merge() end
  end
  local_fallback()
  if not url then M.online = "none"; if on_done then on_done(true) end return end
  -- consulta controlada: o catalogo online so e buscado de novo depois de 6 h
  -- (ou quando o usuario pede); o cache recente e usado sem internet
  local info = love.filesystem.getInfo(CACHE)
  if not force and M.source == "cache" and info and info.modtime and os.time() - info.modtime < 6 * 3600 then
    M.online = "recent"
    if on_done then on_done(true) end
    return
  end
  M.loading = true
  local out = love.filesystem.getSaveDirectory() .. "/" .. CACHE .. ".dl"
  Fetcher.get("catalog", url, out, function(ok, path)
    M.loading = false
    if ok then
      local text = U.read_file(path)
      os.remove(path)
      local res = parse(text)
      if res then
        apply(res, "online")
        pcall(love.filesystem.write, CACHE, text)
      end
    end
    -- sem internet: continua com o catalogo ja conhecido (nada e apagado)
    M.online = ok and "ok" or "failed"
    if on_done then on_done(ok) end
  end, true)
end

--- temas visiveis para um sistema (somente os declarados compativeis com ele)
function M.for_os(os_id)
  local t = {}
  for _, th in ipairs(M.themes) do
    if os_id and th.compat[os_id] then t[#t + 1] = th end
  end
  return t
end

function M.status_label(st)
  return ({ testado = L("TESTADO"), compativel = L("COMPATÍVEL"), experimental = L("EXPERIMENTAL") })[st] or "?"
end

-- ---------------------------------------------------------------------------
-- Temas que existem no console (reconhecidos no sistema de arquivos)
M.ORIGIN = { firmware = L("do sistema"), user = L("do usuário"), hub = L("R36S ROM STORE"), thememaster = L("ThemeMaster") }

--- varre as pastas de temas e cruza com o catalogo (uma vez ao abrir e depois de
--- instalar, remover ou ativar; nao fica varrendo)
function M.scan(os_id, catalog_dir)
  M.load_installed()
  M.tm = Scan.thememaster(C.PORTS_DIR)
  M.roots = Scan.roots(catalog_dir, M.tm)
  M.loc = Scan.scan(M.roots, os_id, M.installed, M.tm)
  M.active = OS.active_theme()
  M.active_loc = M.active and M.loc.by_folder[M.active] or nil
  M.match()
end

function M.match()
  M.local_of = {}
  local used = {}
  local by_repo, by_hub = {}, {}
  for _, loc in ipairs(M.loc and M.loc.list or {}) do
    loc.theme = nil
    if loc.repo then by_repo[loc.repo] = by_repo[loc.repo] or loc end
    if loc.hub_id then by_hub[loc.hub_id] = loc end
  end
  -- 1) marcador/registro do hub  2) repositorio do .git  3) nome da pasta com theme.xml
  local passes = {
    function(th) return by_hub[th.id], "hub" end,
    function(th) local r = Scan.repo_of(th.project_url); return r and by_repo[r], "git" end,
    function(th) local l = M.loc and M.loc.by_folder[th.folder]; return (l and (l.xml_ok or not l.readable)) and l or nil, "folder" end,
  }
  for _, pass in ipairs(passes) do
    for _, th in ipairs(M.themes) do
      if not M.local_of[th.id] then
        local loc, how = pass(th)
        if loc and not used[loc] then
          used[loc] = true
          loc.theme, loc.match = th, how
          M.local_of[th.id] = loc
        end
      end
    end
  end
  M.local_only = {}
  for _, loc in ipairs(M.loc and M.loc.list or {}) do
    if not loc.theme then M.local_only[#M.local_only + 1] = loc end
  end
end

function M.local_for(th) return M.local_of and M.local_of[th.id] or nil end

--- "active" | "installed" | "incomplete" | "available" | "unverified"
function M.state_loc(loc)
  if not loc.readable then return "unverified" end
  if loc.incomplete then return "incomplete" end
  if M.active and loc.folder == M.active then return "active" end
  return "installed"
end

function M.state(th)
  local loc = M.local_for(th)
  if loc then return M.state_loc(loc), loc end
  if M.loc and #M.loc.unreadable > 0 then return "unverified" end
  return "available"
end

M.STATE_LABEL = { active = L("ATIVO"), installed = L("INSTALADO"), incomplete = L("INSTALAÇÃO INCOMPLETA"),
  available = L("DISPONÍVEL"), unverified = L("NÃO VERIFICADO") }
M.STATE_SHORT = { active = L("ATIVO"), installed = L("INSTALADO"), incomplete = L("INCOMPLETO"),
  available = L("DISPONÍVEL"), unverified = L("NÃO VERIFICADO") }
M.STATE_COLOR = { active = "accent", installed = "green", incomplete = "red", available = "faint", unverified = "yellow" }

--- ha versao mais nova no catalogo? (so quando a data instalada e conhecida:
--- registro do hub ou do ThemeMaster, que guarda a data do commit)
-- Upstream revisions are resolved from the actual archive ref, not an estimated date.
M.remote_revisions={}
M.revision_seq=0
M.update_revision=0
local function valid_sha(s) return type(s)=="string" and #s==40 and not s:find("[^%x]") end
function M.revision_request(th)
  local owner,repo=(th.project_url or ""):match("^https://github%.com/([%w_.%-]+)/([%w_.%-]+)/?$")
  if not owner then return end
  local base="https://github.com/"..owner.."/"..repo.."/archive/"
  local url=th.download_url or ""
  if url:sub(1,#base):lower()~=base:lower() then return end
  local ref=url:sub(#base+1):match("^(.+)%.zip$")
  if not ref then return end
  ref=ref:gsub("^refs/heads/","")
  if not ref:match("^[%w_.%/-]+$") or valid_sha(ref) then return end
  local encoded=ref:gsub("/", "%%2F")
  return "https://api.github.com/repos/"..owner.."/"..repo.."/commits?sha="..encoded.."&per_page=1",base
end
function M.decode_revision(raw,base)
  local ok,list=pcall(json.decode,raw or "")
  local item=ok and type(list)=="table" and list[1]
  local date=item and item.commit and item.commit.committer and item.commit.committer.date
  if not item or not valid_sha(item.sha) or type(date)~="string" or not date:match("^%d%d%d%d%-%d%d%-%d%dT") then return end
  return {sha=item.sha:lower(),date=date,url=base..item.sha..".zip",checked=os.time()}
end
function M.fetch_revision(th,cb,force)
  local url,base=M.revision_request(th)
  if not url then cb(nil);return end
  local key=Unified.key(th)
  local prev=M.remote_revisions[key]
  if not force and prev and prev.source==th.download_url and os.time()-prev.checked<1800 then cb(prev);return end
  M.revision_seq=M.revision_seq+1
  local out=love.filesystem.getSaveDirectory().."/theme-revision-"..M.revision_seq..".json"
  Fetcher.get("theme_revision",url,out,function(ok,path)
    local raw=ok and path and U.read_file(path) or nil
    if path then os.remove(path) end
    local rev=M.decode_revision(raw,base)
    if rev then rev.source=th.download_url;M.remote_revisions[key]=rev
    else M.remote_revisions[key]=nil end
    cb(rev)
  end,true)
end
function M.installed_revision(th,loc)
  loc=loc or M.local_for(th)
  if not loc then return end
  if loc.origin=="hub" then
    local rec=M.installed[loc.hub_id or th.id]
    if rec and valid_sha(rec.commit) then return rec.commit,rec.version end
  elseif loc.tm_version then
    local date=loc.tm_version:match("^(%d%d%d%d%-%d%d%-%d%d)")
    return nil,date
  end
end
function M.update_available(th,loc)
  loc=loc or M.local_for(th)
  if not loc or not loc.readable or loc.incomplete then return false end
  local sha,date=M.installed_revision(th,loc)
  local rev=M.remote_revisions[Unified.key(th)]
  local have=sha and sha:sub(1,8) or date
  if not rev or rev.source~=th.download_url then return false,have end
  if sha then return sha:lower()~=rev.sha,have,rev end
  if date then return rev.date:sub(1,10)>date:sub(1,10),have,rev end
  return false,nil,rev
end
function M.update_list()
  local list={}
  for _,th in ipairs(M.themes or {}) do
    local loc=M.local_for(th)
    if loc and loc.origin~="firmware" and M.update_available(th,loc) then list[#list+1]=th end
  end
  return list
end
function M.check_updates(force,cb)
  if M.checking_updates then return false end
  local targets={}
  for _,th in ipairs(M.themes or {}) do
    local loc=M.local_for(th)
    if loc and loc.readable and not loc.incomplete and loc.origin~="firmware" and M.revision_request(th) then targets[#targets+1]=th end
  end
  M.checking_updates=true
  local i,failed=0,0
  local function next_one()
    i=i+1
    if i>#targets then
      M.checking_updates=false;M.update_revision=M.update_revision+1
      M.last_check=os.time()
      local count=#M.update_list()
      if count>0 then M.notice_count=count end
      if cb then cb(count,failed,#targets) end
      return
    end
    M.fetch_revision(targets[i],function(rev)
      if not rev then failed=failed+1 end
      next_one()
    end,force)
  end
  next_one()
  return true
end
function M.download_snapshot(th,rev)
  local copy={};for k,v in pairs(th) do copy[k]=v end
  if rev and rev.source==th.download_url and valid_sha(rev.sha) then
    copy.download_url=rev.url;copy.installed_commit=rev.sha;copy.installed_date=rev.date
    if copy.download_url~=th.download_url then copy.size=nil;copy.sha256=nil end
  else copy.installed_commit=nil;copy.installed_date=nil end
  return copy
end
function M.queue_install(th,dir,os,folder,size,confirmed,existed,cb)
  local D=require("core.downloads")
  if D.pending("estheme:"..Unified.key(th)) then cb(false,L("Tema já está na Central de Downloads."));return end
  if not Unified.can_install(th,os,size) then cb(false,L("Tema incompatível ou link indisponível."));return end
  M.fetch_revision(th,function(rev)
    cb(D.enqueue_theme(M.download_snapshot(th,rev),dir,os,folder,size,confirmed,existed))
  end,false)
end

--- compatibilidade com o codigo antigo da tela
function M.is_installed(th)
  local loc = M.local_for(th)
  return loc ~= nil, loc
end

--- pode remover? devolve true ou false, motivo
function M.can_remove(loc)
  if not loc then return false, L("Tema não encontrado no console.") end
  if loc.origin == "firmware" then return false, L("Este tema acompanha o sistema do console e não é removido pelo hub.") end
  if M.active and loc.folder == M.active then return false, "active" end
  if loc.is_link then return false, L("A pasta do tema é um link: não dá para confirmar a quem pertencem os arquivos. Nada foi apagado.") end
  if type(loc.folder)~="string" or loc.folder=="" or loc.folder=="." or loc.folder==".." or loc.folder:find("[/%c]") then return false, L("Nome de pasta inválido: nada foi apagado.") end
  if not loc.readable then return false, L("Sem permissão para ler a pasta do tema: nada foi apagado.") end
  if not (loc.xml_ok or loc.marker) then
    return false, L("A pasta não tem theme.xml: não dá para confirmar que ela é só de um tema. Nada foi apagado.")
  end
  return true
end

--- remove um tema (com as conferencias acima e de caminho/links)
function M.remove(loc)
  local okr, why = M.can_remove(loc)
  if not okr then return false, why end
  if U.exec_ok("test -L "..U.shq(loc.path)) then return false,L("A pasta do tema é um link: nada foi apagado.") end
  local real = U.trim(U.capture("readlink -f -- " .. U.shq(loc.path) .. " 2>/dev/null") or "")
  local base = loc.root_real or ""
  if real == "" or base == "" or real ~= base.."/"..loc.folder or real:match("^(.*)/[^/]+$") ~= base then
    return false, L("Caminho do tema fora da pasta de temas: nada foi apagado.")
  end
  -- A directory may contain symlinks to shared assets. rm -rf without a
  -- trailing slash unlinks entries, never follows symlinks. Reject mount
  -- points below the directory and re-check the exact root before deletion.
  local mounts=U.read_file("/proc/self/mountinfo") or ""
  for line in mounts:gmatch("[^\n]+") do
    local mount=line:match("^%S+ %S+ %S+ %S+ (%S+)")
    if mount then
      mount=mount:gsub("\\(%d%d%d)",function(n)return string.char(tonumber(n,8) or 63)end)
      if mount==real or mount:sub(1,#real+1)==real.."/" then
        return false,L("A pasta contém um ponto de montagem: nada foi apagado.")
      end
    end
  end
  if type(OS.active_theme)=="function" and OS.active_theme()==loc.folder then return false,L("Tema em uso: ative outro tema antes de remover.") end
  if U.exec_ok("test -L "..U.shq(loc.path)) or U.trim(U.capture("readlink -f -- "..U.shq(loc.path).." 2>/dev/null") or "")~=real then
    return false,L("O caminho do tema mudou: nada foi apagado.")
  end
  if not U.exec_ok("rm -rf -- " .. U.shq(real)) or U.exec_ok("test -e " .. U.shq(real)) then
    return false, L("Não foi possível apagar a pasta do tema.")
  end
  if loc.hub_id and M.installed[loc.hub_id] then M.installed[loc.hub_id] = nil; save_installed() end
  for id, rec in pairs(M.installed) do
    if type(rec) == "table" and rec.folder == loc.folder and (not rec.dir or rec.dir==loc.root or rec.dir==loc.root_real) then M.installed[id] = nil; save_installed() end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Ativacao pelo mecanismo do proprio EmulationStation: ThemeSet do es_settings.cfg.
-- O ES guarda as configuracoes na memoria enquanto roda, entao o hub NAO edita o
-- arquivo com ele aberto: o pedido fica em conf/.es_theme e o launcher do hub,
-- depois que o app fecha, para o EmulationStation, troca o ThemeSet (com backup),
-- confere e inicia o EmulationStation de novo.
local PENDING = "es_theme_pending.json"

function M.request_activate(loc)
  if not loc or not loc.folder:match("^[%w%._%-]+$") or loc.folder=="." or loc.folder==".." or loc.is_link then return false, L("Nome de pasta inválido.") end
  if not loc.xml_ok then return false, L("O tema não tem theme.xml válido: ativar deixaria o EmulationStation sem tema.") end
  if loc.incomplete then return false, L("O tema está incompleto (arquivos ausentes). Reinstale antes de ativar.") end
  os.execute("mkdir -p " .. U.shq(C.APP_DIR .. "/conf") .. " 2>/dev/null")
  if not U.write_file(C.APP_DIR .. "/conf/.es_theme", loc.folder .. "\n") then
    return false, L("Não foi possível gravar o pedido (pasta do app somente leitura?).")
  end
  pcall(love.filesystem.write, PENDING, json.encode({ folder = loc.folder, prev = M.active, time = os.time() }))
  return true
end

--- na abertura: a ativacao pedida antes funcionou? (confere o ThemeSet de verdade)
function M.check_pending()
  local okr, text = pcall(love.filesystem.read, PENDING)
  if not okr or not text then return nil end
  pcall(love.filesystem.remove, PENDING)
  local d = json.decode(text)
  if type(d) ~= "table" or not d.folder then return nil end
  return OS.active_theme() == d.folder and "ok" or "fail", d.folder
end

-- ---------------------------------------------------------------------------
-- Instalacao (thread)
function M.start_install(th, dir, os_id, folder, size, confirmed_unknown, expected_existing)
  size = size or "640x480"
  if not Unified.can_install(th,os_id,size) then return false,L("Tema incompatível ou link indisponível.") end
  if Unified.needs_confirmation(th,os_id,size) and confirmed_unknown~=true then
    return false,L("Compatibilidade não verificada: confirme antes de instalar.")
  end
  if M.job and not M.job.finished then return false, L("Já existe uma instalação de tema em andamento.") end
  local out, inn = "hub_esth_out", "hub_esth_in"
  love.thread.getChannel(out):clear(); love.thread.getChannel(inn):clear()
  folder = folder or th.folder
  if type(folder)~="string" or not folder:match("^[%w%._%-]+$") or folder=="." or folder==".." then return false,L("Nome de pasta do tema inválido.") end
  if type(dir)~="string" or dir=="" or not U.exec_ok("test -d "..U.shq(dir)) then return false,L("A pasta de temas não existe.") end
  if U.exec_ok("test -L "..U.shq(dir.."/"..folder)) then return false,L("A pasta do tema é um link.") end
  if expected_existing==false and U.exec_ok("test -e "..U.shq(dir.."/"..folder)) then
    return false,L("A pasta do tema apareceu enquanto aguardava. Confirme uma nova instalação.")
  end
  M.job = { theme = th, dir = dir, os = os_id, folder = folder, phase = "download", done = 0, total = th.size, speed = 0,
    out = love.thread.getChannel(out), inn = love.thread.getChannel(inn) }
  M.job.thread = love.thread.newThread("threads/estheme_thread.lua")
  M.job.thread:start({ lang = require("lib.i18n").lang, url = th.download_url, dest = dir, size = th.size or 0,
    sha256 = type(th.sha256) == "string" and th.sha256:lower() or "", id = th.id, folder = folder,
    tmp_dir = C.TMP_DIR, fetch_sh = C.FETCH_SH, margin = C.SPACE_MARGIN, out = out, inn = inn })
  return true
end

function M.cancel()
  if M.job and not M.job.finished and M.job.phase == "download" then M.job.inn:push("cancel") end
end

function M.update()
  local j = M.job
  if not j or j.finished then return end
  local e = j.thread:getError()
  if e then j.finished, j.ok, j.error = true, false, L("Erro interno: ") .. tostring(e); return end
  local m = j.out:pop()
  while m do
    if m.t == "phase" then j.phase = m.phase; if m.total then j.total = m.total end
    elseif m.t == "progress" then
      local now = love.timer.getTime()
      if j.last_t and now > j.last_t then
        local inst = (m.done - (j.last_done or 0)) / (now - j.last_t)
        j.speed = j.speed > 0 and (j.speed * 0.7 + inst * 0.3) or inst
      end
      j.last_t, j.last_done = now, m.done
      j.done = m.done
      if m.total and m.total > 0 then j.total = m.total end
    elseif m.t == "done" then
      j.finished, j.ok, j.backup = true, true, m.backup
      M.installed[j.theme.id] = { folder = j.folder, dir = j.dir, date = os.date("%d/%m/%Y %H:%M"),
        version = j.theme.installed_date or "", commit = j.theme.installed_commit, backup = j.backup, os = j.os, name = j.theme.name }
      save_installed()
    elseif m.t == "error" then j.finished, j.ok, j.error = true, false, m.msg
    elseif m.t == "cancelled" then j.finished, j.ok, j.cancelled = true, false, true end
    m = j.out:pop()
  end
end

--- desinstala SOMENTE temas instalados pelo app. Devolve ok, mensagem
function M.uninstall(th)
  local ok, rec = M.is_installed(th)
  if not ok then return false, L("Este tema não foi instalado pelo R36S ROM STORE.") end
  if not rec.folder:match("^[%w%._%-]+$") then return false, L("Registro de instalação inválido.") end
  local active = OS.active_theme()
  if active and active == rec.folder then
    return false, L("Este tema está em uso no EmulationStation. Escolha outro tema no EmulationStation antes de desinstalar.")
  end
  local path = rec.dir .. "/" .. rec.folder
  -- confere que o caminho real continua dentro da pasta de temas
  local real = U.trim(U.capture("readlink -f -- " .. U.shq(path) .. " 2>/dev/null") or "")
  local real_dir = U.trim(U.capture("readlink -f -- " .. U.shq(rec.dir) .. " 2>/dev/null") or "")
  if real == "" or real_dir == "" or real:sub(1, #real_dir + 1) ~= real_dir .. "/" then
    return false, L("Caminho do tema fora da pasta de temas: nada foi apagado.")
  end
  if not U.exec_ok("rm -rf -- " .. U.shq(real)) then return false, L("Não foi possível apagar a pasta do tema.") end
  M.installed[th.id] = nil
  save_installed()
  return true
end

return M
