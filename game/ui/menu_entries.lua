-- Menu principal: as sete opcoes antes reunidas em Central de Conteudo
-- agora sao acessos diretos. Apenas dados; a navegacao continua em menu.lua.
local L = require("lib.i18n").L
local C = require("config")
local M = {}
function M.items()
  return {
    { id="roms", label=L("ROMs"), sub=L("Jogos organizados por sistema"), icon="set_store", classic_icon="store" },
    { id="bios", label=L("BIOS do Sistema"), sub=L("Verificar, baixar e instalar BIOS"), icon="roms_bios_chip", classic_icon="bios" },
    { id="library", label=L("Biblioteca de jogos"), sub=L("Jogos dos emuladores do console"), icon="games", classic_icon="library" },
    { id="installed", label=L("Instalados"), sub=L("ROMs instaladas pela loja"), icon="set_grid", classic_icon="mine" },
    { id="downloads", label=L("Downloads"), sub=L("Progresso e histórico (START)"), icon="download", classic_icon="download" },
    { id="favorites", label=L("Favoritos"), sub=L("Itens marcados como favoritos"), icon="set_favorites", classic_icon="library" },
    { id="esthemes", label=L("Temas do EmulationStation"), sub=L("Temas da interface do console"), icon="roms_es_monitor", classic_icon="es_themes" },
    { id="tools", label=L("Utilidades e Ferramentas"), sub=L("Ferramentas do sistema"), icon="roms_tools_kit", classic_icon="tools" },
    { id="settings", label=L("Configurações"), sub=L("Música, catálogo e sistema"), icon="settings", classic_icon="settings" },
    { id="about", label=L("Sobre o Projeto"), sub=L("Informações e créditos"), icon="set_about", classic_icon="about" },
    { id="exit", label=C.OS_MODE and L("Energia") or L("Sair"), sub=C.OS_MODE and L("Desligar ou reiniciar") or L("Fechar o R36S ROMS STORE"), icon="set_exit", classic_icon="exit" },
  }
end
return M
