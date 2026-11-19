# R36S ROMS STORE

Repositório do projeto **R36S ROMS STORE**, hospedado com o nome **R36S-ROMS-HUB-STORE**.

**Status:** versão 0.6.6-beta

Aplicativo para consoles R36S/R36H, com interface Lua e LÖVE 11.5. Inclui catálogo de ROMs por sistema, gerenciamento de downloads, instalação em SD1/SD2, favoritos, BIOS, temas e gerenciamento seguro dos arquivos instalados.

**Esta revisão** usa a versão com **Configurações em lista**, com o `game.love` correspondente e as fontes Lua da mesma compilação.

## Instalação

Baixe o instalador ZIP em **[Releases](https://github.com/JammesPark/R36S-ROMS-HUB-STORE/releases)** e extraia seu conteúdo na pasta `/roms/ports/` do cartão do console e execute `R36S ROMS STORE.sh` no EmulationStation. É necessário ter o runtime LÖVE apropriado. Para uma atualização manual, faça cópia de segurança do `game.love` anterior.

## Código-fonte e compilação

- `game/`: fonte Lua usada para gerar o `game.love`.
- `r36sromsstore/`: arquivos de suporte e um `game.love` já empacotado, correspondente à fonte.
- `tools/build.sh`: gerador do instalador ZIP.
- `.github/workflows/build.yml`: valida a sintaxe LuaJIT e publica o ZIP da main como pré-release para download manual.

Executar manualmente no Linux: `sh tools/build.sh`.

**O GitHub Actions não instala nada no console e não publica atualizações OTA.** A execução é de build e validação, com ZIP para download na pré-release do commit.

## Autoria, licenças e conteúdo

Aplicativo derivado do **R36S PORT HUB**, por **Lag do Lira**, com modificações para a R36S ROMS STORE. Ver `LICENSE`, `NOTICE.md` e os avisos de terceiros. Código distribuído sob GPL-3.0, com as condições e os avisos de licença aplicáveis. As ROMs, artes e marcas de terceiros são responsabilidade de seus respectivos titulares; o aplicativo não concede licenças sobre elas.
