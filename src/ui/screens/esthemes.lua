-- =============================================================================
--  Loja de Temas (EmulationStation) - Utilitarios & Ferramentas
--  Mostra so os temas compativeis com o sistema identificado (ou escolhido).
--  L1/R1 filtros | A visualizar | X baixar e instalar | Y remover
--  SELECT trocar sistema | B voltar
--  Reconhece os temas que ja existem no console (core/esthemes_scan.lua):
--  de fabrica, do usuario, do hub e do ThemeMaster; mostra o tema ATIVO.
-- =============================================================================
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local U = require("lib.util")
local Covers = require("core.covers")
local OS = require("core.osdetect")
local ES = require("core.esthemes")
local Gal = require("core.esgallery")
local Unified = require("core.esthemes_unified")
local JSON = require("lib.json")
local FAVORITE_FILE="es_theme_favorites.json"
local SIZE_FILE = "es_theme_size.txt"
local lg = love.graphics

local S = {}
-- painel com posicoes fixas e muita informacao: texto sempre no tamanho padrao
-- (Configuracoes > Aparencia > Tamanho do texto nao se aplica a esta tela)
S.fixed_text = true
local FILTERS = {
  {id="all",label=L("Todos")}, {id="compat",label=L("Compatíveis")},
  {id="recent",label=L("Recentes")}, {id="installed",label=L("Instalados")},
  {id="favorites",label=L("Favoritos")}, {id="updates",label=L("Atualizações")},
}
local SECONDARY={
  {"all","Todos"},{"experimental","Experimentais"},{"unknown","Não verificados"},
  {"incompatible","Incompatíveis"},{"popular","Populares"},{"light","Leves"},
  {"full","Completos"},{"collections","Coleções"}
}
local SEARCH_KEYS={"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9"," ","-","<","OK"}

local RES_LABEL = { yes = L("FUNCIONA"), untested = L("NÃO TESTADO"), no = L("NÃO FUNCIONA") }
local RES_COLOR = { yes = "green", untested = "yellow", no = "red" }
local RES_TEXT = { yes = L("funciona"), untested = L("não testado"), no = L("não funciona") }
local ST_COLOR = { testado = "green", compativel = "green", experimental = "yellow", incompatible="red", unknown="dim" }
local LIST_X, LIST_Y, LIST_W, ROW_H, VISIBLE = 12, 112, 300, 40, 8

function S:enter(params)
  self.download_key=params and params.download_key
  self.download_retry=params and params.download_retry
  self.update_revision=ES.update_revision or 0
  self.install_revision=ES.install_revision or 0
  self.os = OS.detect()
  self.os_id = self.os.confirmed and self.os.id or nil
  self.manual = false
  self.secondary,self.sort,self.query='all','az',''
  self.options,self.searchbox=nil,nil
  local ok,raw=pcall(love.filesystem.read,FAVORITE_FILE)
  local favorites=ok and raw and JSON.decode(raw) or nil
  self.favorites=type(favorites)=='table' and favorites or {}
  self.filter, self.sel, self.scroll = params and params.updates and #FILTERS or 1, 1, 0
  -- tamanho de tela: o escolhido antes ou o detectado no console
  local saved = U.trim(love.filesystem.read(SIZE_FILE) or "")
  local det, sure = Gal.detect_size()
  self.size, self.size_auto = det, sure
  for _, sz in ipairs(Gal.SIZES) do if sz == saved then self.size, self.size_auto = saved, false; self.size_manual = true end end
  self.view = nil
  self.state = "loading"
  ES.load(function()
    self.state = "ready"
    ES.match()
    self:refresh()
    if ES.online == "failed" then
      App.toast(L("Atualização online do catálogo indisponível: mostrando os temas já conhecidos."), "warn")
    end
  end)
  if not ES.loading then self.state = "ready" end
  self:rescan()
  if ES.check_updates and (not ES.last_check or os.time()-ES.last_check>=1800) then ES.check_updates(false) end
  -- fontes do ThemeMaster (galeria + colecoes): no maximo a cada 6 h
  ES.refresh_gallery(false, function(st)
    self:refresh()
    if (st == "failed" or st == "partial") and not ES.has_gallery() then
      App.toast(L("Galeria do ThemeMaster indisponível (sem internet?): mostrando o catálogo da loja."), "warn")
    elseif st == "failed" or st == "partial" then
      App.toast(L("Atualização online da galeria indisponível: mostrando a última cópia salva."), "warn")
    end
  end)
  -- uma ativacao pedida antes (o EmulationStation reiniciou): confere se valeu
  local pend, folder = ES.check_pending()
  if pend == "ok" then App.toast(L("Tema ativo no EmulationStation: ") .. folder, "ok")
  elseif pend == "fail" then App.toast(L("A ativação de ") .. folder .. L(" não foi confirmada no es_settings.cfg."), "warn") end
  -- Todos pode ser consultado mesmo sem identificar o firmware.
end

--- varre os temas do console (abrir, instalar, remover, ativar)
function S:rescan()
  local sysinfo = ES.systems[self.os_id or ""] or {}
  ES.scan(self.os_id, sysinfo.themes_dir or "/roms/themes")
  self.local_items = {}
  self:refresh()
end

local function pretty(folder)
  local n = folder:gsub("^es%-theme%-", ""):gsub("[_%-]+", " ")
  return (n:gsub("^%l", string.upper))
end

--- item da lista para um tema que so existe no console (fora do catalogo)
function S:local_item(loc)
  self.local_items = self.local_items or {}
  local key=loc.path or loc.folder
  local it = self.local_items[key]
  if it then return it end
  local g = ES.tm and ES.tm.gallery[loc.folder] or {}
  it = { id = "local:" .. key, name = pretty(loc.folder), folder = loc.folder, author = g.author,
    compat = {}, slug = "localtheme-" .. U.slug(loc.folder), cover = loc.preview or g.preview or "",
    is_local = true, loc = loc }
  self.local_items[key] = it
  return it
end

local function loc_of(th) return th.is_local and th.loc or ES.local_for(th) end
local function state_of(th)
  if th.is_local then return ES.state_loc(th.loc), th.loc end
  return ES.state(th)
end

function S:leave() Covers.reset_pending() end

--- lista do filtro atual (so temas do sistema escolhido)
--- res do tema no tamanho de tela escolhido: "yes" | "untested" | "no"
function S:res_of(th) return (th.res or {})[self.size] or "untested" end

function S:status(th) return Unified.status(th,self.os_id,self.size) end
function S:can_install(th) return Unified.can_install(th,self.os_id,self.size) end
function S:refresh()
  local mode=FILTERS[self.filter].id
  local source={}
  for _,th in ipairs(ES.themes or {}) do source[#source+1]=th end
  if mode=="installed" then
    for _,loc in ipairs(ES.local_only or {}) do source[#source+1]=self:local_item(loc) end
  end
  local list=Unified.select(source,{mode=mode,os=self.os_id,size=self.size,
    secondary=mode=="installed" and "all" or self.secondary,query=mode=="installed" and "" or self.query,sort=self.sort,favorites=self.favorites or {},
    installed=function(th) return loc_of(th)~=nil end,
    has_update=function(th) local loc=loc_of(th);return loc and loc.origin~="firmware" and ES.update_available(th,loc) end})
  self.base_n=#(ES.themes or {})
  self.items,self.msg=list,#list==0 and L("Nenhum tema neste filtro.") or nil
  self.sel=U.clamp(self.sel,1,math.max(1,#list))
  if self.download_key then
    for i,th in ipairs(list) do
      if Unified.key(th)==self.download_key then
        local retry=self.download_retry
        self.download_key,self.download_retry=nil,nil
        self.sel=i
        self.view={theme=th,btn=1,from_download=true}
        if retry then self.retry_theme_key=Unified.key(th) end
        break
      end
    end
  end
end
function S:favorite(th)
  local key=Unified.key(th)
  self.favorites[key]=not self.favorites[key] or nil
  pcall(love.filesystem.write,FAVORITE_FILE,JSON.encode(self.favorites))
  self:refresh()
end

-- ---------------------------------------------------------------------------
-- escolha manual do sistema
--- so aparecem os sistemas que tem temas no catalogo
function S:picker_ids()
  local ids = {}
  for _, id in ipairs(OS.ORDER) do
    ids[#ids + 1] = id
  end
  return ids
end

function S:open_picker(tab)
  self.picker = { sel = 1, ids = self:picker_ids(), tab = tab or 1, ssel = 1 }
  for i, id in ipairs(self.picker.ids) do if id == (self.os_id or self.os.id) then self.picker.sel = i end end
  for i, sz in ipairs(Gal.SIZES) do if sz == self.size then self.picker.ssel = i end end
end

--- aba "Tela": tamanhos da galeria com quantos temas funcionam / nao testados
function S:draw_size_tab(x, y, w)
  local det = Gal.detect_size()
  local msg = self.size_auto and (L("Tela detectada: ") .. det .. L(". Você pode escolher outro tamanho."))
    or L("Escolha o tamanho da tela. Temas de outro tamanho costumam ficar cortados ou esticados.")
  local yy = y
  for _, l in ipairs(G.wrap(T.f.small, msg, w - 40)) do G.text(T.f.small, l, x + 20, yy, T.c.dim); yy = yy + 15 end
  yy = yy + 6
  for i, sz in ipairs(Gal.SIZES) do
    local on = i == self.picker.ssel
    if on then G.rect(x + 16, yy - 2, w - 32, 28, T.c.bg3, 5); G.frame(x + 16, yy - 2, w - 32, 28, T.c.accent, 5, 2) end
    G.text(T.f.bodyb, sz .. (sz == det and L("  (este console)") or ""), x + 28, yy + 3, on and T.c.text or T.c.dim)
    local ok, un = 0, 0
    for _, th in ipairs(ES.for_os(self.os_id)) do
      if not th.collection then
        local r = (th.res or {})[sz] or "untested"
        if r == "yes" then ok = ok + 1 elseif r == "untested" then un = un + 1 end
      end
    end
    local info = ok .. L(" funcionam  •  ") .. un .. L(" não testados")
    G.text(T.f.small, info, x + w - 28 - T.f.small:getWidth(info), yy + 5, T.c.faint)
    yy = yy + 31
  end
end

function S:draw_picker()
  G.rect(0, 0, T.W, T.H, T.c.black, 0, 0.7)
  local w, h = 460, 380
  local x, y = (T.W - w) / 2, (T.H - h) / 2
  G.panel(x, y, w, h, { bg = T.c.bg1, border = T.c.accent, lw = 2, r = 10 })
  -- abas: sistema | tela (esquerda/direita)
  local tabs = { L("SISTEMA DO CONSOLE"), L("TAMANHO DA TELA") }
  local tx = x + 20
  for i, t in ipairs(tabs) do
    local on = i == self.picker.tab
    local tw = T.f.pix8:getWidth(require("lib.i18n").tr(t)) + 20
    G.rect(tx, y + 14, tw, 22, on and T.c.accent or T.c.bg2, 11)
    G.text(T.f.pix8, t, tx, y + 21, on and T.c.bg0 or T.c.dim, "center", tw)
    tx = tx + tw + 8
  end
  if self.picker.tab == 2 then
    self:draw_size_tab(x, y + 46, w)
    return
  end
  local msg = self.os.confirmed and (L("Detectado: ") .. self.os.name .. L(". Você pode escolher outro sistema."))
    or L("Sistema operacional não identificado. Selecione manualmente seu sistema para visualizar os temas compatíveis.")
  if not self.os.confirmed and self.os.id then
    msg = L("Possível sistema: ") .. self.os.name .. L(" (confiança ") .. require("lib.i18n").tr(self.os.confidence) .. L("). Confirme ou escolha outro.")
  end
  local yy = y + 46
  for _, l in ipairs(G.wrap(T.f.small, msg, w - 40)) do G.text(T.f.small, l, x + 20, yy, T.c.dim); yy = yy + 15 end
  yy = yy + 6
  if #self.picker.ids == 0 then
    G.text(T.f.body, L("O catálogo ainda não tem temas para nenhum sistema."), x + 20, yy + 10, T.c.faint, "left", w - 40)
  end
  for i, id in ipairs(self.picker.ids) do
    local on = i == self.picker.sel
    if on then G.rect(x + 16, yy - 2, w - 32, 28, T.c.bg3, 5); G.frame(x + 16, yy - 2, w - 32, 28, T.c.accent, 5, 2) end
    G.text(T.f.bodyb, OS.NAMES[id], x + 28, yy + 3, on and T.c.text or T.c.dim)
    -- quantos temas e como estao classificados para este sistema
    local n, comp = 0, 0
    for _, th in ipairs(ES.for_os(id)) do
      n = n + 1
      if th.compat[id] == "compativel" or th.compat[id] == "testado" then comp = comp + 1 end
    end
    local ex = n - comp
    local info = n .. L(" temas  •  ") .. comp .. (comp == 1 and L(" compatível, ") or L(" compatíveis, "))
      .. ex .. (ex == 1 and L(" experimental") or L(" experimentais"))
    G.text(T.f.small, info, x + w - 28 - T.f.small:getWidth(info), yy + 5, T.c.faint)
    yy = yy + 31
  end
end

-- ---------------------------------------------------------------------------
local function status_tag(st, x, y)
  local c = T.c[ST_COLOR[st] or "dim"]
  return G.tag(st=="unknown" and L("NÃO VERIFICADO") or st=="incompatible" and L("INCOMPATÍVEL") or ES.status_label(st), x, y, c, T.c.bg0, T.f.pix8)
end

function S:sys_dir()
  local sysinfo = ES.systems[self.os_id or ""] or {}
  return OS.themes_dir(self.os_id, sysinfo.themes_dir)
end

function S:draw_preview(th, x, y, w, h, index)
  local p=th
  if type(th.previews)=="table" and type(th.previews[index or 1])=="string" and (th.previews[index or 1]:match("^https://") or th.previews[index or 1]:match("^assets/themegallery/[%w_.%-]+/%d+%.jpg$")) then
    p={slug=th.slug,cover=th.previews[index or 1]}
  end
  local loc=loc_of(th)
  if (not p.cover or p.cover=="") and loc and type(loc.preview)=="string" and loc.preview~="" then
    p={slug=th.slug,cover=loc.preview}
  end
  if (not p.cover or p.cover=="") and ES.tm and ES.tm.gallery then
    local g=ES.tm.gallery[th.folder]
    if g and type(g.preview)=="string" and g.preview~="" then p={slug=th.slug,cover=g.preview} end
  end
  G.rect(x, y, w, h, T.c.bg0, 4)
  local img = Covers.get(p)
  if img then
    local iw, ih = img:getDimensions()
    local s = math.min(w / iw, h / ih)
    lg.setColor(1, 1, 1, 1)
    lg.draw(img, x + (w - iw * s) / 2, y + (h - ih * s) / 2, 0, s, s)
  else
    G.text(T.f.small, Covers.is_loading(p) and L("Carregando imagem...") or L("Sem pré-visualização"), x, y + h / 2 - 6, T.c.faint, "center", w)
  end
  G.frame(x, y, w, h, T.c.line, 4)
end

function S:draw()
  local updates=ES.update_list and #ES.update_list() or 0
  G.header(L("Temas Store"),ES.checking_updates and L("Verificando atualizações...") or updates>0 and (updates.." "..L("atualizações")) or nil)
  -- sistema
  G.panel(12, 46, T.W - 24, 30, { bg = T.c.bg1 })
  local sys
  if self.os_id then
    sys = L("Sistema: ") .. OS.NAMES[self.os_id]
    if not self.manual and self.os.version then sys = sys .. " (" .. self.os.version .. ")" end
    sys = sys .. (self.manual and L("  •  escolhido manualmente") or (L("  •  confiança ") .. require("lib.i18n").tr(self.os.confidence or "?")))
  else
    sys = L("Sistema operacional não identificado")
  end
  G.text_fit(T.f.small, sys, 24, 54, 280, self.os_id and T.c.text or T.c.yellow)
  local cnt = self.size .. "  •  " .. (FILTERS[self.filter].id=="installed" and (tostring(#(self.items or {}))..L(" no console")) or (tostring(#(self.items or {})) .. "/" .. tostring(self.base_n or 0) .. L(" temas")))
  G.text(T.f.small, cnt, T.W - 24 - T.f.small:getWidth(cnt), 54, T.c.dim)

  -- filtros (letra menor se nao couberem na largura da tela, ex.: russo)
  local I18N = require("lib.i18n")
  local ff, pad = T.f.bodyb, 18
  local total = 0
  for _, f in ipairs(FILTERS) do total = total + ff:getWidth(I18N.tr(f.label)) + pad + 5 end
  if total > T.W - 24 then ff, pad = T.f.small, 12 end
  local fx = 12
  for i, f in ipairs(FILTERS) do
    local tw = ff:getWidth(I18N.tr(f.label)) + pad
    local on = i == self.filter
    G.rect(fx, 82, tw, 24, on and T.c.accent or T.c.bg2, 12)
    G.text(ff, f.label, fx, ff == T.f.small and 88 or 85, on and T.c.bg0 or T.c.dim, "center", tw)
    fx = fx + tw + 5
  end

  -- lista
  G.panel(LIST_X, LIST_Y, LIST_W, VISIBLE * ROW_H + 8, { bg = T.c.bg1 })
  local list = self.items or {}
  if self.state == "loading" and #list == 0 then
    G.text(T.f.body, L("Carregando catálogo..."), LIST_X, LIST_Y + 150, T.c.dim, "center", LIST_W)
  elseif #list == 0 then
    local m = self.msg or (self.os_id and L("Nenhum tema do catálogo é compatível com este sistema ainda.") or L("Escolha o sistema (SELECT)."))
    G.text(T.f.small, m, LIST_X + 16, LIST_Y + 140, T.c.faint, "center", LIST_W - 32)
  end
  if self.sel <= self.scroll then self.scroll = self.sel - 1 end
  if self.sel > self.scroll + VISIBLE then self.scroll = self.sel - VISIBLE end
  for i = self.scroll + 1, math.min(#list, self.scroll + VISIBLE) do
    local th = list[i]
    local y = LIST_Y + 4 + (i - self.scroll - 1) * ROW_H
    local on = i == self.sel
    if on then G.rect(LIST_X + 4, y, LIST_W - 8, ROW_H - 4, T.c.bg3, 5); G.frame(LIST_X + 4, y, LIST_W - 8, ROW_H - 4, T.c.accent, 5, 2) end
    local ft, fs, ty, sy = G.row_fonts(ROW_H - 4, 2, 19)
    G.text_fit(ft, (self.favorites[Unified.key(th)] and "* " or "")..th.name, LIST_X + 14, y + ty, LIST_W - 130, on and T.c.text or T.c.dim)
    G.text_fit(fs, th.author or "", LIST_X + 14, y + sy, LIST_W - 120, T.c.faint)
    if th.is_local then
      local o = ES.ORIGIN[th.loc.origin] or "?"
      local ot = I18N.upper(I18N.tr(o))
      local ow = T.f.pix8:getWidth(ot) + 12
      G.tag(ot, LIST_X + LIST_W - 12 - ow, y + 4, T.c.bg3, T.c.text, T.f.pix8)
    else
      local st = self:status(th)
      local tw = T.f.pix8:getWidth(st=="unknown" and L("NÃO VERIFICADO") or st=="incompatible" and L("INCOMPATÍVEL") or ES.status_label(st)) + 12
      status_tag(st, LIST_X + LIST_W - 12 - tw, y + 4)
    end
    local es,loc = state_of(th)
    if es ~= "available" then
      local upd=loc and not th.is_local and ES.update_available(th,loc)
      local lb = require("lib.i18n").tr(upd and L("ATUALIZAR") or ES.STATE_SHORT[es])
      G.tag(lb, LIST_X + LIST_W - 12 - T.f.pix8:getWidth(lb) - 12, y + 20, upd and T.c.yellow or T.c[ES.STATE_COLOR[es]], T.c.bg0, T.f.pix8)
    end
  end

  -- pre-visualizacao do selecionado
  local px, py, pw, ph = LIST_X + LIST_W + 10, LIST_Y, T.W - (LIST_X + LIST_W + 10) - 12, VISIBLE * ROW_H + 8
  G.panel(px, py, pw, ph, { bg = T.c.bg1 })
  local th = list[self.sel]
  if th then
    local focus=self.view and self.view.theme or th
    local token=Unified.key(focus)..":"..tostring(self.view and self.view.preview or 1)
    Covers.focus_view("esthemes",token)
    self:draw_preview(th, px + 10, py + 10, pw - 20, math.floor((pw - 20) * 3 / 4))
    local y = py + 18 + math.floor((pw - 20) * 3 / 4)
    G.text_fit(T.f.h3, th.name, px + 12, y, pw - 24, T.c.text)
    y = y + 22
    local es, loc = state_of(th)
    local tw = 0
    if not th.is_local then
      local st = self:status(th)
      tw = status_tag(st, px + 12, y) + 6
    end
    G.tag(require("lib.i18n").tr(ES.STATE_LABEL[es]), px + 12 + tw, y, T.c[ES.STATE_COLOR[es]], T.c.bg0, T.f.pix8)
    y = y + 20
    local info
    if loc then
      info = L("Origem: ") .. require("lib.i18n").tr(ES.ORIGIN[loc.origin] or "?")
        .. ((not th.is_local and ES.update_available(th, loc)) and ("  •  " .. require("lib.i18n").tr(L("atualização disponível"))) or "")
    else
      info = th.gallery_size or (th.size and U.format_bytes(th.size)) or (th.updated and (L("Atualizado ") .. th.updated) or "")
    end
    if not th.is_local then
      local r = self:res_of(th)
      G.tag(self.size .. " " .. require("lib.i18n").tr(RES_LABEL[r]), px + 12, y, T.c[RES_COLOR[r]], T.c.bg0, T.f.pix8)
      y = y + 18
    end
    G.text_fit(T.f.small, info, px + 12, y, pw - 24, T.c.dim)
  end

  local hints = { { "l1", L("Filtro") } }
  if th then hints[#hints + 1] = { "a", L("Visualizar") } end
  if th and not th.is_local and not loc_of(th) and self:can_install(th) then hints[#hints + 1] = { "x", L("Instalar") } end
  if th and loc_of(th) then hints[#hints + 1] = { "y", L("Remover") } end
  hints[#hints + 1] = { "start", L("Opções") }
  hints[#hints + 1] = { "select", L("Sistema / tela") }
  hints[#hints + 1] = { "b", L("Voltar") }
  G.hints(hints)

  if self.view then self:draw_view() end
  if self.options or self.searchbox then self:draw_options() end
  if self.picker then self:draw_picker() end
end

-- ---------------------------------------------------------------------------
-- VISUALIZAR
function S:draw_view()
  local th = self.view.theme
  G.rect(0, 0, T.W, T.H, T.c.black, 0, 0.75)
  local x, y, w, h = 14, 40, T.W - 28, 404
  G.panel(x, y, w, h, { bg = T.c.bg1, border = T.c.accent, lw = 2, r = 10 })
  self:draw_preview(th, x + 14, y + 14, 300, 225,self.view.preview or 1)
  if type(th.previews)=="table" and #th.previews>1 then G.text(T.f.small,"L2/R2  "..tostring(self.view.preview or 1).."/"..math.min(3,#th.previews),x+14,y+226,T.c.text) end
  local tx, tw = x + 330, w - 344
  G.text_fit(T.f.h2, th.name, tx, y + 12, tw, T.c.text)
  local st = self:status(th)
  local es, loc = state_of(th)
  local tgw = th.is_local and 0 or (status_tag(st, tx, y + 42) + 6)
  G.tag(require("lib.i18n").tr(ES.STATE_LABEL[es]), tx + tgw, y + 42, T.c[ES.STATE_COLOR[es]], T.c.bg0, T.f.pix8)
  local yy = y + 64
  local upd, have = false, nil
  if loc and not th.is_local then upd, have = ES.update_available(th, loc) end
  local rows = {
    { L("Origem"), loc and (require("lib.i18n").tr(ES.ORIGIN[loc.origin] or "?") .. (loc.evidence and ("  (" .. require("lib.i18n").tr(loc.evidence) .. ")") or "")) or nil },
    { L("Pasta"), loc and loc.path or nil },
    { L("Instalado"), loc and (have or L("Versão desconhecida")) or nil },
    { L("Autor"), th.author }, { L("Atualizado"), th.updated and (th.updated .. (upd and ("  •  " .. require("lib.i18n").tr(L("mais novo que o instalado"))) or "")) or nil },
    { L("Tela"), (not th.is_local) and (self.size .. ": " .. require("lib.i18n").tr(RES_TEXT[self:res_of(th)])) or nil },
    { L("Funciona em"), (function()
        if th.is_local or not th.res then return nil end
        local t = {}
        for _, sz in ipairs(Gal.SIZES) do if th.res[sz] == "yes" then t[#t + 1] = sz end end
        return #t > 0 and table.concat(t, ", ") or nil
      end)() },
    { L("Fonte"), (not th.is_local) and ({ catalog = L("catálogo do R36S ROM STORE"), ["catalog+gallery"] = L("catálogo da loja + galeria OGA"),
        gallery = L("galeria OGA (ThemeMaster)"), themegallery="ThemeGallery (djparentx)", collection = L("coleção do GitHub: ") .. tostring(th.collection) })[th.src or "catalog"] or nil },
    { L("Tamanho"), (not th.is_local) and (th.size and U.format_bytes(th.size) or th.gallery_size or L("informado no download")) or nil },
    { L("Tipo"), th.weight and (require("lib.i18n").tr(th.weight) .. (th.files and (" (" .. th.files .. L(" arquivos)")) or "")) or nil },
    { "EmulationStation", (not th.is_local) and ((th.es_min or th.es_max) and ((th.es_min or "?") .. " a " .. (th.es_max or "?")) or L("versão não informada")) or nil },
  }
  if loc and loc.missing and #loc.missing > 0 then
    rows[#rows + 1] = { L("Ausentes"), table.concat(loc.missing, ", ") }
  elseif loc and not loc.xml_ok and loc.readable then
    rows[#rows + 1] = { L("Estrutura"), L("sem theme.xml") }
  end
  for _, r in ipairs(rows) do
    if r[2] then
      G.text(T.f.small, r[1], tx, yy + 1, T.c.faint)
      G.text_fit(T.f.small, tostring(r[2]), tx + 108, yy, tw - 108, T.c.text)
      yy = yy + 17
    end
  end
  yy = y + 248
  for _, l in ipairs(G.wrap(T.f.small, th["description_" .. require("lib.i18n").lang] or th.description or "", w - 28)) do
    G.text(T.f.small, l, x + 14, yy, T.c.dim); yy = yy + 15
  end
  if th.is_local then
    G.text(T.f.small, L("Tema encontrado no console (não está no catálogo da loja)."), x + 14, yy + 2, T.c.dim)
    yy = yy + 17
  elseif st == "experimental" then
    G.text(T.f.small, L("Experimental: deve funcionar neste sistema, mas ainda não foi confirmado."), x + 14, yy + 2, T.c.yellow)
    yy = yy + 17
  end
  G.text_fit(T.f.small, L("Projeto: ") .. (th.project_url or (loc and loc.git_url) or "?"), x + 14, yy + 2, w - 28, T.c.faint)
  -- botoes (conforme o estado real do tema no console)
  local btns = self:view_buttons(th)
  self.view.buttons = btns
  local bx = x + 14
  for i, b in ipairs(btns) do
    local lb = require("lib.i18n").tr(b.label)
    local bw = T.f.pix8:getWidth(lb) + 30
    local on = i == self.view.btn
    G.rect(bx, y + h - 44, bw, 30, on and T.c.accent or T.c.bg2, 6)
    if not on then G.frame(bx, y + h - 44, bw, 30, T.c.line, 6) end
    G.text(T.f.pix8, lb, bx, y + h - 33, on and T.c.bg0 or T.c.text, "center", bw)
    bx = bx + bw + 10
  end
end

-- ---------------------------------------------------------------------------
-- instalacao
function S:ask_install(th, force)
  local es, loc = state_of(th)
  if loc and not force then
    -- ja existe no console: nada de segunda instalacao
    local upd = (not th.is_local) and ES.update_available(th, loc)
    local btns = {}
    if es ~= "active" and loc.xml_ok and not loc.incomplete then btns[#btns + 1] = { label = L("ATIVAR TEMA"), fn = function() self:ask_activate(th) end } end
    local _,have=ES.update_available(th,loc)
    if not th.is_local and loc.origin~="firmware" and (upd or loc.incomplete or not have) then btns[#btns + 1] = { label = (loc.incomplete or not have) and L("REINSTALAR") or L("ATUALIZAR"), fn = function() self:ask_install(th, true) end } end
    btns[#btns + 1] = { label = L("REMOVER"), fn = function() self:ask_uninstall(th) end }
    btns[#btns + 1] = { label = "OK" }
    App.show_dialog({ title = L("Tema já instalado"), kind = "info",
      body = th.name .. L(" já está no console em:\n") .. loc.path .. L("\nOrigem: ") .. require("lib.i18n").tr(ES.ORIGIN[loc.origin] or "?")
        .. (upd and L("\n\nO catálogo tem uma versão mais nova.") or "") .. (loc.incomplete and L("\n\nA instalação está incompleta.") or "")
        .. L("\n\nNada foi baixado."),
      buttons = btns, sel = #btns })
    return
  end
  if th.is_local then return end
  if loc and loc.origin=="firmware" then App.toast(L("Tema de fábrica protegido."),"warn");return end
  if es=="unverified" and not loc then App.toast(L("A pasta de temas não pôde ser verificada."),"warn");return end
  if not self.os_id then App.toast(L("Escolha o sistema do console antes (SELECT)."), "warn"); return end
  local st = (th.compat or {})[self.os_id]
  if not self:can_install(th) then
    local a=th.download_audit
    App.toast(a and a.url==th.download_url and (a.status=="missing" or a.status=="not_zip") and L("Link de download indisponível.") or L("Este tema não é compatível com o sistema escolhido."), "error")
    return
  end
  local dir, why = self:sys_dir()
  if not dir then
    App.show_dialog({ title = L("Não é possível instalar"), kind = "error",
      body = L("A pasta de temas deste sistema não foi encontrada (") .. tostring(why) .. L(").\nNada foi alterado.") })
    return
  end
  -- reinstalar/atualizar vai para a MESMA pasta (nunca duplica o tema)
  local folder = (loc and loc.folder) or th.folder
  if loc then dir = loc.root end
  local existed=U.exec_ok("test -e "..U.shq(dir.."/"..folder))
  local unknown=Unified.needs_confirmation(th,self.os_id,self.size)
  local os_id,size=self.os_id,self.size
  local free = U.free_space(dir)
  local body = th.name .. L("\n\nDestino: ") .. dir .. "/" .. folder .. (free and (L("\nEspaço livre: ") .. U.format_bytes(free)) or "")
  if loc then
    body = body .. L("\n\nO tema já existe: a versão atual vira backup e é substituída.")
  elseif existed then
    body = body .. L("\n\nJá existe uma pasta com esse nome. Ela será guardada como backup antes da troca.")
  end
  if unknown then body = body .. L("\n\nCompatibilidade não verificada: este tema ainda não foi testado neste sistema. Pode apresentar problemas de resolução ou funcionamento no EmulationStation.")
  elseif st == "experimental" then body = body .. L("\n\nAtenção: tema EXPERIMENTAL neste sistema (ainda não confirmado).") end
  local r = self:res_of(th)
  if r ~= "yes" then body = body .. string.format(L("\n\nA galeria não confirma este tema em %s: pode ficar cortado ou esticado."), self.size) end
  body = body .. L("\n\nO tema será baixado em segundo plano pela Central de Downloads. Não será aplicado automaticamente.")
  App.show_dialog({ title = unknown and L("Compatibilidade não verificada") or L("Baixar e instalar tema?"), kind = (unknown or st=="experimental") and "warn" or "info", body = body,
    buttons = { { label = unknown and L("INSTALAR MESMO ASSIM") or L("INSTALAR"), fn = function()
      ES.queue_install(th,dir,os_id,folder,size,unknown,existed,function(ok,e)
        if ok then App.toast(th.name..L(" adicionado à Central de Downloads."),"info") else App.toast(e,"error") end
      end)
    end }, { label = L("CANCELAR") } }, sel = 2 })
end

function S:view_buttons(th)
  local b = {}
  local es, loc = state_of(th)
  if not loc then
    if not th.is_local and es ~= "unverified" and self:can_install(th) then b[#b + 1] = { id = "install", label = L("BAIXAR E INSTALAR") } end
  else
    if es ~= "active" and loc.xml_ok and not loc.incomplete then b[#b + 1] = { id = "activate", label = L("ATIVAR TEMA") } end
    local upd,have=ES.update_available(th,loc)
    if not th.is_local and loc.origin~="firmware" and loc.readable and self:can_install(th) and (loc.incomplete or upd or not have or (self.view and self.view.from_download)) then
      b[#b + 1] = { id = "reinstall", label = upd and L("ATUALIZAR") or L("REINSTALAR") }
    end
    -- Every installed item offers removal; the confirmation explains any protection.
    b[#b + 1] = { id = "remove", label = L("REMOVER") }
  end
  b[#b + 1] = { id = "back", label = L("VOLTAR") }
  return b
end

function S:ask_uninstall(th)
  if require("core.downloads").pending("estheme:"..Unified.key(th)) then App.toast(L("Aguarde ou cancele o download deste tema."),"warn");return end
  local loc = loc_of(th)
  local okr, why = ES.can_remove(loc)
  if not okr then
    if why == "active" then
      App.show_dialog({ title = L("Tema em uso"), kind = "warn",
        body = th.name .. L(" é o tema ativo do EmulationStation. Para removê-lo com segurança, ative outro tema antes."),
        buttons = { { label = L("ESCOLHER OUTRO TEMA"), fn = function()
          for i, f in ipairs(FILTERS) do if f.id == "installed" then self.filter = i end end
          self.sel, self.scroll = 1, 0
          self:refresh()
        end }, { label = L("VOLTAR") } }, sel = 1 })
    else
      App.show_dialog({ title = L("Não removido"), kind = "error", body = why })
    end
    return
  end
  App.show_dialog({ title = L("Remover tema?"), kind = "warn",
    body = th.name .. L("\n\nPasta: ") .. loc.path .. L("\nOrigem: ") .. require("lib.i18n").tr(ES.ORIGIN[loc.origin] or "?")
      .. L("\n\nA pasta inteira do tema será apagada. Arquivos externos apontados por links internos serão preservados. O tema ativo e os temas de fábrica continuam protegidos."),
    buttons = { { label = L("REMOVER"), fn = function()
      local ok, e = ES.remove(loc)
      if ok then App.toast(th.name .. L(" removido."), "ok"); self:rescan()
      else App.show_dialog({ title = L("Não removido"), kind = "error", body = e }) end
    end }, { label = L("CANCELAR") } }, sel = 2 })
end

function S:ask_activate(th)
  local d=require("core.downloads")
  if d.active() or d.waiting_count()>0 then App.toast(L("Termine os downloads antes de ativar um tema."),"warn");return end
  local loc = loc_of(th)
  if not loc then return end
  App.show_dialog({ title = L("Ativar tema?"), kind = "info",
    body = th.name .. L("\n\nO tema é ativado pelo próprio EmulationStation (opção ThemeSet do es_settings.cfg, a mesma do menu Configurações da interface > Tema).")
      .. L("\n\nPara isso o R36S ROM STORE fecha e o EmulationStation reinicia. Uma cópia do es_settings.cfg é guardada antes da troca.")
      .. (ES.active and (L("\n\nTema atual: ") .. ES.active) or ""),
    buttons = { { label = L("ATIVAR E REINICIAR"), fn = function()
      if d.active() or d.waiting_count()>0 then App.toast(L("Termine os downloads antes de ativar um tema."),"warn");return end
      local ok, e = ES.request_activate(loc)
      if not ok then App.show_dialog({ title = L("Não ativado"), kind = "error", body = e }); return end
      App.request_es_restart()
    end }, { label = L("CANCELAR") } }, sel = 2 })
end

function S:check_theme_updates()
  if not ES.check_updates(true,function(n,failed,total)
    App.toast(tostring(n).." "..L("atualizações disponíveis")..(failed>0 and (" • "..failed.." "..L("não verificados")) or ""),failed>0 and "warn" or "info")
  end) then App.toast(L("Verificação em andamento."),"info") end
end

function S:update_all_themes()
  local D=require("core.downloads")
  local plans={}
  for _,th in ipairs(ES.update_list()) do
    local loc=ES.local_for(th)
    local _,_,rev=ES.update_available(th,loc)
    if loc and rev and self:can_install(th) and not D.pending("estheme:"..Unified.key(th)) then
      plans[#plans+1]={theme=ES.download_snapshot(th,rev),dir=loc.root,folder=loc.folder,unknown=Unified.needs_confirmation(th,self.os_id,self.size)}
    end
  end
  if #plans==0 then App.toast(L("Nenhuma atualização instalável disponível."),"info");return end
  local os_id,size=self.os_id,self.size
  App.show_dialog({title=L("Atualizar todos os temas?"),kind="warn",
    body=tostring(#plans).." "..L("temas serão atualizados em segundo plano. Temas experimentais ou não verificados podem apresentar falhas. A versão anterior será guardada. Nenhum tema será ativado automaticamente."),
    buttons={{label=L("ATUALIZAR TODOS"),fn=function()
      local n=0
      for _,p in ipairs(plans) do if D.enqueue_theme(p.theme,p.dir,os_id,p.folder,size,p.unknown,true) then n=n+1 end end
      App.toast(tostring(n).." "..L("adicionados à Central de Downloads."),"info")
    end},{label=L("CANCELAR")}},sel=2})
end

function S:update()
  local checked=ES.update_revision or 0
  if self.update_revision~=checked then self.update_revision=checked;self:refresh() end
  local revision=ES.install_revision or 0
  if self.install_revision~=revision then
    self.install_revision=revision
    local view=self.view
    self:rescan()
    if view then
      for _,th in ipairs(ES.themes or {}) do
        if Unified.key(th)==Unified.key(view.theme) then view.theme=th;break end
      end
      self.view=view
    end
  end
  -- Wait for the initial scan and only confirm on the active screen.
  if self.retry_theme_key and not App.dialog and App.current()==self then
    local key=self.retry_theme_key
    self.retry_theme_key=nil
    for _,th in ipairs(ES.themes or {}) do
      if Unified.key(th)==key then self:ask_install(th,true);return end
    end
    App.toast(L("Origem indisponível no catálogo atual."),"warn")
  elseif self.download_key and not ES.loading and self.state=="ready" and not App.dialog and App.current()==self and not self.download_key_notified then
    self.download_key_notified=true
    App.toast(L("Tema não encontrado no catálogo atual."),"warn")
  end
end

function S:draw_options()
  G.rect(0,0,T.W,T.H,T.c.black,0,0.8)
  local x,y,w,h=30,65,T.W-60,350
  G.panel(x,y,w,h,{bg=T.c.bg1,border=T.c.accent})
  if self.searchbox then
    G.text(T.f.h3,L("Pesquisar"),x+12,y+12,T.c.text)
    G.text_fit(T.f.bodyb,self.searchbox.q,x+12,y+45,w-24,T.c.text)
    local kw=(w-24)/10
    for i,k in ipairs(SEARCH_KEYS) do
      local xx=x+12+((i-1)%10)*kw
      local yy=y+83+math.floor((i-1)/10)*43
      G.rect(xx,yy,kw-3,38,i==self.searchbox.sel and T.c.accent or T.c.bg2,4)
      G.text(T.f.bodyb,k==" " and "_" or k,xx,yy+9,i==self.searchbox.sel and T.c.bg0 or T.c.text,"center",kw-3)
    end
    G.text(T.f.small,L("A Digitar • B Voltar • OK Pesquisar"),x+12,y+h-34,T.c.dim)
    return
  end
  G.text(T.f.h3,L("Opções"),x+12,y+10,T.c.text)
  local names={L("Pesquisar")..": "..(self.query or ""),L("Filtro")..": "..L(SECONDARY[self.options.secondary][2]),L("Ordenação")..": "..self.sort,L("Favoritos"),L("Atualizar catálogo"),L("Limpar filtros"),L("Verificar atualizações"),L("Atualizar todos"),L("Voltar")}
  for i,label in ipairs(names) do
    local yy=y+40+(i-1)*33
    if self.options.sel==i then G.rect(x+8,yy,w-16,30,T.c.bg3,4);G.frame(x+8,yy,w-16,30,T.c.accent,4) end
    G.text_fit(T.f.body,label,x+16,yy+5,w-32,T.c.text)
  end
end
function S:options_action(act)
  if self.searchbox then
    local q=self.searchbox
    if act=="b" then self.searchbox=nil
    elseif act=="left" then q.sel=(q.sel-2)%40+1
    elseif act=="right" then q.sel=q.sel%40+1
    elseif act=="up" then q.sel=(q.sel-11)%40+1
    elseif act=="down" then q.sel=(q.sel+9)%40+1
    elseif act=="a" then
      local k=SEARCH_KEYS[q.sel]
      if k=="OK" then self.query=q.q;self.searchbox=nil;self.options=nil;self.sel,self.scroll=1,0;self:refresh()
      elseif k=="<" then q.q=q.q:sub(1,-2)
      elseif #q.q<48 then q.q=q.q..k end
    end
    return
  end
  local o=self.options
  if act=="b" then self.options=nil
  elseif act=="up" then o.sel=(o.sel-2)%9+1
  elseif act=="down" then o.sel=o.sel%9+1
  elseif act=="a" or act=="left" or act=="right" then
    if o.sel==2 then o.secondary=(o.secondary-1+(act=="left" and -1 or 1))%#SECONDARY+1;self.secondary=SECONDARY[o.secondary][1];self.sel,self.scroll=1,0;self:refresh()
    elseif o.sel==3 then self.sort=self.sort=="az" and "za" or "az";self.sel,self.scroll=1,0;self:refresh()
    elseif act=="a" then
      if o.sel==1 then self.searchbox={q=self.query or "",sel=1}
      elseif o.sel==4 then local th=(self.items or {})[self.sel];if th then self:favorite(th) end;self.options=nil
      elseif o.sel==5 then self.options=nil;ES.refresh_gallery(true,function()self:refresh()end)
      elseif o.sel==6 then self.secondary,self.sort,self.query="all","az","";self.options=nil;self.sel,self.scroll=1,0;self:refresh()
      elseif o.sel==7 then self.options=nil;self:check_theme_updates()
      elseif o.sel==8 then self.options=nil;self:update_all_themes()
      else self.options=nil end
    end
  end
end

-- START is routed by main.lua to on_start before normal screen actions.
-- Keep the global download shortcut unchanged on all other screens.
function S:on_start()
  self:action("start")
end

function S:action(act)
  if self.options or self.searchbox then self:options_action(act);return end
  if self.picker and (act == "left" or act == "right") then
    self.picker.tab = self.picker.tab == 1 and 2 or 1
    return
  end
  if self.picker and self.picker.tab == 2 then
    local p = self.picker
    local n = #Gal.SIZES
    if act == "up" then p.ssel = (p.ssel - 2) % n + 1
    elseif act == "down" then p.ssel = p.ssel % n + 1
    elseif act == "a" then
      self.size = Gal.SIZES[p.ssel]
      self.size_auto = false
      pcall(love.filesystem.write, SIZE_FILE, self.size)
      self.picker = nil
      self.sel, self.scroll = 1, 0
      self:refresh()
    elseif act == "b" then self.picker = nil end
    return
  end
  if self.picker then
    local p = self.picker
    local n = #p.ids
    if act == "up" and n > 0 then p.sel = (p.sel - 2) % n + 1
    elseif act == "down" and n > 0 then p.sel = p.sel % n + 1
    elseif act == "a" and n > 0 then
      local id = p.ids[p.sel]
      self.manual = not (self.os.confirmed and id == self.os.id)
      self.os_id = id
      self.picker = nil
      self.sel, self.scroll = 1, 0
      self:rescan()
    elseif act == "b" then
      self.picker = nil

    end
    return
  end
  if self.view then
    local v = self.view
    local n = #(v.buttons or { 1, 2 })
    if (act=="l2" or act=="r2") and type(v.theme.previews)=="table" and #v.theme.previews>1 then
      v.preview=((v.preview or 1)-1+(act=="l2" and -1 or 1))%math.min(3,#v.theme.previews)+1
      Covers.reset_pending()
    elseif act == "left" then v.btn = math.max(1, v.btn - 1)
    elseif act == "right" then v.btn = math.min(n, v.btn + 1)
    elseif act == "b" then
      self.view=nil
      if v.from_download then App.pop() end
    elseif act == "a" then
      local b = v.buttons and v.buttons[v.btn]
      local th = v.theme
      self.view = nil
      if not b or b.id == "back" then if v.from_download then App.pop() end;return
      elseif b.id == "remove" then self:ask_uninstall(th)
      elseif b.id == "activate" then self:ask_activate(th)
      elseif b.id == "reinstall" then self:ask_install(th, true)
      else self:ask_install(th) end
    end
    return
  end
  local list = self.items or {}
  local th = list[self.sel]
  if act == "up" and #list > 0 then self.sel = (self.sel - 2) % #list + 1
  elseif act == "down" and #list > 0 then self.sel = self.sel % #list + 1
  elseif act == "left" then self.sel = math.max(1, self.sel - VISIBLE)
  elseif act == "right" then self.sel = math.min(math.max(1, #list), self.sel + VISIBLE)
  elseif act == "l1" or act == "r1" then
    self.filter = (self.filter - 1 + (act == "l1" and -1 or 1)) % #FILTERS + 1
    self.sel, self.scroll = 1, 0
    Covers.reset_pending()
    self:refresh()
  elseif act == "start" then
    local n=1;for i,v in ipairs(SECONDARY) do if v[1]==self.secondary then n=i end end
    self.options={sel=1,secondary=n}
  elseif act == "select" then self:open_picker()
  elseif act == "a" and th then self.view = { theme = th, btn = 1 }
  elseif act == "x" and th then self:ask_install(th)
  elseif act == "y" and th and loc_of(th) then self:ask_uninstall(th)
  elseif act == "y" and th then self:favorite(th)
  elseif act == "b" then App.pop()
  end
end

return S
