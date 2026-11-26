-- Novidades e Em Breve da tela Force Nexus.
-- Lista exclusivamente dados reais do catalogo selecionado (Lira ou R36S ROM STORE).
-- Nunca mistura fontes nem inventa jogos para preencher a vitrine.
local Catalog = require("core.catalog")
local M = { LIMIT = 6 }

local function valid_date(s)
  return type(s) == "string" and s:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil
end
local function marked_date(s)
  return valid_date(s) and s or ""
end

function M.build()
  local news_dates = {}
  for _, item in ipairs(Catalog.news or {}) do
    if item.type == "new" and type(item.id) == "string" then
      local date = marked_date(item.date)
      if date ~= "" and (not news_dates[item.id] or date > news_dates[item.id]) then
        news_dates[item.id] = date
      end
    end
  end

  local feeds = { novos = {}, breve = {} }
  for position, p in ipairs(Catalog.ports or {}) do
    if p.section == "games" and not p.builtin then
      local added = marked_date(p.added)
      if added == "" then added = news_dates[p.id] or "" end
      local has_download = type(p.download_url) == "string" and p.download_url ~= ""
      if has_download then
        -- Sem data confirmada, nao afirmar que o port foi adicionado recentemente.
        if added ~= "" then
          feeds.novos[#feeds.novos + 1] = {
            port = p, kind = "novos", date = added, position = position
          }
        end
      else
        -- O catalogo oficial ja usa link vazio para indicar "EM BREVE".
        -- Ordena anuncios por data, com ordem do catalogo como desempate.
        local announced = marked_date(p.announced_at)
        if announced == "" then announced = added end
        feeds.breve[#feeds.breve + 1] = {
          port = p, kind = "breve", date = announced, position = position
        }
      end
    end
  end

  for _, items in pairs(feeds) do
    table.sort(items, function(a,b)
      if a.date ~= b.date then return a.date > b.date end
      return a.position > b.position
    end)
    while #items > M.LIMIT do items[#items] = nil end
  end
  return feeds
end
return M
