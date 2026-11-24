-- =============================================================================
--  Linha de port reutilizada pelas listas (loja, favoritos, pesquisa, novidades)
--  Capa, nome, estrela de favorito, categoria/tipo, tamanho e selo de status.
--  O selo usa o reconhecimento de instalados ja existente (App.status).
-- =============================================================================
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local Covers = require("core.covers")
local Favorites = require("core.favorites")
local Cats = require("core.categories")
local Icons = require("ui.icons")
local Region = require("ui.region")

local R = {}

R.BADGE = {
  installed = { L("INSTALADO"), T.c.green },
  update = { L("ATUALIZAR"), T.c.yellow },
}
R.NEW = { L("NOVO"), T.c.accent }

--- texto secundario: categoria (+ tipo de teste) e tamanho
function R.subtitle(p)
  local cat = p.category
  if p.test_type and Cats.TEST_TYPE_BY_ID[p.test_type] then
    cat = cat .. " • " .. Cats.TEST_TYPE_BY_ID[p.test_type].name:gsub("^Teste d?e? ?", "")
  end
  return cat .. "  •  " .. (p.size_label or "?")
end

--- extra: { area = true } mostra JOGO/UTILITARIO; { right = "texto" } troca o selo
function R.draw(p, x, y, w, h, on, accent, extra)
  extra = extra or {}
  if on then
    G.rect(x, y, w, h, T.c.bg3, 6)
    G.frame(x, y, w, h, accent or T.c.accent, 6, 2)
  end
  local st, badge
  if p.builtin then
    G.rect(x + 8, y + 4, 29, h - 8, T.c.bg0, 4)
    G.frame(x + 8, y + 4, 29, h - 8, T.c.green, 4)
    Icons.draw(p.icon, x + 11, y + h / 2 - 11, T.c.green, 0.9)
    badge = { L("INTEGRADO"), T.c.green }
  else
    G.cover(Covers.get(p), p, x + 8, y + 4, 29, h - 8, false, App.t)
    st = App.status(p)
    badge = extra.location and { extra.location, T.c.green } or R.BADGE[st]
    -- selo NOVO (adicionado ha poucos dias ao catalogo), so se ainda nao instalado
    if not badge and require("core.catalog").is_new(p) then badge = R.NEW end
  end
  local fav = not p.builtin and Favorites.is(p)
  local rightw = 0
  if badge then
    rightw = T.f.pix8:getWidth(badge[1]) + 12
    G.tag(badge[1], x + w - 10 - rightw, y + h / 2 - 9, badge[2], T.c.bg0)
  end
  local nx = x + 46
  if fav then
    Icons.draw("generic", nx, y + 6, T.c.yellow, 0.6)
    nx = nx + 17
  end
  local tw = w - (nx - x) - 12 - (rightw > 0 and rightw + 8 or 0)
  local ft, fs, ty, sy = G.row_fonts(h, 5, h - 22)
  G.text_fit(ft, Region.display_name(p), nx, y + ty, tw, on and T.c.text or T.c.dim)
  local sub = R.subtitle(p)
  if extra.area then
    sub = (p.section == "tools" and L("Utilitário") or L("Jogo")) .. "  •  " .. sub
  end
  local sub_x = x + 46
  local sub_w = w - 58 - (rightw > 0 and rightw + 8 or 0)
  if p.section == "games" and not p.builtin then
    local code = Region.code(p)
    local region_w = code and (Region.pill_width(code) + 6) or 0
    local size = (p.size_label or "?")
    local size_w = size ~= "?" and math.min(54, fs:getWidth(size) + 6) or 0
    local sys_w = math.max(42, sub_w - region_w - size_w - 4)
    local dx = Region.draw_system(p, sub_x, y + h - 23, sys_w)
    if code then
      dx = dx + 6
      dx = dx + Region.draw_region(p, sub_x + dx, y + h - 23)
    end
    if size_w > 0 and dx + size_w + 5 <= sub_w then
      G.text_fit(fs, size, sub_x + dx + 8, y + sy, size_w, T.c.faint)
    end
  else
    G.text_fit(fs, sub, sub_x, y + sy, sub_w, T.c.faint)
  end
end

return R
