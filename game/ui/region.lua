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
}
R.SYSTEM_COLOR = T.hex("#38D6FF") -- ciano em ambos os temas

function R.code(p)
  if not p or p.builtin or p.section ~= "games" then return nil end
  local tag = type(p.region_tag) == "string" and p.region_tag:upper() or ""
  if R.COLORS[tag] then return tag end
  local code = type(p.name) == "string" and p.name:match("%s+%[([A-Z][A-Z])%]$") or nil
  if R.COLORS[code] then return code end
  return nil
end

function R.display_name(p)
  local name = p and p.name or ""
  local tag = R.code(p)
  if tag then
    -- Tira apenas o ultimo [JP]/[CN]/[TW]/[HK] da tela; nao altera p.name.
    return (name:gsub("%s+%[" .. tag .. "%]$", ""))
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
  G.rect(x, y, w, 20, T.c.bg1, 9, 0.94)
  G.frame(x, y, w, 20, color or T.c.accent2, 9, 1)
  G.text_fit(T.f.small, tostring(text), x + 8, y + 3, w - 16, color or T.c.accent2)
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
