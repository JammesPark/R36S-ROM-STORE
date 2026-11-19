-- R36S ROMS STORE: versao modificada em 2026-11-15. GPL-3.0.
-- Base: R36S PORT HUB, por Lag do Lira (creditos em NOTICE.md).
-- =============================================================================
--  Sobre o projeto
--  Topo fixo: logo do app + versao | botao do Telegram com identidade propria
--  Abaixo: texto de apresentacao rolavel (cima/baixo, L1/R1), dados do catalogo
--  e o aviso de direitos autorais no final.
--  A = Telegram | START = Apoiar via LivePix (James Park) | B = voltar
-- =============================================================================
local L = require("lib.i18n").L
local I18N = require("lib.i18n")
local T = require("ui.theme")
local G = require("ui.gfx")
local C = require("config")
local Catalog = require("core.catalog")
local lg = love.graphics

local S = {}

local CHANNEL_NAME = "James Park"
local CHANNEL_URL = "https://t.me/R36SPORTSBR"
local CHANNEL_SHORT = "t.me/R36SPORTSBR"
local QR_ASSET = "assets/qr/telegram_r36sportsbr.png"
local TELEGRAM_ICON = "assets/icons/telegram_official.png"

-- Apoio ao projeto (START): apenas link do LivePix do James Park, nao Pix copia-e-cola.
local SUPPORT_URL = "https://livepix.gg/jammespark"
local SUPPORT_SHORT = "livepix.gg/jammespark"
local SUPPORT_QR_ASSET = "assets/qr/livepix_jammespark.png"
local SUPPORT_TEXT = L("Esta loja é gratuita. Se ela ajudou você, considere apoiar o desenvolvimento da R36S ROMS STORE & HUB.")
local SUPPORT_HOW = L("Leia o QR Code com a câmera do celular para abrir livepix.gg/jammespark. Escolha o valor e conclua o apoio no site. Este não é um QR Pix de pagamento direto.")

-- Credito preservado conforme a licenca GPL-3.0 e o pedido do autor da base.
local TITLE = L("Sobre a R36S ROMS STORE")
local PARAGRAPHS = {
  L("R36S ROMS STORE é uma loja independente de ports e ferramentas para o console R36S."),
  L("Baseado no R36S PORT HUB, por Lag do Lira"),
  L("Canal do autor da base: https://youtube.com/@lagdolira"),
  L("Esta é uma versão modificada, com identidade e manutenção próprias. Não é um lançamento oficial do autor da base."),
  L("Software distribuído sob GNU GPL-3.0. Você pode estudar, modificar e redistribuir o código-fonte sob os termos da licença."),
  L("Não há garantia; consulte LICENSE e os avisos de autoria e de terceiros incluídos no pacote."),
}
local MOTTO = L("PROJETO INDEPENDENTE · SOFTWARE LIVRE")
local DISCLAIMER = {
  L("Os créditos de autoria do projeto base e as licenças dos componentes de terceiros devem ser preservados."),
  L("Esta loja não possui vínculo oficial com fabricantes, PortMaster ou desenvolvedores de jogos e ports de terceiros."),
  L("Use apenas conteúdos que você tenha direito de baixar ou distribuir."),
}

local VIEW_X, VIEW_Y, VIEW_W, VIEW_H = 20, 152, T.W - 40, 286
local TEXT_W = VIEW_W - 44

-- Marca do mantenedor mostrada ao lado do cartao do Telegram no cabecalho.
-- O arquivo ja esta incluido no pacote, mas precisa ser desenhado nesta tela.
local dev_logo
local function get_dev_logo()
  if dev_logo == nil then
    local ok, img = pcall(lg.newImage, "assets/logo/dev_logo.png")
    dev_logo = (ok and img) or false
    if dev_logo then dev_logo:setFilter("linear", "linear") end
  end
  return dev_logo or nil
end

function S:enter()
  self.scroll = 0
  self.qr = nil          -- matriz do QR Code (gerada so quando o usuario pede)
  self.show_qr = false
  self.qr_big = false
  self.show_pix = false
  self.pix_big = false
  self.pix_qr = nil
  self.pix_qr_image = nil
  local ok_pix, pix_img = pcall(love.graphics.newImage, SUPPORT_QR_ASSET)
  if ok_pix and pix_img then
    pix_img:setFilter("nearest", "nearest")
    self.pix_qr_image = pix_img
  end
  -- QR estatico embutido, para funcionar sem Wi-Fi e sem depender de navegador.
  self.qr_image = nil
  local ok, img = pcall(love.graphics.newImage, QR_ASSET)
  if ok and img then
    img:setFilter("nearest", "nearest")
    self.qr_image = img
  end
  self:layout()
end

--- monta a lista de blocos do conteudo rolavel (texto quebrado para a largura)
function S:layout()
  local blocks = {}
  local function add(kind, font, text, color, gap)
    local lines = G.wrap(font, text, TEXT_W)
    blocks[#blocks + 1] = { kind = kind, font = font, lines = lines, color = color, gap = gap or 0 }
  end
  add("text", T.f.h3, TITLE, T.c.accent2, 6)
  for _, p in ipairs(PARAGRAPHS) do add("text", T.f.body, p, T.c.text, 10) end
  add("text", T.f.pix8, MOTTO, T.c.accent, 16)
  blocks[#blocks + 1] = { kind = "info", gap = 16 }
  add("text", T.f.pix8, L("AVISO"), T.c.yellow, 6)
  for i, p in ipairs(DISCLAIMER) do add("text", T.f.small, p, T.c.dim, i < #DISCLAIMER and 6 or 0) end
  -- altura total
  local h = 10
  for _, b in ipairs(blocks) do
    if b.kind == "info" then
      b.h = 4 * G.step(T.f.small, 17)
    else
      local lh = b.font:getHeight() * b.font:getLineHeight()
      if b.font == T.f.pix8 then lh = 14 end
      b.lh = lh
      b.h = #b.lines * lh
    end
    h = h + b.h + b.gap
  end
  self.blocks = blocks
  self.content_h = h + 6
  self.max_scroll = math.max(0, self.content_h - VIEW_H)
end

-- Icone oficial do Telegram fornecido para esta loja. Cache evita carregar a imagem a cada frame.
-- Em caso de asset ausente, usamos uma alternativa vetorial simples.
local telegram_icon_image
local function telegram_icon(x, y, w, h)
  if telegram_icon_image == nil then
    local ok, image = pcall(lg.newImage, TELEGRAM_ICON)
    telegram_icon_image = (ok and image) or false
    if telegram_icon_image then telegram_icon_image:setFilter("linear", "linear") end
  end
  if telegram_icon_image then
    local iw, ih = telegram_icon_image:getDimensions()
    local size = math.min(w, h)
    local px = x + (w - size) / 2
    local py = y + (h - size) / 2
    lg.setColor(1, 1, 1, 1)
    lg.draw(telegram_icon_image, px, py, 0, size / iw, size / ih)
  else
    local cx, cy, r = x + w/2, y + h/2, math.min(w, h)*0.48
    lg.setColor(0.13, 0.67, 0.89, 1)
    lg.circle("fill", cx, cy, r, 40)
    lg.setColor(1, 1, 1, 1)
    lg.polygon("fill", cx-r*.70, cy-r*.06, cx+r*.75, cy-r*.62,
      cx+r*.33, cy+r*.67, cx-r*.10, cy+r*.23)
  end
end

function S:draw()
  G.header(L("Sobre o projeto"))

  -- topo fixo: marca propria e link de credito ao autor da base
  G.panel(20, 50, T.W - 40, 96, { bg = T.c.bg1 })
  -- Usa a arte propria da tela Sobre, ampliada ~13% sem deformar e sem
  -- invadir o painel do Telegram (inicio x=168). A anterior, "splash" x0.48,
  -- parecia menor por conter excesso de margem transparente vertical.
  -- Painel esquerdo x20..167; arte x26..163, y66..130.
  G.logo(26, 66, "about", 1.04)

  -- Logo James Park, como no Sobre da base original (posicao direita).
  local img = get_dev_logo()
  if img then
    lg.setColor(1, 1, 1, 1)
    local ds = 1.18
    local panel_y, panel_h = 50, 96
    local iy = panel_y + math.floor((panel_h - img:getHeight() * ds) / 2) - 3
    lg.draw(img, T.W - 24 - img:getWidth() * ds, iy, 0, ds, ds)
  end

  -- Cartao proprio do Telegram; o botao A abre o QR Code na tela.
  T.with_base_fonts(self.draw_channel, self)

  -- conteudo rolavel
  self:draw_content()
end

function S:draw_channel()
  local bx, by, bw, bh = 168, 64, 300, 68
  local pulse = App.pulse(0.25, 0.15, 4)
  G.rect(bx - 3, by - 3, bw + 6, bh + 6, T.c.accent, 12, pulse)
  G.rect(bx, by, bw, bh, T.c.bg3, 10)
  G.frame(bx, by, bw, bh, T.c.accent, 10, 2)
  telegram_icon(bx + 12, by + 12, 46, 44)
  G.text_fit(T.f.bodyb, L("Siga nosso canal no Telegram"), bx + 68, by + 7, bw - 76, T.c.text)
  G.text(T.f.bodyb, CHANNEL_NAME, bx + 68, by + 27, T.c.text)
  G.text_fit(T.f.small, CHANNEL_SHORT, bx + 68, by + 47, 142, T.c.accent2)
  G.button_icon("a", bx + 218, by + 45)
  G.text_fit(T.f.small, L("Abrir canal"), bx + 240, by + 47, bw - 245, T.c.faint)
  -- START volta a ter a funcao de apoio, sem mexer no atalho A do Telegram.
  local sx, sy = bx + 188, by + 27
  local sw = G.button_icon("start", sx, sy, T.c.yellow)
  G.text_fit(T.f.small, L("Apoiar"), sx + sw + 5, sy + 1, bw - (sx - bx) - sw - 12, T.c.yellow)
end

function S:draw_content()
  G.panel(VIEW_X, VIEW_Y, VIEW_W, VIEW_H, { bg = T.c.bg1 })
  G.clip(VIEW_X + 2, VIEW_Y + 2, VIEW_W - 4, VIEW_H - 4)
  local y = VIEW_Y + 10 - self.scroll
  local x = VIEW_X + 20
  for _, b in ipairs(self.blocks) do
    if y + b.h >= VIEW_Y and y <= VIEW_Y + VIEW_H then
      if b.kind == "info" then
        G.rect(x, y - 8, TEXT_W, 1, T.c.line)
        local info = {
          { L("Pasta de ports"), C.PORTS_DIR },
          { L("Catálogo"), Catalog.source_label() .. string.format(" (%d ports)", #Catalog.ports) },
          { L("Fonte online"), Catalog.remote_url or L("não configurada") },
          { L("Atualizado em"), Catalog.updated ~= "" and Catalog.updated or "—" },
        }
        local st = G.step(T.f.small, 17)
        for i, row in ipairs(info) do
          G.text_fit(T.f.small, row[1], x, y + (i - 1) * st, 114, T.c.faint)
          G.text_fit(T.f.small, row[2], x + 120, y + (i - 1) * st, TEXT_W - 120, T.c.dim)
        end
      else
        for i, l in ipairs(b.lines) do
          G.text(b.font, l, x, y + (i - 1) * b.lh, b.color)
        end
      end
    end
    y = y + b.h + b.gap
  end
  G.unclip()
  -- barra de rolagem
  if self.max_scroll > 0 then
    local track = VIEW_H - 12
    local hh = math.max(24, track * VIEW_H / self.content_h)
    local yy = VIEW_Y + 6 + (track - hh) * (self.scroll / self.max_scroll)
    G.rect(VIEW_X + VIEW_W - 8, yy, 3, hh, T.c.accent2, 1, 0.7)
  end

  -- Reserva o canto direito do rodape para a versao, sem sobrepor as dicas.
  G.hints({ { "a", L("Abrir canal") }, { "start", L("Apoiar") }, { "dpad", L("Rolar") }, { "b", L("Voltar") } }, nil, T.W - 142)
  local version_label = L("VERSÃO ") .. (C.VERSION_NUM or C.VERSION)
  local version_x = T.W - 16 - T.f.pix8:getWidth(version_label)
  G.text(T.f.pix8, version_label, version_x, T.H - 21, T.c.yellow)

  if self.show_qr then
    if self.qr_big and (self.qr or self.qr_image) then self:draw_qr_big(self.qr) else self:draw_qr() end
  end
  if self.show_pix then
    if self.pix_big and (self.pix_qr or self.pix_qr_image) then self:draw_pix_big()
    else self:draw_pix() end
  end
end

--- QR Code centralizado com zona de silencio (modulos inteiros)
local function draw_qr_matrix(qr, x, y, max)
  local n = #qr
  local m = math.max(1, math.floor(max / (n + 8)))
  local size = (n + 8) * m
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", x, y, size, size)
  lg.setColor(0, 0, 0, 1)
  for cx = 1, n do
    for cy = 1, n do
      if qr[cx][cy] > 0 then lg.rectangle("fill", x + (cx + 3) * m, y + (cy + 3) * m, m, m) end
    end
  end
  return size
end

-- Janela de apoio restaurada para o projeto James Park.
-- QR aponta para a pagina LivePix, nao representa uma cobranca Pix.
function S:draw_pix()
  G.rect(0, 0, T.W, T.H, T.c.black, 0, 0.75)
  local w, h = 600, 330
  local x, y = (T.W - w) / 2, (T.H - h) / 2 - 6
  G.panel(x, y, w, h, { bg = T.c.bg1, border = T.c.yellow, lw = 2, r = 10 })
  G.rect(x, y, w, 6, T.c.yellow, 3)
  G.text(T.f.pix16, L("APOIE O PROJETO"), x + 22, y + 22, T.c.yellow)
  local qx, qy, size = x + 22, y + 54, 226
  local has_qr = (self.pix_qr_image ~= nil or self.pix_qr ~= nil)
  if self.pix_qr_image then
    local iw, ih = self.pix_qr_image:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(self.pix_qr_image, qx, qy, 0, size / iw, size / ih)
  elseif self.pix_qr then
    size = draw_qr_matrix(self.pix_qr, qx, qy, size)
  else
    G.text(T.f.body, L("Nao foi possivel gerar o QR Code."), qx, qy + 60, T.c.red)
  end
  local tx = x + 22 + 226 + 20
  local tw = x + w - 22 - tx
  G.text(T.f.bodyb, "James Park", tx, y + 54, T.c.text)
  G.text_fit(T.f.small, SUPPORT_SHORT, tx, y + 76, tw, T.c.accent2)
  local ty = y + 106
  for _, line in ipairs(G.wrap(T.f.body, SUPPORT_TEXT, tw)) do
    G.text(T.f.body, line, tx, ty, T.c.text)
    ty = ty + 18
  end
  ty = ty + 8
  G.tag("LIVEPIX", tx, ty, T.c.accent2, T.c.bg0, T.f.pix8)
  ty = ty + 23
  for _, line in ipairs(G.wrap(T.f.small, SUPPORT_HOW, tw)) do
    G.text(T.f.small, line, tx, ty, T.c.dim)
    ty = ty + 15
  end
  G.text(T.f.bodyb, L("Obrigado pelo apoio!"), tx, y + h - 64, T.c.accent)
  if has_qr then
    G.button_icon("a", x + 22, y + h - 30)
    G.text(T.f.small, L("Ampliar QR Code"), x + 44, y + h - 29, T.c.dim)
  end
  G.button_icon("b", x + w - 110, y + h - 30)
  G.text(T.f.small, L("Fechar"), x + w - 88, y + h - 29, T.c.dim)
end

-- Modo ampliado usa exclusivamente o QR do LivePix, nunca o QR do Telegram.
function S:draw_pix_big()
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", 0, 0, T.W, T.H)
  local size = 394
  local qx, qy = math.floor((T.W - size) / 2), 6
  if self.pix_qr_image then
    local iw, ih = self.pix_qr_image:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(self.pix_qr_image, qx, qy, 0, size / iw, size / ih)
  elseif self.pix_qr then
    size = draw_qr_matrix(self.pix_qr, qx, qy, size)
  end
  G.text(T.f.bodyb, "James Park  •  " .. SUPPORT_SHORT,
    0, qy + size + 8, { 0.08, 0.15, 0.22, 1 }, "center", T.W)
  G.text(T.f.small, L("QR do site LivePix (não é código Pix bancário)") .. "  •  " .. L("A/B: voltar"),
    0, qy + size + 34, { 0.25, 0.25, 0.25, 1 }, "center", T.W)
end

-- START e exclusivo da tela Sobre: nao abre a Central de Downloads.
function S:on_start()
  if self.show_pix then
    self.pix_big = false
    self.show_pix = false
    return
  end
  self.show_qr = false
  self.qr_big = false
  if not self.pix_qr_image and not self.pix_qr then
    local ok, qrlib = pcall(require, "lib.qrencode")
    if ok then
      local okq, tab = pcall(qrlib.qrcode, SUPPORT_URL)
      if okq and type(tab) == "table" then self.pix_qr = tab end
    end
  end
  self.pix_big = false
  self.show_pix = true
end

--- QR grande em tela cheia, mantendo o branco de fundo para leitura pela camera.
function S:draw_qr_big(qr)
  lg.setColor(1, 1, 1, 1)
  lg.rectangle("fill", 0, 0, T.W, T.H)
  local size = 407
  local qx, qy = math.floor((T.W - size) / 2), 7
  if self.qr_image then
    local iw, ih = self.qr_image:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(self.qr_image, qx, qy, 0, size / iw, size / ih)
  elseif qr then
    size = draw_qr_matrix(qr, qx, qy, size)
  end
  G.text(T.f.bodyb, CHANNEL_NAME .. "  •  " .. CHANNEL_SHORT,
    0, qy + size + 9, { 0.08, 0.15, 0.22, 1 }, "center", T.W)
  G.text(T.f.small, L("Aponte a câmera do celular para o QR Code") .. "  •  " .. L("A/B: voltar"),
    0, qy + size + 35, { 0.25, 0.25, 0.25, 1 }, "center", T.W)
end

--- Janela com QR Code e endereco (console sem navegador)
function S:draw_qr()
  G.rect(0, 0, T.W, T.H, T.c.black, 0, 0.7)
  local w, h = 520, 330
  local x, y = (T.W - w) / 2, (T.H - h) / 2
  G.panel(x, y, w, h, { bg = T.c.bg1, border = T.c.accent, lw = 2, r = 10 })
  G.rect(x, y, w, 6, T.c.accent, 3)
  telegram_icon(x + 20, y + 17, 38, 34)
  G.text_fit(T.f.pix16, L("SIGA NOSSO CANAL NO TELEGRAM"), x + 66, y + 26, w - 94, T.c.text)
  -- QR Code: modulos inteiros, com margem branca (zona de silencio)
  local qr = self.qr
  local has_qr = (self.qr_image ~= nil) or (qr ~= nil)
  if has_qr then
    local qx, qy = x + 24, y + 66
    local size = 185
    if self.qr_image then
      local iw, ih = self.qr_image:getDimensions()
      lg.setColor(1, 1, 1, 1)
      lg.draw(self.qr_image, qx, qy, 0, size / iw, size / ih)
    else
      size = draw_qr_matrix(qr, qx, qy, size)
    end
    local tx = qx + size + 20
    local tw = x + w - 24 - tx
    G.text(T.f.bodyb, CHANNEL_NAME, tx, qy, T.c.text)
    G.text_fit(T.f.body, CHANNEL_SHORT, tx, qy + 24, tw, T.c.accent2)
    G.text(T.f.small, L("Escaneie para seguir nosso canal no Telegram."),
      tx, qy + 57, T.c.dim, "left", tw)
  else
    G.text(T.f.body, L("Acesse pelo celular ou computador:\n") .. CHANNEL_URL,
      x + 24, y + 80, T.c.text, "left", w - 48)
    G.text(T.f.small, L("Não foi possível gerar o QR Code."), x + 24, y + 146, T.c.dim)
  end
  if has_qr then
    G.button_icon("a", x + 24, y + h - 34)
    G.text(T.f.small, L("Ampliar QR Code"), x + 46, y + h - 33, T.c.dim)
  end
  G.button_icon("b", x + w - 120, y + h - 34)
  G.text(T.f.small, L("Fechar"), x + w - 98, y + h - 33, T.c.dim)
end

--- O botao A abre sempre a janela com QR Code. Nao tenta abrir navegador.
function S:open_channel()
  -- Imagem QR local verificada, com geracao dinamica como fallback.
  if not self.qr_image and not self.qr then
    local ok, qrlib = pcall(require, "lib.qrencode")
    if ok then
      local okq, tab = pcall(qrlib.qrcode, CHANNEL_URL)
      if okq and type(tab) == "table" then self.qr = tab end
    end
  end
  self.show_qr = true
  self.qr_big = false
end

function S:action(act)
  if self.show_pix then
    if act == "a" and (self.pix_qr_image or self.pix_qr) then
      self.pix_big = not self.pix_big
    elseif act == "b" then
      if self.pix_big then self.pix_big = false else self.show_pix = false end
    end
    return
  end
  if self.show_qr then
    if act == "a" and (self.qr or self.qr_image) then
      self.qr_big = not self.qr_big
    elseif act == "b" or act == "a" then
      if self.qr_big then self.qr_big = false else self.show_qr = false end
    end
    return
  end
  if act == "b" then App.pop()
  elseif act == "a" then self:open_channel()
  elseif act == "up" then self.scroll = math.max(0, self.scroll - 24)
  elseif act == "down" then self.scroll = math.min(self.max_scroll, self.scroll + 24)
  elseif act == "l1" or act == "left" then self.scroll = math.max(0, self.scroll - (VIEW_H - 40))
  elseif act == "r1" or act == "right" then self.scroll = math.min(self.max_scroll, self.scroll + (VIEW_H - 40))
  end
end

return S
