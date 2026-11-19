-- R36S ROMS STORE: lista de licencas somente leitura (sem gerenciador de arquivos).
-- B: retorna exatamente a tela anterior. Preserva LICENSE, NOTICE e creditos.
local L = require("lib.i18n").L
local Base = require("ui.screens.infolist")

local S = { draw = Base.draw, action = Base.action, visible = Base.visible, resume = Base.resume }

function S:enter()
  Base.enter(self, {
    title = L("Licenças"),
    sub = L("Licenças e avisos preservados"),
    items = {
      { tag = "GPL", text = "GNU GPL-3.0", sub = L("Licença do código derivado") },
      { tag = "7-Zip", text = "7-Zip", sub = L("GNU LGPL e restrições unRAR aplicáveis") },
      { tag = "LÖVE", text = "LÖVE 2D", sub = L("Licenças dos componentes do motor") },
      { tag = "Lua", text = "LuaQRCode", sub = L("Licença do componente QR Code") },
      { tag = "FONT", text = "Inter", sub = L("Licenças da fonte Inter") },
      { tag = "FONT", text = "Chakra Petch", sub = "SIL Open Font License" },
      { tag = "FONT", text = "Press Start 2P", sub = "SIL Open Font License" },
      { tag = "INFO", text = L("Avisos de autoria"), sub = "NOTICE.md — Lag do Lira e componentes de terceiros" },
    },
  })
end

return S
