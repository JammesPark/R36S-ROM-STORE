<p align="center"><img src="../port/r36sromstore/logo_hd.png" alt="R36S ROM STORE" width="340"></p>

# R36S ROM STORE

<p align="center">
  <img alt="R36S e R36H" src="https://img.shields.io/badge/Console-R36S%20%7C%20R36H-0891b2?style=for-the-badge">
  <img alt="Sistemas: dArkOSRE, dArkOS, dArkOSen, ArkOS, ArchR" src="https://img.shields.io/badge/Sistema-dArkOSRE%20%7C%20dArkOS%20%7C%20dArkOSen%20%7C%20ArkOS%20%7C%20ArchR-ffdc49?style=for-the-badge">
</p>

[🇧🇷 Português](../README.md) · [🇺🇸 English](README.en.md) · [🇪🇸 Español](README.es.md) · [🇷🇺 Русский](README.ru.md)

**Status:** 0.7.2-beta — official beta.

## About

An independent retro gaming manager for R36S, written in Lua and LÖVE 11.5. It manages ROMs, BIOS, EmulationStation themes and tools using the handheld controls, SD1/SD2 and a logical 640×480 layout. R36S and R36H have both been physically tested by the maintainer. Based on R36S PORT HUB by Lag do Lira; not an official product of the original project or console manufacturer.

## Important notice

⚠️ **BETA version.** The main features have been tested in a simulated environment on a computer and on R36S and R36H handhelds. Some functions and operating-system combinations still need additional validation. Community bug reports, suggestions and contributions are welcome.

Beta software: back up your cards. Download and use only content you are authorized to access and distribute. The GPL-3.0 software license does not grant rights to third-party games, BIOS, artwork or themes. Compatibility varies.

## Downloads

| | Download |
|---|---|
| Automatic installer (.sh) — active official release with OTA | [SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) |
| Full installation with OTA | [ZIP](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.2-beta/R36S_ROM_STORE_0.7.2-beta.zip) |
| Manual update | [UPDATE.zip](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.2-beta/R36S_ROM_STORE_0.7.2-beta_UPDATE.zip) |
| Previous releases | [Releases](https://github.com/JammesPark/R36S-ROM-STORE/releases) |

For migration from 0.7.0-beta or older, use the SH or full ZIP. The manual update requires the new r36sromstore/ layout. Back up first. The legacy OTA remains at 0.7.0-beta. The new-channel SH passed automated tests; separate physical validation has not been confirmed.

## Interface

| Matrix Edition | Pulse Edition |
|:---:|:---:|
| <img src="images/atual/matrix-menu.png" width="320" alt="Matrix"> | <img src="images/atual/pulse-menu.png" width="320" alt="Pulse"> |


Matrix is the default on fresh installs; Pulse is optional. Independent colors; List, Grid and Showcase views. Actual application captures rendered at 640×480 in an isolated environment, not physical hardware readings.

## Features

- ROM catalog with over 15,000 validated collection entries, search, covers, region badges, favorites and system categories; totals change with catalog updates.
- Local game library, SD1/SD2 selection and store-installed ROM management.
- Themes Store: 100 themes in the tested catalog, previews, installation in background, activation, updates and removal of installed themes including external ones; warnings for unverified themes and protection for active/system themes.
- Shared ROM/theme download queue, speed, progress, ETA, cancellation during transfer, history and direct details.
- BIOS detection and management; SD tools, controls/analog tester, network diagnostics, Wi-Fi, FTP, file manager, PortMaster/runtimes, device information, backup/restore and logs (availability depends on firmware).
- Appearance, colors, text size and four languages; last valid catalog and cached artwork available offline.

## Install and migrate

Back up first. Extract the full ZIP into the card's `ports/` directory. In the new layout, the launcher is `R36S ROM STORE.sh` beside `r36sromstore/` containing `game.love`. Open it from Ports in EmulationStation, with LÖVE 11.5 available; connect to the internet for initial synchronization.

First migrate with the full installer. Keep the old folder, launcher and backups until you have checked your data on the card. The new layout uses its own OTA feed. The legacy feed stays at 0.7.0-beta.

## Controls

| Button | Action |
|---|---|
| D-pad / left stick | Navigate |
| A / B | Details/confirm / back/cancel |
| X | ROM search; theme install; clear download history |
| Y | Context action; remove theme; download info/actions |
| L1/R1 | Categories/filters |
| L2/R2 | ROM views; theme previews |
| SELECT | ROM favorite; theme system/display selector |
| START | Downloads; theme options; About support action |
| FN | Screenshot when supported |

## Compatibility and support

Both R36S and R36H have been physically tested by the maintainer. dArkOSen was tested with earlier controller-mapping differences. Installation on ArchR was tested. dArkOSRE, dArkOS and ArkOS are reference systems; full validation of individual firmware/model combinations remains pending. AmberELEC, ROCKNIX, JELOS, KNULLI and Batocera have theme compatibility/detection information, not certification of the whole app. Automatic theme-update popup and specifically manual theme removal were not physically exercised. ThemeMaster and outside-catalog removal passed. Migration and the physical checklist were approved by the maintainer; live new-channel OTA and SH are not separately confirmed on hardware.

Internet is required for first sync and new downloads. An active theme must be replaced before removal. If an error occurs, report firmware, version and steps, without passwords or personal information.

[Telegram](https://t.me/r36sportsromstorebr) · [Issues](https://github.com/JammesPark/R36S-ROM-STORE/issues) · [Support guide (PT-BR)](SUPORTE.md)

## Development and credits

Source: `src/`; build: `sh tools/build.sh`; [changelog](../CHANGELOG.md), [post-launch roadmap](ROADMAP.md), [release process](HISTORICO_RELEASES.md). Rankings and other roadmap items are future proposals, not current features.

[JammesPark](https://github.com/JammesPark) · [Lag do Lira](https://github.com/liralflsti-wq/r36s-port-hub) · [ChatGPT (OpenAI)](https://chatgpt.com/) · [NOTICE](../NOTICE.md) · [Contributors](../CONTRIBUTORS.md) · [GPL-3.0](../LICENSE)

Lag do Lira authored the base project, original Matrix/Pulse themes and inherited tools. JammesPark maintains the derivative; ChatGPT assists development. ThemeGallery previews: Dave, MIT. Third-party credits and licensing apply separately.
