-- =============================================================================
--  Catalogo de ports: leitura, validacao e normalizacao do JSON
--  Formato documentado em docs/CATALOGO.md
-- =============================================================================
local L = require("lib.i18n").L
local json = require("lib.json")
local U = require("lib.util")
local C = require("config")
local Cats = require("core.categories")

local Catalog = {
  ports = {},          -- lista normalizada
  by_id = {},
  categories = {},     -- { {id=, name=, count=} }
  source = "none",     -- "online" | "cache" | "local" | "example" | "none"
  title = "",
  updated = "",
  warnings = {},
  remote_url = nil,
  remote_state = "idle", -- idle | loading | ok | failed
  remote_error = "",
  news = {},
}

-- A edicao Experimental utiliza exclusivamente catalogo proprio local.
function Catalog.provider() return "r36s_own" end
function Catalog.catalog_source() return "r36s_own" end
function Catalog.catalog_source_label() return "R36S ROMS STORE — Experimental" end

--- texto do port no idioma atual (description/short); sem traducao, usa o original
function Catalog.text(p, field)
  local t = p.i18n and p.i18n[require("lib.i18n").lang]
  local v = t and t[field]
  if v and v ~= "" then return v end
  return p[field] or ""
end

-- Nomes amigaveis para categorias comuns (quando o catalogo nao define)
local DEFAULT_CAT_NAMES = {
  acao = L("Ação"), aventura = L("Aventura"), plataforma = L("Plataforma"), corrida = L("Corrida"),
  rpg = "RPG", tiro = L("Tiro"), fps = "FPS", puzzle = "Puzzle", estrategia = L("Estratégia"),
  luta = L("Luta"), esporte = L("Esporte"), terror = L("Terror"), metroidvania = "Metroidvania",
  indie = "Indie", classicos = L("Clássicos"), ferramentas = L("Ferramentas"), outros = L("Outros"),
}

local function str(v)
  if v == nil then return "" end
  if type(v) == "number" then
    if v % 1 == 0 then return string.format("%d", v) end
    return tostring(v)
  end
  if type(v) ~= "string" then return "" end
  return U.safe_utf8(U.trim(v))
end

--- Gera a URL a partir dos campos do catalogo (link completo ou caminho local)
local function build_url(t, direct_keys)
  for _, k in ipairs(direct_keys) do
    local v = str(t[k])
    if v ~= "" then
      if v:match("^https?://") then return (v:gsub(" ", "%%20")) end
      return v -- caminho local relativo (capas)
    end
  end
  return ""
end

local function normalize_port(raw, idx, cat_names)
  if type(raw) ~= "table" then return nil, L("item ") .. idx .. L(" nao e objeto") end
  local p = {}
  p.name = str(raw.name or raw.nome or raw.title)
  if p.name == "" then return nil, L("item ") .. idx .. L(" sem nome") end
  p.id = str(raw.id or raw.identificador)
  if p.id == "" then p.id = U.slug(p.name) end
  p.slug = U.slug(p.id)
  p.description = str(raw.description or raw.descricao or raw.desc)
  p.short = str(raw.short or raw.resumo)
  if p.short == "" then
    p.short = p.description:match("^([^\n]+)") or ""
  end
  -- textos opcionais em outros idiomas (description_en, description_es, short_ru...)
  p.i18n = {}
  for _, lang in ipairs({ "en", "es", "ru" }) do
    local d, sh = str(raw["description_" .. lang]), str(raw["short_" .. lang])
    if d ~= "" or sh ~= "" then
      p.i18n[lang] = { description = d, short = sh ~= "" and sh or (d:match("^([^\n]+)") or "") }
    end
  end
  p.version = str(raw.version or raw.versao)
  p.author = str(raw.author or raw.porter or raw.autor)
  p.notes = str(raw.notes or raw.observacoes)
  p.requires_files = raw.requires_files == true or raw.requer_arquivos == true
  p.featured = raw.featured == true or raw.destaque == true
  -- ordem opcional na vitrine EM DESTAQUE (sem ela, vale a ordem do catalogo)
  p.featured_order = tonumber(raw.featured_order or raw.destaque_ordem)
  p.allow_no_script = raw.allow_no_script == true
  -- requisitos para o Verificador de compatibilidade (opcionais; nada e deduzido)
  p.compat = type(raw.compat) == "table" and raw.compat or nil
  p.attr = type(raw.attr) == "table" and raw.attr or nil
  p.pm_name = str(raw.pm_name or raw.portmaster_name)
  -- Novidades (opcionais): datas no formato AAAA-MM-DD
  p.added = str(raw.added or raw.added_at or raw.adicionado_em)
  -- Anuncio de port ainda sem download: data opcional para a aba Em Breve.
  p.announced_at = str(raw.announced_at or raw.anunciado_em)
  p.updated_at = str(raw.updated or raw.updated_at or raw.atualizado_em)
  p.changelog = str(raw.changelog or raw.notas_versao or raw.whats_new)

  local cat = str(raw.category or raw.categoria or raw.genre)
  if cat == "" then cat = "outros" end
  local test_from_cat
  p.category_id, test_from_cat = Cats.resolve(cat)
  if p.category_id == "testes_de_controles" then
    -- os tres testes continuam separados: tipo proprio dentro da categoria unica
    p.test_type = Cats.test_type(str(raw.test_type or raw.tipo_teste or raw.subtype), test_from_cat)
  end
  local official = Cats.BY_ID[p.category_id]
  p.category = official and official.name or cat_names[p.category_id] or DEFAULT_CAT_NAMES[p.category_id] or cat
  p.section = Cats.section_of(str(raw.section or raw.area or raw.type or raw.tipo), p.category_id)
  -- Em ROMs as categorias sao SISTEMAS, nao generos (acao, RPG etc.).
  -- Usa o id publicado pelo catalogo. No caso de formato antigo, aceita
  -- identificacao por plataforma, preservando os filtros de ferramentas.
  if p.section == "games" then
    local sys = str(raw.system_id or raw.system or raw.sistema or raw.platform or raw.plataforma)
    local raw_id = U.slug(str(raw.system_id or raw.system or raw.sistema or raw.category or raw.categoria or sys))
    local chosen = cat_names[raw_id] and raw_id or nil
    if not chosen and sys ~= "" then
      local slug = U.slug(sys)
      if cat_names[slug] then chosen = slug end
      if not chosen then
        for id, name in pairs(cat_names) do
          if U.slug(name) == slug then chosen = id; break end
        end
      end
    end
    p.category_id = chosen or (sys ~= "" and U.slug(sys) or raw_id)
    p.category = cat_names[p.category_id] or (sys ~= "" and sys or cat)
  end

  p.size = U.parse_size(raw.size_bytes or raw.sizeBytes or raw.size or raw.tamanho)
  p.size_label = str(raw.size_label)
  if p.size_label == "" then p.size_label = p.size and U.format_bytes(p.size) or "?" end
  -- se o tamanho veio como texto aproximado ("150 MB"), nao usar para verificacao exata
  p.size_exact = type(raw.size_bytes or raw.sizeBytes or raw.size) == "number"

  p.download_url = build_url(raw, { "download_url", "downloadUrl", "url", "download", "rip_url" })
  -- informacoes extras opcionais (exibidas nos detalhes)
  p.platform = str(raw.platform or raw.plataforma)
  p.origin = str(raw.source or raw.origem)
  p.file_type = str(raw.file_type or raw.formato):upper()
  p.cover = build_url(raw, { "cover", "cover_url", "capa", "image" })
  p.sha256 = str(raw.sha256):lower()
  p.md5 = str(raw.md5):lower()

  p.install_check = {}
  if type(raw.install_check) == "table" then
    for _, v in ipairs(raw.install_check) do
      local s = str(v)
      if s ~= "" and not s:find("%.%.") and s:sub(1, 1) ~= "/" then p.install_check[#p.install_check + 1] = s end
    end
  elseif type(raw.install_check) == "string" and raw.install_check ~= "" then
    p.install_check[1] = str(raw.install_check)
  end
  return p
end

--- Interpreta o texto JSON. Devolve (dados normalizados) ou (nil, erro)
function Catalog.parse(text)
  -- Aceita tabela previamente decodificada pelo leitor ZLIB para evitar
  -- deserializar duas vezes 15 mil registros num console ARM.
  local data,err
  if type(text)=="table" then data=text else data,err=json.decode(text) end
  if data == nil then return nil, L("JSON inválido: ") .. tostring(err) end
  local list, meta = nil, {}
  if type(data) == "table" and data[1] ~= nil then
    list = data                         -- formato simples: lista de ports
  elseif type(data) == "table" then
    meta = data
    list = data.ports or data.games or data.jogos
  end
  if type(list) ~= "table" then return nil, L("o catálogo não tem a lista \"ports\"") end

  local cat_names, cat_order = {}, {}
  if type(meta.categories) == "table" then
    for _, c in ipairs(meta.categories) do
      if type(c) == "table" then
        local id = U.slug(str(c.id or c.name))
        cat_names[id] = str(c.name or c.nome or c.id)
        cat_order[#cat_order + 1] = id
      elseif type(c) == "string" then
        local id = U.slug(c)
        cat_names[id] = str(c)
        cat_order[#cat_order + 1] = id
      end
    end
  end

  local res = { ports = {}, by_id = {}, warnings = {}, title = str(meta.title or meta.titulo),
    updated = str(meta.updated or meta.atualizado), news = {} }
  -- lista opcional de novidades: [{ "id": "...", "type": "new"|"update", "date": "AAAA-MM-DD", "text": "..." }]
  if type(meta.news or meta.novidades) == "table" then
    for _, n in ipairs(meta.news or meta.novidades) do
      if type(n) == "table" and n.id then
        res.news[#res.news + 1] = { id = str(n.id), type = (str(n.type) == "update" or str(n.type) == "atualizacao") and "update" or "new",
          date = str(n.date or n.data), text = str(n.text or n.texto) }
      end
    end
  end
  for i, raw in ipairs(list) do
    local p, perr = normalize_port(raw, i, cat_names)
    if not p then
      res.warnings[#res.warnings + 1] = perr
    elseif res.by_id[p.id] then
      res.warnings[#res.warnings + 1] = L("id repetido ignorado: ") .. p.id
    else
      res.ports[#res.ports + 1] = p
      res.by_id[p.id] = p
    end
  end

  -- A ordem de sistemas vem do catalogo, mesmo os que ainda estao vazios.
  -- As categorias de ferramentas continuam como no projeto original.
  local counts = {}
  for _, p in ipairs(res.ports) do
    local k = p.section .. "|" .. p.category_id
    counts[k] = (counts[k] or 0) + 1
  end
  local cats, seen = {}, {}
  for _, id in ipairs(cat_order) do
    local k = "games|" .. id
    if not seen[k] then
      cats[#cats + 1] = { id=id, name=cat_names[id] or id, section="games", icon="games", count=counts[k] or 0 }
      seen[k] = true
    end
  end
  -- Sistemas adicionais: jogos com plataforma ausente do indice.
  local extra = {}
  for _, p in ipairs(res.ports) do
    if p.section == "games" then
      local k = "games|" .. p.category_id
      if not seen[k] then
        seen[k] = true
        extra[#extra + 1] = { id=p.category_id, name=p.category, section="games", icon="games", count=counts[k] or 0 }
      end
    end
  end
  table.sort(extra, function(a,b) return a.name:lower()<b.name:lower() end)
  for _, c in ipairs(extra) do cats[#cats+1]=c end
  for _, c in ipairs(Cats.LIST) do
    if c.section == "tools" then
      local k = "tools|" .. c.id
      cats[#cats + 1] = { id=c.id, name=c.name, section="tools", icon=c.icon, count=counts[k] or 0 }
      seen[k] = true
    end
  end
  local tool_extra = {}
  for _, p in ipairs(res.ports) do
    if p.section == "tools" then
      local k = "tools|" .. p.category_id
      if not seen[k] then
        seen[k] = true
        tool_extra[#tool_extra + 1] = { id=p.category_id, name=p.category, section="tools", icon="generic", count=counts[k] or 0 }
      end
    end
  end
  table.sort(tool_extra, function(a,b) return a.name:lower()<b.name:lower() end)
  for _, c in ipairs(tool_extra) do cats[#cats+1]=c end
  res.categories = cats
  return res
end

local function apply(res, source)
  Catalog.ports = res.ports
  Catalog.by_id = res.by_id
  Catalog.categories = res.categories
  Catalog.warnings = res.warnings
  Catalog.title = res.title
  Catalog.updated = res.updated
  Catalog.news = res.news or {}
  Catalog.source = source
  for _, w in ipairs(res.warnings) do U.log("catalogo:", w) end
  U.log(string.format("catalogo carregado (%s): %d ports, %d categorias", source, #res.ports, #res.categories))
end

-- Nao ha URL remota nem fallback para o provedor anterior.
function Catalog.get_remote_url() return nil end

function Catalog.load_local()
  Catalog.remote_url = nil
  local own = require("core.own_source")
  local payload, origin_or_err, bytes = own.read()
  if payload then
    local res, err = Catalog.parse(payload)
    if res and #res.ports == #payload.ports then
      -- Aprova a copia apenas depois de validar e normalizar 100% dos itens.
      if origin_or_err == "own-local" then
        if not own.remember(bytes) then
          U.log("catalogo proprio: nao foi possivel gravar backup (leitura continua)")
        end
      elseif origin_or_err == "own-backup" then
        if not own.restore(bytes) then
          U.log("catalogo proprio: backup carregado, mas sem permissao para restaurar original")
        end
      elseif origin_or_err == "own-embedded" then
        if own.restore(bytes) then own.remember(bytes) end
      end
      apply(res, origin_or_err)
      Catalog.remote_state, Catalog.remote_error = "ok", ""
      return true
    end
    origin_or_err = err or "Registros rejeitados ao normalizar"
  end
  Catalog.remote_state = "failed"
  Catalog.remote_error = tostring(origin_or_err or "Catalogo proprio indisponivel")
  U.log("catalogo proprio:", Catalog.remote_error)
  -- Se uma atualizacao falhou durante a sessao, preservar a lista em memoria.
  if #Catalog.ports == 0 then
    Catalog.ports, Catalog.by_id, Catalog.categories = {}, {}, {}
    Catalog.source = "none"
  end
  return false
end

-- API de compatibilidade mantida sem fazer consultas remotas.
function Catalog.on_remote(ok, path)
  if path then os.remove(path) end
  return false, "Edicao Experimental usa somente catalogo proprio"
end

function Catalog.source_label()
  if Catalog.source == "own-local" then return "Catálogo próprio (SD)" end
  if Catalog.source == "own-backup" then return "Catálogo próprio (cópia recuperada)" end
  if Catalog.source == "own-embedded" then return "Catálogo próprio (embutido)" end
  return "Catálogo próprio indisponível"
end

function Catalog.set_provider(provider)
  if provider ~= "r36s_own" then
    return false, "Fonte indisponivel nesta edicao: somente catalogo proprio"
  end
  return true
end

--- Filtra ports. filter = "all" | "installed" | "cat:<id>"
--- section: "games" | "tools" | nil (todas). As areas nunca se misturam.
function Catalog.filter(filter, status_fn, section)
  if filter=="installed" and section=="games" then
    return require("core.rom_installed").list(Catalog)
  end
  local out = {}
  for _, p in ipairs(Catalog.ports) do
    local keep = (section == nil) or (p.section == section)
    if keep and filter == "favs" then
      keep = require("core.favorites").is(p)
    elseif keep and filter == "installed" then
      keep = status_fn and status_fn(p) ~= "none"
    elseif keep and filter and filter:sub(1, 4) == "cat:" then
      keep = p.category_id == filter:sub(5)
    end
    if keep then out[#out + 1] = p end
  end
  if filter == "installed" or filter == "favs" then
    -- inclui os ports do cartao que nao estao no catalogo (contam como jogos)
    local Manifest = require("core.manifest")
    local Fav = require("core.favorites")
    for _, lp in ipairs(Manifest.local_ports(Catalog.ports)) do
      if (section == nil or section == (lp.section or "games")) and (filter == "installed" or Fav.is(lp)) then
        out[#out + 1] = lp
      end
    end
  end
  -- Testes de controles: agrupa pelos tres tipos (analogicos, botoes, completo)
  if filter == "cat:testes_de_controles" then
    local Cats = require("core.categories")
    table.sort(out, function(a, b)
      local ta = Cats.TEST_TYPE_BY_ID[a.test_type or "completo"].order
      local tb = Cats.TEST_TYPE_BY_ID[b.test_type or "completo"].order
      if ta ~= tb then return ta < tb end
      return a.name:lower() < b.name:lower()
    end)
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Selo NOVO: port com "added" (AAAA-MM-DD) nos ultimos NEW_DAYS dias.
-- A data de referencia e a maior entre a data do console e o "added" mais
-- novo do catalogo: assim um relogio atrasado (sem internet) nao some com o
-- selo, e um catalogo antigo nao marca tudo como novo para sempre.
Catalog.NEW_DAYS = 7
local function day_num(s)
  local y, m, d = tostring(s or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if not y then return nil end
  return math.floor(os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 }) / 86400)
end
local new_ref_cache
local function new_ref()
  local n, today = #(Catalog.ports or {}), os.date("%Y-%m-%d")
  local c = new_ref_cache
  if c and c.n == n and c.day == today and c.ports == Catalog.ports then return c.ref end
  local ref = day_num(today) or 0
  for _, p in ipairs(Catalog.ports or {}) do
    local a = day_num(p.added)
    if a and a > ref then ref = a end
  end
  new_ref_cache = { n = n, day = today, ports = Catalog.ports, ref = ref }
  return ref
end
-- Data numerica usada no modo Recentes; campos invalidos ficam no fim.
function Catalog.added_day(p)
  if not p then return nil end
  return day_num(p.added)
end

function Catalog.is_new(p)
  if not p or p.builtin then return false end
  local a = day_num(p.added)
  if not a then return false end
  local diff = new_ref() - a
  return diff >= 0 and diff <= Catalog.NEW_DAYS
end

return Catalog
