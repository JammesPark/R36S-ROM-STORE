-- R36S ROMS STORE: versao modificada em 2026-11-15. GPL-3.0.
-- Base: R36S PORT HUB, por Lag do Lira (creditos em NOTICE.md).
-- =============================================================================
--  R36S ROMS STORE - configuracao
--  Para trocar o catalogo NAO e preciso mexer no codigo do app: basta publicar
--  um catalog.json em qualquer endereco (ex.: um arquivo "raw" do GitHub).
--  Veja docs/CATALOGO.md.
-- =============================================================================
local L = require("lib.i18n").L
local C = {}

C.APP_NAME = "R36S ROMS STORE — Experimental"
C.EDITION = "Experimental"  -- identificacao visual; numero de versao inalterado
C.VERSION = L("0.6.7-beta")       -- texto exibido
C.VERSION_NUM = "0.6.7-beta"        -- numero usado para comparar com a atualizacao
-- R36 Hub OS: o hub e a interface principal do sistema (supervisor exporta R36HUBOS=1)
C.OS_MODE = os.getenv("R36HUBOS") == "1"
C.OS_NAME = "R36 Hub OS"
C.OS_VERSION = os.getenv("R36HUBOS_VERSION") or ""

-- Atualizacao do sistema (Configuracoes > Atualizacao do sistema).
-- Link direto do pacote .zip (o hub le o update_manifest.json de dentro dele:
-- versao, mudancas e correcoes), link do repositorio no GitHub (ex.:
-- https://github.com/USUARIO/REPO, usa a ultima Release) ou de um JSON
-- { "version", "url", "sha256", "notes" }.
-- Tambem pode ser definido em <pasta do app>/update_url.txt (sobrescreve este).
C.UPDATE_URL = "https://raw.githubusercontent.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/main/ota/update.json"

-- Catalogo de temas (Configuracoes > Temas > Baixar novos temas). Vazio ate o
-- repositorio de temas ser publicado. Tambem pode ser definido em
-- <pasta do app>/themes_url.txt. Formato esperado: veja docs/TEMAS.md.
C.THEMES_CATALOG_URL = "https://raw.githubusercontent.com/JammesPark/R36SPORTSBR-STORE-UPDATES/main/themes/themes.json"

-- Loja de Temas do EmulationStation (Utilitarios & Ferramentas > Ferramentas de
-- sistema). Link "raw" do temas.json no GitHub. Vazio = usa a copia que vem no
-- app (catalog/es_themes.json). Tambem pode ir em <pasta do app>/es_themes_url.txt
C.ES_THEMES_URL = ""
C.TAGLINE = L("Ports de jogos e utilitários para o console R36S, criados por fãs e para fãs.")

-- Jogos: somente API de ROMs em core/rom_source.lua e cache local.
-- URLs legadas de catalogos do Lira/PORTS STORE nao sao utilizadas.

-- Central de Conteudo > BIOS do Sistema: pacote de BIOS (link direto do arquivo).
-- Link oficial do projeto. Pode ser trocado em <pasta do app>/bios_url.txt
-- (uma linha; sobrescreve este). Vazio = a tela avisa que a fonte nao foi configurada.
C.BIOS_URL = "https://archive.org/download/bios-r-36s/Bios%20r36s.rar"

-- Fonte unica: ROMs da API GameStoreBR (core/rom_source.lua).
-- Ao ficar offline: catalog.json local valido, cache proprio de ROMs
-- ou catalogo embutido. As fontes legadas de ports nao sao usadas.

-- Pastas (definidas pelo launcher .sh; os valores padrao servem para o R36S)
C.PORTS_DIR = os.getenv("R36SBR_PORTS_DIR") or "/roms/ports"
C.APP_DIR = os.getenv("R36SBR_DIR") or (C.PORTS_DIR .. "/r36sromsstore")
C.TMP_DIR = C.APP_DIR .. "/tmp"          -- mesma particao de /roms/ports (mover = instantaneo)
C.FETCH_SH = C.APP_DIR .. "/bin/fetch.sh"

-- Margem de seguranca de espaco livre (bytes) exigida alem do necessario
C.SPACE_MARGIN = 32 * 1024 * 1024

-- Itens da pasta de ports que pertencem ao sistema/outras ferramentas.
-- Se um pacote trouxer algo com esses nomes na raiz, o item e IGNORADO
-- (nunca substitui o original). Comparacao sem diferenciar maiusculas.
C.PROTECTED_NAMES = {
  ["portmaster"] = true, ["portmaster.sh"] = true, ["gamelist.xml"] = true,
  ["r36sromsstore"] = true, ["r36s port hub.sh"] = true, ["r36sportsbr store.sh"] = true,
}

-- =============================================================================
--  Runtimes do PortMaster (Configuracoes > Atualizar runtimes)
-- =============================================================================
-- Pacote com todos os runtimes aarch64 (versao especifica, definida pelo projeto)
C.RUNTIMES_RELEASE = "2026-10-22_1343"
C.RUNTIMES_ZIP_URL = "https://github.com/PortsMaster/PortMaster-New/releases/download/"
  .. C.RUNTIMES_RELEASE .. "/runtimes.all.aarch64.zip"
-- Indice da MESMA release: traz md5 e tamanho de cada runtime (verificacao)
C.RUNTIMES_INDEX_URL = "https://github.com/PortsMaster/PortMaster-New/releases/download/"
  .. C.RUNTIMES_RELEASE .. "/ports.json"
C.RUNTIMES_ZIP_NAME = "runtimes.all.aarch64.zip"
C.RUNTIMES_ARCH = "aarch64"

-- Futuro: URL dinamica. Com true, o app consulta a API do GitHub e usa a release
-- mais recente que contenha C.RUNTIMES_ZIP_NAME (se falhar, usa a URL fixa acima).
-- Tambem e possivel sobrescrever a URL sem recompilar, criando
-- <pasta do app>/runtimes_url.txt (linha 1: URL do zip; linha 2: URL do ports.json).
C.RUNTIMES_AUTO_LATEST = false
C.RUNTIMES_API_URL = "https://api.github.com/repos/PortsMaster/PortMaster-New/releases?per_page=15"

-- Onde procurar o PortMaster (o launcher tambem informa a pasta encontrada)
C.PORTMASTER_DIRS = {}
for _, d in ipairs({
  os.getenv("R36SBR_PM_DIR") or "",
  C.PORTS_DIR .. "/PortMaster",
  "/roms/ports/PortMaster",
  "/roms2/ports/PortMaster",
  "/opt/system/Tools/PortMaster",
  "/opt/tools/PortMaster",
  os.getenv("R36SBR_XDG_ORIG") and (os.getenv("R36SBR_XDG_ORIG") .. "/PortMaster") or "",
}) do
  if d ~= "" then C.PORTMASTER_DIRS[#C.PORTMASTER_DIRS + 1] = d end
end

-- Capas: quantas ficam carregadas na memoria ao mesmo tempo
C.COVER_CACHE_MAX = 14

-- Quadros por segundo maximos (baixo consumo de CPU/bateria)
C.MAX_FPS = 30
C.ECO_FPS = 20   -- modo economico

return C
