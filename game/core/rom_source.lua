-- ROMs do GameStoreBR: fonte paginada usada pela ROMS STORE anterior.
-- Busca por sistema sem substituir os catalogos locais e sem consultar ports.
local json = require("lib.json")
local U = require("lib.util")
local Fetcher = require("core.fetcher")
local Catalog = require("core.catalog")
local R = { pages = {}, serial = 0, generation = 0, error = nil }
function R.reset()
  R.generation=R.generation+1
  R.pages={}
  R.error=nil
end
local HOST = "r36swiki.com"
local BASE = "https://" .. HOST .. "/getgames.php?"
local LIMIT = 10
local VALID = {
  ["3do"]=true, amigacd32=true, atari2600=true, dreamcast=true,
  gamegear=true, gb=true, gba=true, gbc=true, mame=true,
  mastersystem=true, megadrive=true, n64=true, nds=true, neogeo=true,
  nes=true, pcengine=true, psp=true, psx=true, saturn=true, snes=true,
  genesis=true,
}
local function category(c)
  if c == "genesis" then return "megadrive" end
  return (c == "all" or VALID[c]) and c or nil
end
local function encode(s)
  return (tostring(s):gsub("([^%w%-_%.~])", function(c) return string.format("%%%02X",string.byte(c)) end))
end
local function safe_link(s)
  if type(s) ~= "string" or #s > 2048 then return nil end
  s = U.trim(s)
  if s:sub(1,2) == "//" then return nil end
  if not s:match("^https?://") and not s:find(":",1,true) then
    s = "http://" .. HOST .. "/" .. s:gsub("^/+", "")
  end
  if not s:match("^https?://[%w%.%-]+") or s:find("[%c%s]") or s:find("@",1,true) then return nil end
  return s
end
local function normalize_games(body, fallback)
  if type(body) ~= "table" or body.success ~= true or type(body.games) ~= "table" then return nil end
  local out = {}
  for _,g in ipairs(body.games) do
    if #out >= LIMIT then break end
    if type(g) == "table" then
      local name = type(g.name) == "string" and U.trim(g.name):sub(1,160) or ""
      local cat = category(type(g.category)=="string" and g.category:lower() or fallback)
      local url = safe_link(g.game_path)
      if name ~= "" and cat and cat ~= "all" and url then
        local cover = safe_link(g.image_url) or ""
        -- Identificador estavel por URL. Nomes iguais podem ter ROMs distintas.
        local digest = love.data.encode("string", "hex", love.data.hash("sha1", cat .. ":" .. url))
        local id = "rom-" .. cat .. "-" .. U.slug(name):sub(1,68) .. "-" .. digest:sub(1,10)
        out[#out+1] = { id=id, name=name, category=cat, system_id=cat,
          section="games", download_url=url, cover=cover }
      end
    end
  end
  return out
end
local function read_response(path)
  local f = io.open(path or "", "rb")
  if not f then return nil end
  local size = f:seek("end") or 0
  if size < 1 or size > 3*1024*1024 then f:close(); return nil end
  f:seek("set",0)
  local text = f:read("*a")
  f:close()
  return text
end
local function decode(text)
  if type(text) ~= "string" then return nil end
  local ok, payload = pcall(json.decode, text)
  if not ok or type(payload) ~= "table" then return nil end
  return payload
end
local function entry(cat)
  local e = R.pages[cat]
  if not e then e={page=0,total_pages=nil,loading=false,failed=false}; R.pages[cat]=e end
  return e
end
function R.state(cat)
  if Catalog.provider()=="r36s_own" then
    return {page=1,total_pages=1,loading=false,failed=false}
  end
  return R.pages[cat]
end
function R.is_supported(cat)
  if Catalog.provider()=="r36s_own" then return false end
  if cat=="all" then return true end
  for _,c in ipairs(Catalog.categories or {}) do
    if c.section=="games" and c.id==cat then return VALID[cat] == true end
  end
  return false
end
local function apply_page(cat, page, text, notify)
  local payload=decode(text)
  local games=payload and normalize_games(payload,cat)
  if not games then return false end
  local e=entry(cat)
  local total=math.floor(tonumber(payload.total_pages) or page)
  e.total_pages=math.max(page,math.min(total,100000))
  e.page=math.max(e.page,page)
  e.failed=false
  local added=Catalog.add_rom_games(games)
  if notify and added>0 and App and App.on_catalog_changed then App.on_catalog_changed() end
  return true, added
end
local function cache_name(cat,page)
  return "roms_pages/" .. cat .. "_" .. tostring(page) .. ".json"
end
local function fetch_page(cat, page, retry_http, on_done)
  local generation=R.generation
  local e=entry(cat)
  if e.loading then return end
  e.loading=true
  R.serial=R.serial+1
  local qs="action=games&page=" .. page .. "&limit=" .. LIMIT
  if cat ~= "all" then qs=qs .. "&category=" .. encode(cat) end
  local url=(retry_http and "http://" .. HOST .. "/getgames.php?" or BASE)..qs
  local out=love.filesystem.getSaveDirectory() .. "/roms_page_download_" .. R.serial .. ".json"
  Fetcher.get("catalog",url,out,function(ok, path, reason)
    if generation~=R.generation or Catalog.provider()=="r36s_own" then
      if path then os.remove(path) end
      if on_done then on_done(false,0,"Fonte do catalogo alterada") end
      return
    end
    local body = ok and read_response(path) or nil
    if path then os.remove(path) end
    local applied, added = body and apply_page(cat,page,body,true)
    if applied then
      pcall(function()
        love.filesystem.createDirectory("roms_pages")
        love.filesystem.write(cache_name(cat,page),body)
      end)
      e.loading=false
      if on_done then on_done(true,added,nil) end
      return
    end
    if not retry_http then
      e.loading=false
      fetch_page(cat,page,true,on_done) -- tentativa HTTP original deste host
      return
    end
    e.loading=false
    e.failed=true
    e.error=reason or "API de ROMs sem resposta válida"
    U.log("ROMs por sistema: falha",cat,page,e.error)
    if on_done then on_done(false,0,e.error) end
  end,true)
end
-- Endereco conhecido da API de ROMs. Nenhuma fonte de ports é consultada.
function R.source_label() return BASE:match("^https?://[^/]+") or HOST end

function R.ensure(cat)
  if Catalog.provider()=="r36s_own" then return false end
  cat=category(cat)
  if not cat or not R.is_supported(cat) then return false end
  local e=entry(cat)
  if e.loading or e.failed then return false end
  if e.total_pages and e.page >= e.total_pages then return false end
  local page=e.page+1
  -- Reutiliza páginas armazenadas, sem rede; somente a página em foco.
  local cached=love.filesystem.read(cache_name(cat,page))
  if cached and apply_page(cat,page,cached,false) then return true end
  fetch_page(cat,page,false)
  return true
end

-- Recarrega a primeira pagina pela rede, sem apagar ROMs/cache existentes.
function R.refresh(cat,on_done)
  if Catalog.provider()=="r36s_own" then return false end
  cat=category(cat)
  if not cat or not R.is_supported(cat) then return false end
  local e=entry(cat)
  if e.loading then return false end
  e.failed=false
  fetch_page(cat,1,false,on_done)
  return true
end

function R.retry(cat)
  if Catalog.provider()=="r36s_own" then return end
  cat=category(cat)
  if not cat or not R.is_supported(cat) then return end
  local e=entry(cat)
  if e.loading then return end
  e.failed=false
  R.ensure(cat)
end

-- Pesquisa paginada por todos os sistemas; não exige baixar o catálogo inteiro.
function R.search(query, page, callback)
  if Catalog.provider()=="r36s_own" then
    if callback then callback(false,nil,"Busca local: catalogo completo ja carregado") end
    return
  end
  local generation=R.generation
  local q=tostring(query or ""):sub(1,80)
  if #q<2 or q:find("[%c]") then return end
  page=math.floor(tonumber(page) or 1)
  if page<1 or page>10000 then return end
  local seq=R.serial+1;R.serial=seq
  local baseqs="action=search&search="..encode(q).."&page="..page.."&limit="..LIMIT
  local function fetch(http)
    local url=(http and "http://"..HOST.."/getgames.php?" or BASE)..baseqs
    local out=love.filesystem.getSaveDirectory().."/roms_search_"..seq..".json"
    Fetcher.get("catalog",url,out,function(ok,path,reason)
      if generation~=R.generation or Catalog.provider()=="r36s_own" then
        if path then os.remove(path) end
        if callback then callback(false,nil,"Fonte alterada") end
        return
      end
      local body=ok and read_response(path) or nil
      if path then os.remove(path) end
      local payload=decode(body)
      local games=payload and normalize_games(payload,"all")
      if games then
        Catalog.add_rom_games(games)
        if callback then callback(true, games, payload) end
      elseif not http then
        fetch(true)
      elseif callback then callback(false,nil,reason) end
    end,true)
  end
  fetch(false)
end
return R
