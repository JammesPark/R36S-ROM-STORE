-- =============================================================================
--  Central de Downloads em Segundo Plano (START ou menu principal)
--  Mostra a fila, o progresso real (download, extracao, instalacao) e o
--  historico salvo. A mesma tela e os mesmos dados para os dois acessos.
--  A: abrir detalhes diretamente | Y: informações e ações | X: limpar histórico
--  B: voltar
-- =============================================================================
local L = require("lib.i18n").L
local T = require("ui.theme")
local G = require("ui.gfx")
local U = require("lib.util")
local Downloads = require("core.downloads")
local Catalog = require("core.catalog")
local Covers = require("core.covers")
local Icons = require("ui.icons")
local lg = love.graphics

local S = {}
local ROW_H, LIST_Y, VISIBLE = 92, 48, 4

local STATE = {
  waiting = { "AGUARDANDO", T.c.dim }, downloading = { L("BAIXANDO"), T.c.accent2 },
  extracting = { L("EXTRAINDO"), T.c.yellow }, installing = { L("INSTALANDO"), T.c.orange },
  done = { "CONCLUÍDO", T.c.green }, error = { "ERRO", T.c.red }, cancelled = { "CANCELADO", T.c.faint },
}
local STAGE_LABEL = { download = L("DOWNLOAD"), extract = L("EXTRAÇÃO"), install = L("INSTALAÇÃO") }

function S:enter() self.sel, self.scroll = 1, 0 end

function S:clamp()
  local n = #Downloads.list
  self.sel = U.clamp(self.sel, 1, math.max(1, n))
  if self.sel <= self.scroll then self.scroll = self.sel - 1 end
  if self.sel > self.scroll + VISIBLE then self.scroll = self.sel - VISIBLE end
  self.scroll = U.clamp(self.scroll, 0, math.max(0, n - VISIBLE))
end

function S:update() self:clamp() end

--- port do catalogo (para capa e para conferir se esta instalado)
local function port_of(e) if e.section=="themes" then return nil end; return e.port or (e.pid and Catalog.by_id[e.pid]) end

--- linha de numeros reais da etapa atual / resultado final
local function detail_line(e)
  if e.state == "error" then return (e.error and (require("lib.i18n").tr(e.error):gsub("\n", " "))) or L("Erro desconhecido.") end
  if e.state == "cancelled" then return L("Cancelado") .. (e.date and (L(" em ") .. e.date) or "") end
  if e.state == "waiting" then return L("Na fila: começa quando a operação atual terminar.") end
  if e.state == "done" then
    local parts = { L("Concluído") .. (e.date and (L(" em ") .. e.date) or "") }
    if e.dl_total and e.dl_total > 0 then parts[#parts + 1] = U.format_bytes(e.dl_total) end
    if e.avg and e.avg > 0 then parts[#parts + 1] = L("média ") .. U.format_speed(e.avg) end
    if e.elapsed then parts[#parts + 1] = L("tempo ") .. U.format_time(e.elapsed) end
    return table.concat(parts, "  •  ")
  end
  local parts = {}
  if e.phase == "download" then
    if e.total and e.total > 0 then
      parts[#parts + 1] = U.format_bytes(e.done) .. L(" de ") .. U.format_bytes(e.total)
    else
      parts[#parts + 1] = U.format_bytes(e.done or 0) .. L(" baixados (tamanho total desconhecido)")
    end
    if e.speed and e.speed > 0 then parts[#parts + 1] = U.format_speed(e.speed) end
    if e.eta then parts[#parts + 1] = L("faltam ") .. U.format_time(e.eta) end
  elseif e.phase == "extract" and e.total and e.total > 0 then
    parts[#parts + 1] = string.format(L("%d de %d itens extraídos"), e.done or 0, e.total)
  elseif e.phase == "install" and e.total and e.total > 0 then
    parts[#parts + 1] = string.format(L("%d de %d itens instalados"), e.done or 0, e.total)
  elseif e.phase == "verify" then parts[#parts + 1] = L("Verificando o arquivo baixado")
  elseif e.phase == "analyze" then parts[#parts + 1] = L("Analisando a estrutura do pacote")
  else parts[#parts + 1] = L("Preparando") end
  return table.concat(parts, "  •  ")
end

--- tres etapas lado a lado: pendente / em andamento (%) / concluida / pulada / falhou
local function draw_stages(e, x, y, w)
  local gap = 6
  local sw = math.floor((w - gap * 2) / 3)
  for i, k in ipairs(Downloads.STAGES) do
    local st = e.stages and e.stages[k]
    local sx = x + (i - 1) * (sw + gap)
    local label, c, txt
    local s = st and st.state or (e.state == "waiting" and "pending" or nil)
    if s == "ok" then c, txt = T.c.green, st.pct and (st.pct .. "%") or "OK"
    elseif s == "active" then c, txt = STATE[e.state] and STATE[e.state][2] or T.c.accent2, st.pct and (st.pct .. "%") or "..."
    elseif s == "skip" then c, txt = T.c.faint, L("PULADA")
    elseif s == "fail" then c, txt = T.c.red, L("FALHOU")
    elseif s == "cancel" then c, txt = T.c.faint, L("PARADA")
    else c, txt = T.c.faint, "—" end
    label = STAGE_LABEL[k]
    G.rect(sx, y, sw, 18, T.c.bg0, 4)
    if s == "active" and st.pct then G.rect(sx, y, sw * st.pct / 100, 18, c, 4, 0.35) end
    if s == "ok" then G.rect(sx, y, sw, 18, c, 4, 0.18) end
    G.frame(sx, y, sw, 18, s and s ~= "pending" and c or T.c.line, 4)
    G.text(T.f.pix8, label, sx + 6, y + 5, c)
    G.text(T.f.pix8, txt, sx + sw - 6 - T.f.pix8:getWidth(txt), y + 5, c)
  end
end

function S:draw()
  local active = Downloads.active()
  local right = active and L("1 em andamento") or L("nada em andamento")
  local w = Downloads.waiting_count()
  if w > 0 then right = right .. string.format(L("  •  %d na fila"), w) end
  G.header(L("Downloads em segundo plano"), right)
  local list = Downloads.list
  if #list == 0 then
    G.panel(12, LIST_Y + 4, T.W - 24, 380, { bg = T.c.bg1 })
    G.text(T.f.pix16, L("NENHUM DOWNLOAD"), 12, LIST_Y + 150, T.c.dim, "center", T.W - 24)
    G.text(T.f.body, L("Downloads, extrações e instalações feitos pelo hub aparecem aqui.\nPressione START em qualquer tela para voltar a esta central."),
      30, LIST_Y + 180, T.c.faint, "center", T.W - 60)
    G.hints({ { "b", L("Voltar") } })
    return
  end
  for i = self.scroll + 1, math.min(#list, self.scroll + VISIBLE) do
    local e = list[i]
    local y = LIST_Y + 4 + (i - self.scroll - 1) * (ROW_H + 4)
    local on = i == self.sel
    local st = STATE[e.state] or { e.state, T.c.dim }
    local c = st[2]
    G.panel(12, y, T.W - 24, ROW_H, { bg = on and T.c.bg3 or T.c.bg1, border = on and T.c.accent or T.c.line, lw = on and 2 or 1 })
    G.rect(12, y + 8, 4, ROW_H - 16, c, 2)
    -- capa ou icone
    local p = port_of(e)
    if p and (p.cover or "") ~= "" then
      G.cover(Covers.get(p), p, 24, y + 8, 40, 54, false, App.t)
    else
      G.rect(24, y + 8, 40, 54, T.c.bg0, 5)
      G.frame(24, y + 8, 40, 54, e.section == "tools" and T.c.green or T.c.accent, 5)
      Icons.draw(e.section == "tools" and "tools" or "download", 32, y + 23, e.section == "tools" and T.c.green or T.c.accent, 1)
    end
    -- nome + tipo de operacao
    local tx = 74
    G.text_fit(T.f.bodyb, e.name, tx, y + 5, T.W - 230, T.c.text)
    G.text_fit(T.f.small, e.op or Downloads.op_label(nil, e.section), tx, y + 23, T.W - 230, T.c.faint)
    -- estado + porcentagem real
    local pct = Downloads.percent(e)
    local lbl = pct and e.job and (st[1] .. " — " .. pct .. "%") or st[1]
    G.text(T.f.pix8, lbl, T.W - 26 - T.f.pix8:getWidth(lbl), y + 9, c)
    -- selo INSTALADO so depois da instalacao concluida e validada
    if e.state == "done" and p and (e.op or ""):find("instala") and App.status(p) ~= "none" then
      G.tag(L("INSTALADO"), T.W - 26 - T.f.pix8:getWidth("INSTALADO") - 12, y + 24, T.c.green, T.c.bg0)
    end
    -- barra da etapa atual
    if e.job then
      if pct then G.progress(tx, y + 44, T.W - tx - 26, 8, pct / 100, c)
      else G.progress_busy(tx, y + 44, T.W - tx - 26, 8, App.t, c) end
      G.text_fit(T.f.small, detail_line(e), tx, y + 54, T.W - tx - 26, T.c.dim)
      draw_stages(e, tx, y + 70, T.W - tx - 26)
    else
      G.text_fit(T.f.small, detail_line(e), tx, y + 46, T.W - tx - 26, e.state == "error" and T.c.red or T.c.dim)
      if e.stages and next(e.stages) then draw_stages(e, tx, y + 66, T.W - tx - 26) end
    end
  end
  -- barra de rolagem
  if #list > VISIBLE then
    local track = VISIBLE * (ROW_H + 4) - 4
    local h = math.max(20, track * VISIBLE / #list)
    G.rect(T.W - 8, LIST_Y + 4 + (track - h) * (self.scroll / (#list - VISIBLE)), 3, h, T.c.accent2, 1, 0.7)
  end
  local sel = list[self.sel]
  local hints = { { "dpad", L("Navegar") } }
  if sel then
    hints[#hints+1]={"a",L("Detalhes")}
    hints[#hints+1]={"y",sel.job and L("Ações") or sel.state=="waiting" and L("Ações") or L("Informações")}
  end
  if Downloads.history_count() > 0 then hints[#hints + 1] = { "x", L("Limpar histórico") } end
  hints[#hints + 1] = { "b", L("Voltar") }
  G.hints(hints)
end

-- Details are available for every record, including legacy entries without a source.
-- All actions re-check live state; downloads continue while this dialog is open.
function S:information(e)
  local body={e.name or "?",e.op or Downloads.op_label(nil,e.section),
    L("Status")..": "..(Downloads.LABEL[e.state] or e.state or "?")}
  if e.date then body[#body+1]=L("Data")..": "..e.date end
  if e.dl_total and e.dl_total>0 then body[#body+1]=L("Tamanho")..": "..U.format_bytes(e.dl_total) end
  body[#body+1]=detail_line(e)
  local buttons={}
  local function add(label,fn) buttons[#buttons+1]={label=L(label),fn=fn} end
  local screen,params=Downloads.target(e,Catalog)
  if screen then
    add(screen=="files" and "Abrir gerenciador de arquivos" or screen=="bios" and "Abrir BIOS" or screen=="pmmanager" and "Abrir PortMaster" or "Abrir detalhes",function() App.push(screen,params) end)
  elseif not e.job and e.state~="waiting" then
    body[#body+1]=L("Origem indisponível no catálogo atual.")
  end
  if e.job then
    if not e.ext then
      add("Ver progresso",function() if e.job and not e.job.finished then e.job.background=false;Downloads.background=false end end)
    end
    if not e.job.finished and (e.phase=="download" or (not e.ext and e.job.phase=="download")) and (not e.ext or e.cancel_fn) then
      add("Cancelar download",function()
        if not e.job or e.job.finished or (e.phase~="download" and (e.ext or e.job.phase~="download")) then return end
        App.show_dialog({title=L("Cancelar download?"),kind="warn",body=e.name,
          buttons={{label=L("CANCELAR DOWNLOAD"),fn=function() if e.job and not e.job.finished and (e.phase=="download" or (not e.ext and e.job.phase=="download")) then Downloads.cancel(e) end end},{label=L("VOLTAR")}},sel=2})
      end)
    end
  elseif e.state=="waiting" then
    add("Tirar da fila",function()
      if e.state~="waiting" then return end
      App.show_dialog({title=L("Tirar da fila?"),kind="warn",body=e.name..L(" será retirado da fila. Nada foi baixado ainda."),
        buttons={{label=L("TIRAR DA FILA"),fn=function() if e.state=="waiting" then Downloads.cancel(e) end end},{label=L("VOLTAR")}},sel=2})
    end)
  elseif screen=="details" or screen=="esthemes" then
    add("Baixar novamente",function()
      if Downloads.pending(e.pid) then App.toast(L("Já está na Central de Downloads."),"warn");return end
      local dest,arg=Downloads.target(e,Catalog)
      if dest=="details" then App.install(arg.port,{})
      elseif dest=="esthemes" then arg.download_retry=true;App.push(dest,arg)
      else App.toast(L("Origem indisponível no catálogo atual."),"warn") end
    end)
  end
  add("VOLTAR")
  App.show_dialog({title=L("Informações"),kind=e.state=="error" and "warn" or "info",body=table.concat(body,"\n"),list=true,buttons=buttons,sel=1})
end

function S:action(act)
  local list = Downloads.list
  local n = #list
  local e = list[self.sel]
  if act == "up" and n > 0 then self.sel = math.max(1, self.sel - 1)
  elseif act == "down" and n > 0 then self.sel = math.min(n, self.sel + 1)
  elseif act == "b" then App.pop()
  elseif act=="a" and e then
    local screen,params=Downloads.target(e,Catalog)
    if screen then App.push(screen,params) else self:information(e) end
  elseif act=="y" and e then
    self:information(e)
  elseif act == "x" then
    local h = Downloads.history_count()
    if h == 0 then App.toast(L("O histórico já está vazio."), "info"); return end
    App.show_dialog({
      title = L("Limpar histórico?"), kind = "warn",
      body = string.format(L("%d registro(s) de downloads finalizados serão apagados desta lista.\n\n")
        .. L("Somente o histórico é limpo: jogos instalados e arquivos não são apagados, e downloads em andamento ou na fila continuam."), h),
      buttons = { { label = "LIMPAR", fn = function()
        Downloads.clear_history()
        self.sel, self.scroll = 1, 0
        App.toast(L("Histórico de downloads limpo."), "ok")
      end }, { label = "VOLTAR" } },
      sel = 2,
    })
  end
  self:clamp()
end

return S
