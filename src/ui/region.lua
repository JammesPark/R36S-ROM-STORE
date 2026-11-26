-- Selos de regiao: apresentação somente. Nao altera nome, ID ou URL.
-- As siglas representam metadados do arquivo, nao idioma confirmado.
local T = require("ui.theme")
local G = require("ui.gfx")
local R = {}

R.COLORS = {
  JP = T.hex("#FF738A"), -- rosa coral
  CN = T.hex("#FFC065"), -- laranja
  TW = T.hex("#58E0A6"), -- verde
  HK = T.hex("#B9A1FF"), -- lilas
  US=T.hex("#79B9FF"), EU=T.hex("#A5B8FF"), BR=T.hex("#63E690"),
  KR=T.hex("#F1A0E5"), WW=T.hex("#C4CEDA"), AS=T.hex("#F6C66F"),
  AU=T.hex("#75D8DE"), CA=T.hex("#FF9696"), UK=T.hex("#92A9EF"),
  FR=T.hex("#7AB5FF"), DE=T.hex("#E8CD75"), ES=T.hex("#FF9B6C"),
  IT=T.hex("#87DDA6"), PT=T.hex("#9BDB8C"), RU=T.hex("#C0AEFF"),
  NL=T.hex("#FFA66B"), SE=T.hex("#88C5FF"), MX=T.hex("#9ED5A0"),
}
R.SYSTEM_COLOR = T.hex("#38D6FF") -- ciano em ambos os temas

function R.code(p)
  if not p or p.builtin or p.section ~= "games" then return nil end
  local code=require("core.rom_region").detect(p)
  return R.COLORS[code] and code or nil
end

function R.display_name(p)
  local name = p and p.name or ""
  local tag = R.code(p)
  if tag then
    -- Limpa apenas a APRESENTACAO, nunca altera p.name, original_name ou URLs.
    name = (name:gsub("%s+%[" .. tag .. "%]$", ""))
    local names = {
      JP = { "(Japan)", "(JP)", "(Japanese)" },
      CN = { "(China)", "(CN)", "(Chinese)" },
      TW = { "(Taiwan)", "(TW)" },
      HK = { "(Hong Kong)", "(HK)" },
    }
    for _, ending in ipairs(names[tag] or {}) do
      if name:sub(-#ending) == ending then
        return (name:sub(1, #name - #ending):gsub("%s+$", ""))
      end
    end
    return name
  end
  return name
end

function R.color(tag)
  return R.COLORS[tag]
end

function R.pill_width(text, maxw)
  local width = T.f.small:getWidth(tostring(text or "")) + 16
  return maxw and math.min(width, maxw) or width
end

-- Mesma etiqueta arredondada/contornada para sistema e regiao;
-- maxw restringe o sistema quando o titulo e longo.
function R.pill(text, x, y, color, maxw)
  if not text or text == "" then return 0 end
  local w = R.pill_width(text, maxw)
  if w < 26 then return 0 end
  G.rect(x, y, w, 20, color or T.c.accent2, 9, 1)
  G.text_fit(T.f.small, tostring(text), x + 8, y + 3, w - 16, T.hex("#101820"))
  return w
end

function R.draw_system(p, x, y, maxw)
  if not p or not p.category then return 0 end
  return R.pill(p.category, x, y, R.SYSTEM_COLOR, maxw)
end

function R.draw_region(p, x, y)
  local tag = R.code(p)
  if not tag then return 0 end
  return R.pill(tag, x, y, R.COLORS[tag])
end

return R
