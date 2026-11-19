# Auditoria de preservação — 2026-11-16

**Origem histórica da auditoria:** `JammesPark/R36SPORTSBR-STORE-HUB` (branch `main` antes da recuperação).
**Origem:** `liralflsti-wq/r36s-port-hub`.

> Inventário gerado antes de modificar arquivos do aplicativo. Comparação por SHA-1 Git de blobs, com mapeamento dos caminhos `src/` → `game/` e `port/r36sporthub/` → `r36sromsstore/`. Divergência de SHA significa conteúdo diferente, não comprova remoção de funcionalidade.

- Arquivos da STORE no início: **516**; arquivos na origem: **526**.
- Arquivos originais preservados/alterados no início: **496**, sendo **358** idênticos e **138** modificados.
- Arquivos ausentes detectados: **30**.
- Arquivos novos próprios da STORE: **20**.

## Alterações próprias que não devem ser apagadas

### Núcleo (core) (44)

- `src/core/battery.lua` → `game/core/battery.lua`
- `src/core/bios.lua` → `game/core/bios.lua`
- `src/core/bios_ref.lua` → `game/core/bios_ref.lua`
- `src/core/brightness.lua` → `game/core/brightness.lua`
- `src/core/catalog.lua` → `game/core/catalog.lua`
- `src/core/clock.lua` → `game/core/clock.lua`
- `src/core/compat.lua` → `game/core/compat.lua`
- `src/core/consoleid.lua` → `game/core/consoleid.lua`
- `src/core/datetime.lua` → `game/core/datetime.lua`
- `src/core/diag.lua` → `game/core/diag.lua`
- `src/core/downloads.lua` → `game/core/downloads.lua`
- `src/core/errlog.lua` → `game/core/errlog.lua`
- `src/core/esgallery.lua` → `game/core/esgallery.lua`
- `src/core/esgamelist.lua` → `game/core/esgamelist.lua`
- `src/core/esthemes.lua` → `game/core/esthemes.lua`
- `src/core/esthemes_scan.lua` → `game/core/esthemes_scan.lua`
- `src/core/input.lua` → `game/core/input.lua`
- `src/core/installer.lua` → `game/core/installer.lua`
- `src/core/library.lua` → `game/core/library.lua`
- `src/core/manifest.lua` → `game/core/manifest.lua`
- `src/core/music.lua` → `game/core/music.lua`
- `src/core/net.lua` → `game/core/net.lua`
- `src/core/osdetect.lua` → `game/core/osdetect.lua`
- `src/core/pmcore.lua` → `game/core/pmcore.lua`
- `src/core/pmmanager.lua` → `game/core/pmmanager.lua`
- `src/core/r36ctl.lua` → `game/core/r36ctl.lua`
- `src/core/recorder.lua` → `game/core/recorder.lua`
- `src/core/recordings.lua` → `game/core/recordings.lua`
- `src/core/runtimes.lua` → `game/core/runtimes.lua`
- `src/core/savebackup.lua` → `game/core/savebackup.lua`
- `src/core/scan.lua` → `game/core/scan.lua`
- `src/core/screencap.lua` → `game/core/screencap.lua`
- `src/core/sdcard.lua` → `game/core/sdcard.lua`
- `src/core/sdmaint.lua` → `game/core/sdmaint.lua`
- `src/core/stream.lua` → `game/core/stream.lua`
- `src/core/sysinfo.lua` → `game/core/sysinfo.lua`
- `src/core/uninstall.lua` → `game/core/uninstall.lua`
- `src/core/update.lua` → `game/core/update.lua`
- `src/core/updater/backup.lua` → `game/core/updater/backup.lua`
- `src/core/updater/folder.lua` → `game/core/updater/folder.lua`
- `src/core/updater/formats.lua` → `game/core/updater/formats.lua`
- `src/core/updater/manager.lua` → `game/core/updater/manager.lua`
- `src/core/updater/rules.lua` → `game/core/updater/rules.lua`
- `src/core/updnotice.lua` → `game/core/updnotice.lua`

### Interface (UI) (30)

- `src/ui/gfx.lua` → `game/ui/gfx.lua`
- `src/ui/overlay.lua` → `game/ui/overlay.lua`
- `src/ui/portrow.lua` → `game/ui/portrow.lua`
- `src/ui/screens/about.lua` → `game/ui/screens/about.lua`
- `src/ui/screens/bios.lua` → `game/ui/screens/bios.lua`
- `src/ui/screens/datetime.lua` → `game/ui/screens/datetime.lua`
- `src/ui/screens/details.lua` → `game/ui/screens/details.lua`
- `src/ui/screens/disclaimer.lua` → `game/ui/screens/disclaimer.lua`
- `src/ui/screens/esthemes.lua` → `game/ui/screens/esthemes.lua`
- `src/ui/screens/files.lua` → `game/ui/screens/files.lua`
- `src/ui/screens/integrity.lua` → `game/ui/screens/integrity.lua`
- `src/ui/screens/language.lua` → `game/ui/screens/language.lua`
- `src/ui/screens/menu.lua` → `game/ui/screens/menu.lua`
- `src/ui/screens/recordings.lua` → `game/ui/screens/recordings.lua`
- `src/ui/screens/sdanalyzer.lua` → `game/ui/screens/sdanalyzer.lua`
- `src/ui/screens/sdmaint.lua` → `game/ui/screens/sdmaint.lua`
- `src/ui/screens/sdmaint_run.lua` → `game/ui/screens/sdmaint_run.lua`
- `src/ui/screens/splash.lua` → `game/ui/screens/splash.lua`
- `src/ui/screens/store.lua` → `game/ui/screens/store.lua`
- `src/ui/screens/streamrec.lua` → `game/ui/screens/streamrec.lua`
- `src/ui/screens/tester.lua` → `game/ui/screens/tester.lua`
- `src/ui/screens/themes.lua` → `game/ui/screens/themes.lua`
- `src/ui/screens/upd_backups.lua` → `game/ui/screens/upd_backups.lua`
- `src/ui/screens/upd_local.lua` → `game/ui/screens/upd_local.lua`
- `src/ui/screens/update.lua` → `game/ui/screens/update.lua`
- `src/ui/screens/updmgr.lua` → `game/ui/screens/updmgr.lua`
- `src/ui/screens/wifi.lua` → `game/ui/screens/wifi.lua`
- `src/ui/settings_defs.lua` → `game/ui/settings_defs.lua`
- `src/ui/settings_extra.lua` → `game/ui/settings_extra.lua`
- `src/ui/theme.lua` → `game/ui/theme.lua`

### Temas (20)

- `src/themes/default/preview.png` → `game/themes/default/preview.png`
- `src/themes/default/theme.json` → `game/themes/default/theme.json`
- `src/themes/neongrid/logo_about.png` → `game/themes/neongrid/logo_about.png`
- `src/themes/neongrid/logo_header.png` → `game/themes/neongrid/logo_header.png`
- `src/themes/neongrid/logo_menu.png` → `game/themes/neongrid/logo_menu.png`
- `src/themes/neongrid/logo_splash.png` → `game/themes/neongrid/logo_splash.png`
- `src/themes/neongrid/preview.png` → `game/themes/neongrid/preview.png`
- `src/themes/neongrid/theme.json` → `game/themes/neongrid/theme.json`
- `src/themes/pastel/logo_about.png` → `game/themes/pastel/logo_about.png`
- `src/themes/pastel/logo_header.png` → `game/themes/pastel/logo_header.png`
- `src/themes/pastel/logo_menu.png` → `game/themes/pastel/logo_menu.png`
- `src/themes/pastel/logo_splash.png` → `game/themes/pastel/logo_splash.png`
- `src/themes/pastel/preview.png` → `game/themes/pastel/preview.png`
- `src/themes/pastel/theme.json` → `game/themes/pastel/theme.json`
- `src/themes/wiiblue/logo_about.png` → `game/themes/wiiblue/logo_about.png`
- `src/themes/wiiblue/logo_header.png` → `game/themes/wiiblue/logo_header.png`
- `src/themes/wiiblue/logo_menu.png` → `game/themes/wiiblue/logo_menu.png`
- `src/themes/wiiblue/logo_splash.png` → `game/themes/wiiblue/logo_splash.png`
- `src/themes/wiiblue/preview.png` → `game/themes/wiiblue/preview.png`
- `src/themes/wiiblue/theme.json` → `game/themes/wiiblue/theme.json`

### Threads (16)

- `src/threads/bios_thread.lua` → `game/threads/bios_thread.lua`
- `src/threads/consoleid_thread.lua` → `game/threads/consoleid_thread.lua`
- `src/threads/delete_thread.lua` → `game/threads/delete_thread.lua`
- `src/threads/estheme_thread.lua` → `game/threads/estheme_thread.lua`
- `src/threads/fetch_thread.lua` → `game/threads/fetch_thread.lua`
- `src/threads/ftp_thread.lua` → `game/threads/ftp_thread.lua`
- `src/threads/install_thread.lua` → `game/threads/install_thread.lua`
- `src/threads/integrity_thread.lua` → `game/threads/integrity_thread.lua`
- `src/threads/pm_thread.lua` → `game/threads/pm_thread.lua`
- `src/threads/rec_thread.lua` → `game/threads/rec_thread.lua`
- `src/threads/runtimes_thread.lua` → `game/threads/runtimes_thread.lua`
- `src/threads/sdspeed_thread.lua` → `game/threads/sdspeed_thread.lua`
- `src/threads/shjob_thread.lua` → `game/threads/shjob_thread.lua`
- `src/threads/speedtest_thread.lua` → `game/threads/speedtest_thread.lua`
- `src/threads/stream_thread.lua` → `game/threads/stream_thread.lua`
- `src/threads/updater_thread.lua` → `game/threads/updater_thread.lua`

### Configuração, launcher e outros (13)

- `.gitignore` → `.gitignore`
- `LICENSE` → `LICENSE`
- `README.md` → `README.md`
- `port/R36S PORT HUB.sh` → `R36S ROMS STORE.sh`
- `port/r36sporthub/bin/es_theme_apply.sh` → `r36sromsstore/bin/es_theme_apply.sh`
- `port/r36sporthub/bin/fetch.sh` → `r36sromsstore/bin/fetch.sh`
- `port/r36sporthub/tools/converter_gravacao.html` → `r36sromsstore/tools/converter_gravacao.html`
- `src/catalog/catalog.json` → `game/catalog/catalog.json`
- `src/catalog/es_themes.json` → `game/catalog/es_themes.json`
- `src/conf.lua` → `game/conf.lua`
- `src/config.lua` → `game/config.lua`
- `src/lib/util.lua` → `game/lib/util.lua`
- `src/main.lua` → `game/main.lua`

### Imagens e arte (9)

- `port/r36sporthub/cover.png` → `r36sromsstore/cover.png`
- `port/r36sporthub/fanart.png` → `r36sromsstore/fanart.png`
- `port/r36sporthub/gameinfo.xml` → `r36sromsstore/gameinfo.xml`
- `port/r36sporthub/logo.png` → `r36sromsstore/logo.png`
- `src/assets/logo/dev_logo.png` → `game/assets/logo/dev_logo.png`
- `src/assets/logo/logo_about.png` → `game/assets/logo/logo_about.png`
- `src/assets/logo/logo_header.png` → `game/assets/logo/logo_header.png`
- `src/assets/logo/logo_menu.png` → `game/assets/logo/logo_menu.png`
- `src/assets/logo/logo_splash.png` → `game/assets/logo/logo_splash.png`

### Ferramentas (4)

- `tools/build.sh` → `tools/build.sh`
- `tools/make_icons.py` → `tools/make_icons.py`
- `tools/make_system_icons.py` → `tools/make_system_icons.py`
- `tools/make_update.py` → `tools/make_update.py`

### Idiomas (2)

- `src/i18n/en.lua` → `game/i18n/en.lua`
- `src/i18n/ru.lua` → `game/i18n/ru.lua`

## Arquivos novos da STORE (preservar)

- `.github/workflows/build.yml`
- `.github/workflows/import-source.yml`
- `.github/workflows/verify-tools.yml`
- `CHANGELOG.md`
- `NOTICE.md`
- `game/assets/icons/telegram_official.png`
- `game/assets/logo/logo_dev.png`
- `game/assets/qr/livepix_jammespark.png`
- `game/assets/qr/telegram_r36sportsbr.png`
- `game/catalog/lira_catalog.json`
- `game/core/portstorage.lua`
- `game/themes/default/logo_about.png`
- `game/themes/default/logo_header.png`
- `game/themes/default/logo_menu.png`
- `game/themes/default/logo_splash.png`
- `r36sromsstore/README.md`
- `r36sromsstore/licenses/GPL-3.0.txt`
- `r36sromsstore/licenses/NOTICE.md`
- `tools/README.md`
- `tools/version.py`

## Arquivos originais que estavam faltando

- `GUIA_GITHUB_CATALOGOS.txt` → recuperação em `GUIA_GITHUB_CATALOGOS.txt`
- `docs/AJUSTES.md` → recuperação em `docs/AJUSTES.md`
- `docs/ANALISE_KMP.md` → recuperação em `docs/ANALISE_KMP.md`
- `docs/CATALOGO.md` → recuperação em `docs/CATALOGO.md`
- `docs/ENTREGAS.md` → recuperação em `docs/ENTREGAS.md`
- `docs/IDIOMAS.md` → recuperação em `docs/IDIOMAS.md`
- `docs/LOJA_TEMAS.md` → recuperação em `docs/LOJA_TEMAS.md`
- `docs/MANUAL.md` → recuperação em `docs/MANUAL.md`
- `docs/TEMAS.md` → recuperação em `docs/TEMAS.md`
- `docs/catalog.example.json` → recuperação em `docs/catalog.example.json`
- `docs/images/capa.png` → recuperação em `docs/images/capa.png`
- `docs/images/configuracoes.png` → recuperação em `docs/images/configuracoes.png`
- `docs/images/loja.png` → recuperação em `docs/images/loja.png`
- `docs/images/loja_temas.png` → recuperação em `docs/images/loja_temas.png`
- `docs/images/menu.png` → recuperação em `docs/images/menu.png`
- `docs/images/portmaster.png` → recuperação em `docs/images/portmaster.png`
- `ports.json` → recuperação em `ports.json`
- `publicar.sh` → recuperação em `publicar.sh` (invólucro desativado; cópia integral em `docs/preservacao/original/publicar.sh`)
- `src/dev/autotest.lua` → recuperação em `game/dev/autotest.lua`
- `src/dev/installtest.lua` → recuperação em `game/dev/installtest.lua`
- `src/dev/scan.lua` → recuperação em `game/dev/scan.lua`
- `temas.json` → recuperação em `temas.json`
- `tools/fdt2.py` → recuperação em `tools/fdt2.py`
- `tools/fdt3.py` → recuperação em `tools/fdt3.py`
- `tools/fdtparse.py` → recuperação em `tools/fdtparse.py`
- `tools/mkart.py` → recuperação em `tools/mkart.py`
- `tools/mkbiosdb.py` → recuperação em `tools/mkbiosdb.py`
- `tools/mkconsoledb.py` → recuperação em `tools/mkconsoledb.py`
- `tools/ref/System.dat` → recuperação em `tools/ref/System.dat`
- `update.json` → recuperação em `update.json`

## Medidas da recuperação

- Criados todos os caminhos ausentes, sem eliminar ou substituir os 516 caminhos existentes da STORE.
- Restaurado o catálogo original de 34 ports como `ports.json` e cópia intacta em `game/catalog/lira_catalog_original.json`; a STORE mantém seus próprios arquivos e seleção de fonte.
- Adicionado fallback offline do catálogo original apenas quando a fonte Lira está selecionada, respeitando dados locais e cache.
- Preservado o workflow de importação anterior em `docs/preservacao/original/import-source.yml`; o workflow executável foi desativado (`if: false`) e passou a ter permissões somente de leitura.
- Mantido o publicador original intacto em `docs/preservacao/original/publicar.sh`, com invólucro inofensivo em `publicar.sh`, para não publicar acidentalmente usando links da origem.
- Ferramentas de desenvolvimento legadas restauradas como referência. `fdt3.py` e `mkconsoledb.py` ainda contêm caminhos antigos; não estão habilitados como etapas automáticas.
- Catálogos próprios, marcas, SD1/SD2, arquivos de temas e código de atualização existentes não foram revertidos.

## Limites da auditoria

- A igualdade de caminhos e SHA é uma verificação de preservação de arquivos. **Não substitui teste funcional no console**.
- Alterações antigas nos 138 arquivos modificados ainda devem ser revisadas por comportamento em testes específicos; esta operação não tenta desfazê-las.
- Novos ajustes de fluxo seguro podem alterar de modo aditivo `game/core/catalog.lua` e `.github/workflows/import-source.yml`; o resto dos caminhos originais da STORE deve permanecer byte a byte igual ao início da recuperação.


## Adaptação posterior — 0.0.7-beta

Os seis scripts de desenvolvimento que estavam recuperados em sua forma original receberam interfaces de execução atualizadas. Antes de alterá-los, suas versões completas foram arquivadas em `docs/preservacao/original/tools/`. Os geradores atualizados salvam resultados somente em pastas de desenvolvimento por padrão, sem modificar `game/` ou `r36sromsstore/`.

São eles: `fdtparse.py`, `fdt2.py`, `fdt3.py`, `mkconsoledb.py`, `mkbiosdb.py` e `mkart.py`. As bases ativas, logos, capas, cores de tema e regras de SD1/SD2 não foram alteradas. Testes de geração são executados pelo GitHub Actions.
