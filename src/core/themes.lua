-- =============================================================================
--  Temas visuais (Configuracoes > Temas)
--  Cada tema e SO DADOS (theme.json: cores, botoes, estilo + preview.png).
--  Nenhum codigo e executado a partir de um tema.
--    - Temas que acompanham o app:  themes/<id>/            (dentro do game.love)
--    - Temas baixados (futuro):     <dados do app>/user_themes/<id>/
--      (fora dos arquivos do app; instalar/remover nunca toca nos temas inclusos)
--  O tema escolhido fica salvo em theme.txt (pasta de dados do app).
-- =============================================================================
local L = require("lib.i18n").L
local C = require("config")
local U = require("lib.util")
local json = require("lib.json")
local T = require("ui.theme")
local Prefs=require("core.prefs")
local Schemes=require("ui.color_schemes")

local M = { list = {}, current = "neongrid", DEFAULT = "neongrid" }
-- Edicao Experimental: somente Tema Padrao e Neon Grid sao permitidos.
-- Os outros temas nao sao mais carregados nem exibidos no seletor.
M.FIRST = "neongrid"
M.ALLOWED = { default = true, neongrid = true }
M.ORDER = { "neongrid", "default" }
-- ids antigos -> ids atuais (quem usava o tema antigo continua com ele, ja renomeado)
M.ALIASES = { xbox = "neongrid" }
local function resolve(id) return M.ALIASES[id] or id end
M.resolve = resolve
local PREF = "theme.txt"
local BUILTIN_DIR = "themes"
M.USER_DIR = "user_themes"

local COLOR_KEYS = { "bg0", "bg1", "bg2", "bg3", "line", "text", "dim", "faint", "accent", "accent2",
  "yellow", "green", "red", "orange", "black", "shadow" }
local BUTTON_KEYS = { "a", "b", "x", "y", "l1", "r1", "start", "select", "dpad" }

--- le e valida um theme.json. Devolve tema ou nil, motivo
local function load_def(dir, builtin)
  local ok, text = pcall(love.filesystem.read, dir .. "/theme.json")
  if not ok or not text then return nil, L("theme.json não encontrado") end
  local d = json.decode(text)
  if type(d) ~= "table" then return nil, L("theme.json inválido") end
  if type(d.id) ~= "string" or not d.id:match("^[%w_%-]+$") then return nil, L("id inválido") end
  if type(d.colors) ~= "table" then return nil, L("sem cores") end
  local display_names={default="Pulse Edition",neongrid="Matrix Edition"}
  local th = { id = d.id, name = display_names[d.id] or tostring(d.name or d.id), description = tostring(d.description or ""),
    version = tostring(d.version or ""), author = display_names[d.id] and "Lag do Lira (tema original)" or tostring(d.author or ""), dir = dir, builtin = builtin,
    colors = {}, buttons = {}, style = {} }
  -- todas as cores sao obrigatorias: um tema incompleto nao e aplicado
  for _, k in ipairs(COLOR_KEYS) do
    local c = T.parse_hex(d.colors[k])
    if not c then return nil, L("cor \"") .. k .. L("\" ausente ou inválida") end
    th.colors[k] = c
  end
  for _, k in ipairs(BUTTON_KEYS) do
    local c = T.parse_hex(type(d.buttons) == "table" and d.buttons[k] or nil)
    if c then th.buttons[k] = c end
  end
  local st = type(d.style) == "table" and d.style or {}
  local BGS = { modern = true, neongrid = true, wii = true, pastel = true, xdash = true }
  th.style.background = BGS[st.background] and st.background or "retro"
  -- layout da tela inicial: "channels" (grade de canais: Wii Blue e NEON GRID),
  -- "dashboard" (painel NEON GRID antigo) ou o classico (lista)
  local LAYS = { dashboard = true, channels = true, carousel = true, xdash = true, force = true }
  th.style.layout = LAYS[st.layout or ""] and st.layout or nil
  -- listas de ports: "grid" = grade de capas com o port escolhido em destaque (Neon Grid)
  th.style.list = (st.list == "grid") and "grid" or nil
  -- barras do topo e do rodape: "pill" = pilulas brancas flutuantes (Pastel Pop)
  th.style.chrome = (st.chrome == "pill") and "pill" or nil
  -- cartoes (canais, areas, categorias, cartoes de configuracao): cores proprias
  -- opcionais. Sem elas, o cartao usa as cores dos paineis do tema.
  if type(st.card) == "table" then
    local cd = {}
    for _, k in ipairs({ "fill", "line", "text", "dim", "faint", "icon" }) do cd[k] = T.parse_hex(st.card[k]) end
    if cd.fill and cd.text then th.style.card = cd end
  end
  -- foco (cartao selecionado): cor e efeito ("soft" = halo suave e leve
  -- aumento; "neon" = contorno luminoso e cantos de mira)
  th.style.focus = T.parse_hex(st.focus) or th.colors.accent
  local EFX = { neon = true, soft = true, pop = true, glow = true }
  th.style.effect = EFX[st.effect or ""] and st.effect or nil
  th.style.round = U.clamp(tonumber(st.round) or 1, 0, 1.5)
  th.style.glow = T.parse_hex(st.glow) or th.colors.accent
  th.style.scanlines = st.scanlines ~= false
  -- Os três temas escolhidos podem ampliar somente o logo do cabeçalho.
  for _, k in ipairs({ "logo_header_scale", "logo_menu_scale", "logo_about_scale", "logo_splash_scale" }) do
    local value = tonumber(st[k])
    if value and value > 0 and value <= 3 then th.style[k] = value end
  end
  -- logo propria do tema (opcional): logo_header.png, logo_menu.png, logo_about.png
  if love.filesystem.getInfo(dir .. "/logo_menu.png") then th.style.logo_dir = dir end
  -- Fundo pixel-fiel renderizado diretamente do HTML V4 aprovado.
  if love.filesystem.getInfo(dir .. "/background_v4.png","file") then
    th.style.force_bg = dir .. "/background_v4.png"
  end
  if type(d.preview) == "string" and d.preview:match("^[%w_%-%.]+%.png$") then
    th.preview = dir .. "/" .. d.preview
  end
  return th
end

-- Permite tema instalado mais recente substituir visualmente um tema incluso,
-- mantendo os arquivos originais intactos e recuperaveis.
local function newer_version(a,b)
  local x,y,z=tostring(a or ""):match("^(%d+)%.(%d+)%.(%d+)")
  local u,v,w=tostring(b or ""):match("^(%d+)%.(%d+)%.(%d+)")
  x,y,z=tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0
  u,v,w=tonumber(u) or 0,tonumber(v) or 0,tonumber(w) or 0
  if x~=u then return x>u end
  if y~=v then return y>v end
  return z>w
end

-- Atualiza somente temas OPCIONAIS previamente instalados, sem apagar
-- arquivos extras ou rebaixar versoes existentes.
local THEME_FILES = {
  "background_v4.png", "selected_tiles_v4.png", "preview.png",
  "logo_header.png", "logo_menu.png", "logo_about.png", "logo_splash.png"
}
local function sync_bundled_installed_themes()
  local srcroot = "theme_updates"
  if not love.filesystem.getInfo(srcroot, "directory") then return end
  for _, id in ipairs(love.filesystem.getDirectoryItems(srcroot)) do
    if M.ALLOWED[id] and id:match("^[%w_%-]+$") then
      local src = srcroot .. "/" .. id
      local dst = M.USER_DIR .. "/" .. id
      -- So atualizar um tema opcional ja instalado pelo usuario.
      if love.filesystem.getInfo(dst .. "/theme.json", "file") then
        local newdata = love.filesystem.read(src .. "/theme.json")
        local olddata = love.filesystem.read(dst .. "/theme.json")
        local newest = newdata and json.decode(newdata) or nil
        local current = olddata and json.decode(olddata) or nil
        if type(newest) == "table" and newest.id == id
            and type(current) == "table" and current.id == id
            and newer_version(newest.version, current.version) then
          local valid = true
          for _, name in ipairs(THEME_FILES) do
            -- Os temas do Lira nao usam background_v4/selected_tiles_v4.
            -- Atualizar apenas os assets que EXISTEM no pacote oficial.
            if love.filesystem.getInfo(src .. "/" .. name, "file") then
              local data = love.filesystem.read(src .. "/" .. name)
              if not data or not love.filesystem.write(dst .. "/" .. name, data) then
                valid = false
                U.log("tema opcional: falha ao atualizar", id, name)
                break
              end
            end
          end
          -- Gravar versao por ultimo; se houver falha, permite retentar.
          if valid and love.filesystem.write(dst .. "/theme.json", newdata) then
            U.log("tema opcional atualizado com a STORE:", id, newest.version)
          end
        end
      end
    end
  end
end

-- Compatibilidade com usuarios vindos da linha 0.6.2: o tema do Lira
-- que JA ESTAVA SELECIONADO continua aplicado, mesmo sem internet.
-- O bundle "theme_updates/<id>" e um pacote de migracao, nao tema de fabrica.
-- Nao toca em outras pastas nem instala automaticamente os quatro legados.
local LEGACY = { default=true, neongrid=true }
local function migrate_selected_legacy()
  local ok, wanted = pcall(love.filesystem.read, PREF)
  wanted = ok and wanted and resolve(U.trim(wanted)) or nil
  if not LEGACY[wanted] then return end
  local src = "theme_updates/" .. wanted
  local dst = M.USER_DIR .. "/" .. wanted
  if love.filesystem.getInfo(dst .. "/theme.json", "file") then return end
  -- Se a pasta ja existe sem manifesto, preserva tudo; nao sobrescreve custom.
  if love.filesystem.getInfo(dst, "directory") then
    U.log("tema legado: destino personalizado/incompleto preservado", wanted)
    return
  end
  local data = love.filesystem.read(src .. "/theme.json")
  local meta = data and json.decode(data) or nil
  if type(meta) ~= "table" or meta.id ~= wanted or type(meta.colors) ~= "table" then
    U.log("tema legado: pacote de migracao nao encontrado", wanted)
    return
  end
  if not love.filesystem.createDirectory(dst) then
    U.log("tema legado: nao foi possivel criar pasta de destino", wanted)
    return
  end
  for _, name in ipairs(THEME_FILES) do
    if love.filesystem.getInfo(src .. "/" .. name, "file") then
      local body = love.filesystem.read(src .. "/" .. name)
      if not body or not love.filesystem.write(dst .. "/" .. name, body) then
        U.log("tema legado: copia incompleta", wanted, name)
        return -- o manifesto sera gravado SOMENTE apos todos os PNGs
      end
    end
  end
  if love.filesystem.write(dst .. "/theme.json", data) then
    U.log("tema legado preservado ao migrar para opcional:", wanted)
  end
end

--- procura os temas inclusos e os instalados pelo usuario
function M.scan()
  migrate_selected_legacy()
  sync_bundled_installed_themes()
  M.list, M.by_id, M.errors = {}, {}, {}
  local function add(dir, builtin)
    local th, err = load_def(dir, builtin)
    if th and not M.ALLOWED[th.id] then return end
    if th and not M.by_id[th.id] then
      M.list[#M.list + 1] = th
      M.by_id[th.id] = th
    elseif th and not builtin and M.by_id[th.id] and M.by_id[th.id].builtin
        and newer_version(th.version,M.by_id[th.id].version) then
      -- So sobrepoe com pacote mais recente; apagar pacote restaura o incluso.
      for i, old in ipairs(M.list) do
        if old.id==th.id then M.list[i]=th; break end
      end
      M.by_id[th.id]=th
    elseif not th then
      M.errors[#M.errors + 1] = dir .. ": " .. tostring(err)
      U.log("tema ignorado:", dir, err)
    end
  end
  -- Os temas removidos podem persistir na pasta do cartao apos atualizar
  -- o app; nao apagamos dados privados, mas nunca listamos ou aplicamos.
  for _, id in ipairs(M.ORDER) do
    local dir = BUILTIN_DIR .. "/" .. id
    if love.filesystem.getInfo(dir, "directory") then add(dir, true) end
  end
  -- Caso o utilizador tenha substituido um dos dois temas, manter o
  -- comportamento de sobreposicao ja existente somente nesses IDs.
  if love.filesystem.getInfo(M.USER_DIR, "directory") then
    for _, id in ipairs(M.ORDER) do
      local dir = M.USER_DIR .. "/" .. id
      if love.filesystem.getInfo(dir, "directory") then add(dir, false) end
    end
  end
end

-- Preferencias de cor isoladas por ID estavel do tema.
local function color_key(id) return "ui_color_" .. resolve(id) end
local function color_for(id)
  local value=Prefs.get(color_key(id))
  return Schemes.valid(value) and value or "original"
end
local function migrate_color(id)
  local legacy=Prefs.get("ui_color")
  if legacy==nil then return end
  if not M.ALLOWED[id] or not M.by_id[id] then id=M.DEFAULT end
  -- A ultima cor global pertencia ao tema que estava ativo.
  if Prefs.get(color_key(id))==nil and Schemes.valid(legacy) then
    Prefs.set(color_key(id),legacy)
  end
  Prefs.set("ui_color",nil)
end

--- aplica um tema (sem reiniciar). Devolve true ou false, motivo
function M.apply(id, save)
  id = resolve(id)
  local th = M.by_id and M.by_id[id]
  if not th or not M.ALLOWED[id] then return false, L("tema não encontrado") end
  local colors,style=Schemes.resolve(th.colors,th.style,color_for(id))
  T.apply_palette(colors,th.buttons,style)
  require("ui.gfx").build_background()
  M.current = id
  if save then pcall(love.filesystem.write, PREF, id) end
  return true
end

function M.color_id()
  return color_for(M.current)
end
function M.set_color(id)
  if not Schemes.valid(id) then return false end
  local key=color_key(M.current)
  local before=Prefs.get(key)
  Prefs.set(key,id)
  local ok=M.apply(M.current,false)
  if not ok then Prefs.set(key,before);return false end
  return true
end

--- na abertura: aplica o ultimo tema escolhido; se falhar, volta ao padrao
--- Devolve uma mensagem de aviso (ou nil)
function M.init()
  M.scan()
  local ok, saved = pcall(love.filesystem.read, PREF)
  saved = ok and saved and U.trim(saved) or (M.by_id[M.FIRST] and M.FIRST or M.DEFAULT)
  if saved == "" then saved = M.by_id[M.FIRST] and M.FIRST or M.DEFAULT end
  -- migracao: tema salvo com o id antigo (ex.: xbox -> neongrid) e regravado com o novo
  if M.ALIASES[saved] then
    U.log("tema: id antigo", saved, "migrado para", resolve(saved))
    saved = resolve(saved)
    pcall(love.filesystem.write, PREF, saved)
  end
  migrate_color(saved)
  if saved ~= M.DEFAULT then
    local applied = M.apply(saved, false)
    if applied then return nil end
    U.log("tema salvo indisponivel:", saved)
    if not M.apply(M.DEFAULT, true) then M.apply("default", true) end
    return L("O tema escolhido não pôde ser carregado. Usando Tema Padrão.")
  end
  if not M.apply(M.DEFAULT, false) then
    if not M.apply("default", false) then M.current = "default" end
  end
  return nil
end

--- endereco do catalogo de temas (futuro): config.lua ou themes_url.txt
function M.catalog_url()
  local s = U.read_file(C.APP_DIR .. "/themes_url.txt")
  if s then
    s = U.trim(s:match("^[^\r\n]*") or "")
    if s:match("^https?://") then return s end
  end
  if C.THEMES_CATALOG_URL and C.THEMES_CATALOG_URL:match("^https?://") then return C.THEMES_CATALOG_URL end
  return nil
end

return M
