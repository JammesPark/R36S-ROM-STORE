<p align="center"><img src="images/atual/logo_hd.png" alt="R36S ROM STORE" width="340"></p>

# R36S ROM STORE

<p align="center">
  <img alt="R36S e R36H" src="https://img.shields.io/badge/Console-R36S%20%7C%20R36H-0891b2?style=for-the-badge">
  <img alt="Sistemas: dArkOSRE, dArkOS, dArkOSen, ArkOS, ArchR" src="https://img.shields.io/badge/Sistema-dArkOSRE%20%7C%20dArkOS%20%7C%20dArkOSen%20%7C%20ArkOS%20%7C%20ArchR-ffdc49?style=for-the-badge">
</p>

[🇧🇷 Português](../README.md) · [🇺🇸 English](README.en.md) · [🇪🇸 Español](README.es.md) · [🇷🇺 Русский](README.ru.md)

**Status:** 0.7.0-beta — official beta.

## About

Independent retro gaming manager for R36S and R36H, written in Lua and LÖVE 11.5. ROM catalog, search, covers, favorites, local library, SD1/SD2 installation, BIOS, EmulationStation themes, download queue, history and device tools. Two built-in themes, Matrix and Pulse; four languages.

## Important notice

⚠️ **BETA version.** The main features have been tested in a simulated environment on a computer and on R36S and R36H handhelds. Some functions and operating-system combinations still need additional validation. Community bug reports, suggestions and contributions are welcome.

Back up your cards and use only content you are authorized to access. The GPL-3.0 software license does not grant rights to third-party ROMs, BIOS, artwork or themes.

## Downloads

| Package | Download |
|---|---|
| Automatic installer (.sh), latest active official version with OTA | [Download SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) |
| Full 0.7.0-beta installation with OTA | [ZIP](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.0-beta/R36S_ROMS_STORE_0.7.0-beta.zip) |
| Manual 0.7.0-beta update | [UPDATE.zip](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.0-beta/R36S_ROMS_STORE_0.7.0-beta_UPDATE.zip) |
| Previous versions | [Official history](https://github.com/JammesPark/R36S-ROM-STORE/releases) |

Copy the SH to ports, connect to the internet and run it from EmulationStation. It downloads and verifies the active official full installer. Automated validation passed; physical validation of this script is pending. The manual update contains only the application folder, including game.love, not the launcher or user data. Use it only with an existing installation of the same layout; back up first. The full ZIP already includes OTA.

## Interface

Approved visual identity for the next edition; actual LÖVE screenshots at 640×480 from an isolated environment. The currently available release is 0.7.0-beta.

| Matrix Edition | Pulse Edition |
|:---:|:---:|
| <img src="images/atual/matrix-menu.png" width="320" alt="Matrix"> | <img src="images/atual/pulse-menu.png" width="320" alt="Pulse"> |

## Installation

Extract the complete 0.7.0-beta ZIP into `ports/` on the card. Open `R36S ROMS STORE.sh` beside `r36sromsstore/` in EmulationStation with LÖVE 11.5 available. Connect to the internet for initial synchronization.

## Compatibility and tests

R36S and R36H have both been physically tested by the maintainer. dArkOSen was tested with controller-mapping differences. Installation on ArchR was tested. dArkOSRE, dArkOS and ArkOS are reference systems; full validation of every combination remains pending.

## Updates

Use the in-app online updater for official releases. Back up before updating.

## Development and credits

Lua/LuaJIT/LÖVE, Python, Shell Script, HTML, JSON/YAML/XML, Markdown, GitHub Actions and Cloudflare R2. Based on R36S PORT HUB by Lag do Lira; JammesPark maintains the derivative, with assistance from ChatGPT (OpenAI). Original theme/tool authorship and third-party licenses are preserved.

[Telegram](https://t.me/R36SPORTSBR) · [GitHub Issues](https://github.com/JammesPark/R36S-ROM-STORE/issues) · [GPL-3.0](../LICENSE) · [NOTICE](../NOTICE.md) · [Contributors](../CONTRIBUTORS.md)
