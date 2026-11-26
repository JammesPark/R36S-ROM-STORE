<p align="center"><img src="images/atual/logo_hd.png" alt="R36S ROM STORE" width="340"></p>

# R36S ROM STORE

<p align="center">
  <img alt="R36S e R36H" src="https://img.shields.io/badge/Console-R36S%20%7C%20R36H-0891b2?style=for-the-badge">
  <img alt="Sistemas: dArkOSRE, dArkOS, dArkOSen, ArkOS, ArchR" src="https://img.shields.io/badge/Sistema-dArkOSRE%20%7C%20dArkOS%20%7C%20dArkOSen%20%7C%20ArkOS%20%7C%20ArchR-ffdc49?style=for-the-badge">
</p>

[🇧🇷 Português](../README.md) · [🇺🇸 English](README.en.md) · [🇪🇸 Español](README.es.md) · [🇷🇺 Русский](README.ru.md)

**Статус:** 0.7.0-beta — официальная бета-версия.

## О проекте

Независимое приложение для ретроигр на R36S и R36H, разработанное на Lua и LÖVE 11.5. Каталог ROM, поиск, обложки, избранное, локальная библиотека, установка на SD1/SD2, BIOS, темы EmulationStation, очередь и история загрузок, инструменты. Две встроенные темы Matrix и Pulse; четыре языка.

## Важно

⚠️ **Бета-версия.** Основные функции протестированы в симулированной среде на компьютере и на консолях R36S и R36H. Некоторые функции и сочетания операционных систем требуют дополнительной проверки. Приветствуются сообщения об ошибках, предложения и вклад сообщества.

Создайте резервную копию и используйте только разрешённые материалы. GPL-3.0 не предоставляет прав на сторонние ROM, BIOS, изображения или темы.

## Загрузки

| Пакет | Загрузка |
|---|---|
| Автоматический установщик (.sh), последняя активная официальная версия с OTA | [Скачать SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) |
| Полная установка 0.7.0-beta с OTA | [ZIP](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.0-beta/R36S_ROMS_STORE_0.7.0-beta.zip) |
| Ручное обновление 0.7.0-beta | [UPDATE.zip](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.0-beta/R36S_ROMS_STORE_0.7.0-beta_UPDATE.zip) |
| Предыдущие версии | [История выпусков](https://github.com/JammesPark/R36S-ROM-STORE/releases) |

Скопируйте SH в ports, подключитесь к интернету и запустите его через EmulationStation. Скрипт скачивает и проверяет активную официальную версию. Автоматические тесты пройдены; проверка скрипта на консоли ещё предстоит. Ручное обновление содержит только папку приложения с game.love, без скрипта запуска и пользовательских данных. Используйте только с существующей установкой той же структуры, предварительно сделав резервную копию. Полный ZIP уже включает OTA.

## Интерфейс

Утверждённое оформление следующего выпуска; реальные снимки LÖVE в 640×480 из изолированной среды. Доступная версия — 0.7.0-beta.

| Matrix Edition | Pulse Edition |
|:---:|:---:|
| <img src="images/atual/matrix-menu.png" width="320" alt="Matrix"> | <img src="images/atual/pulse-menu.png" width="320" alt="Pulse"> |

## Установка

Распакуйте полный ZIP 0.7.0-beta в `ports/` карты. Запустите `R36S ROMS STORE.sh` рядом с `r36sromsstore/` через EmulationStation при наличии LÖVE 11.5. Для первой синхронизации подключитесь к интернету.

## Совместимость и тесты

R36S и R36H проверены сопровождающим проекта на реальных устройствах. dArkOSen тестировался с различиями в управлении; установка на ArchR проверена. dArkOSRE, dArkOS и ArkOS учитываются при разработке; полная проверка всех сочетаний ещё предстоит.

## Обновления

Для официальных выпусков используйте встроенное сетевое обновление. Перед обновлением создайте резервную копию.

## Разработка и авторство

Lua/LuaJIT/LÖVE, Python, Shell Script, HTML, JSON/YAML/XML, Markdown, GitHub Actions и Cloudflare R2. Основано на R36S PORT HUB автора Lag do Lira; JammesPark поддерживает производный проект при помощи ChatGPT (OpenAI). Исходное авторство и лицензии сохранены.

[Telegram](https://t.me/R36SPORTSBR) · [GitHub Issues](https://github.com/JammesPark/R36S-ROM-STORE/issues) · [GPL-3.0](../LICENSE) · [NOTICE](../NOTICE.md) · [Contributors](../CONTRIBUTORS.md)
