<p align="center"><img src="../port/r36sromstore/logo_hd.png" alt="R36S ROM STORE" width="340"></p>

# R36S ROM STORE

<p align="center">
  <img alt="R36S e R36H" src="https://img.shields.io/badge/Console-R36S%20%7C%20R36H-0891b2?style=for-the-badge">
  <img alt="Sistemas: dArkOSRE, dArkOS, dArkOSen, ArkOS, ArchR" src="https://img.shields.io/badge/Sistema-dArkOSRE%20%7C%20dArkOS%20%7C%20dArkOSen%20%7C%20ArkOS%20%7C%20ArchR-ffdc49?style=for-the-badge">
</p>

[🇧🇷 Português](../README.md) · [🇺🇸 English](README.en.md) · [🇪🇸 Español](README.es.md) · [🇷🇺 Русский](README.ru.md)

**Estado:** 0.7.2-beta — versión oficial BETA.

## Acerca del proyecto

Gestor independiente de juegos retro para R36S, desarrollado en Lua y LÖVE 11.5. Permite gestionar ROMs, BIOS, temas de EmulationStation y herramientas con los controles físicos, SD1/SD2 y resolución lógica de 640×480. El responsable ha probado físicamente tanto R36S como R36H. Basado en R36S PORT HUB de Lag do Lira; no es un producto oficial del proyecto original ni del fabricante.

## Aviso importante

⚠️ **Versión BETA.** Las funciones principales se han probado en un entorno simulado en el ordenador y en las consolas R36S y R36H. Algunas funciones y combinaciones de sistemas operativos aún requieren validación adicional. Se agradecen los informes de errores, sugerencias y contribuciones de la comunidad.

Software Beta: haga copias de seguridad. Descargue y utilice únicamente contenido para el que tenga autorización. La licencia GPL-3.0 del software no concede derechos sobre ROMs, BIOS, imágenes o temas de terceros. La compatibilidad varía.

## Descargas

| | Download |
|---|---|
| Instalador automático (.sh) — versión oficial activa con OTA | [SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) |
| Instalación completa con OTA | [ZIP](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.2-beta/R36S_ROM_STORE_0.7.2-beta.zip) |
| Actualización manual | [UPDATE.zip](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.2-beta/R36S_ROM_STORE_0.7.2-beta_UPDATE.zip) |
| Versiones anteriores | [Releases](https://github.com/JammesPark/R36S-ROM-STORE/releases) |

Para migrar desde 0.7.0-beta o anterior, use el SH o ZIP completo. UPDATE.zip requiere la nueva estructura r36sromstore/. Haga una copia de seguridad. El canal OTA anterior permanece en 0.7.0-beta. El SH del nuevo canal pasó las pruebas automatizadas; falta confirmar su prueba física independiente.

## Interfaz

| Matrix Edition | Pulse Edition |
|:---:|:---:|
| <img src="images/atual/matrix-menu.png" width="320" alt="Matrix"> | <img src="images/atual/pulse-menu.png" width="320" alt="Pulse"> |


Matrix es el tema predeterminado en instalaciones nuevas; Pulse es alternativo. Colores independientes y vistas Lista, Cuadrícula y Vitrina. Capturas reales de la aplicación a 640×480 en un entorno aislado, no mediciones de hardware físico.

## Funciones

- Catálogo de ROMs con más de 15.000 registros de la colección validada, búsqueda, carátulas, regiones, favoritos y categorías por sistema; los totales cambian con el catálogo.
- Biblioteca local, selección SD1/SD2 y gestión de ROMs instaladas por la tienda.
- Tienda de temas: 100 temas en el catálogo probado, vistas previas, instalación en segundo plano, activación, actualizaciones y eliminación de temas instalados, incluidos externos; advertencia para temas no verificados y protección del tema activo y de fábrica.
- Cola compartida ROMs/temas, velocidad, progreso, tiempo restante, cancelación durante la descarga, historial y acceso a detalles.
- BIOS y utilidades: tarjetas SD, controles, diagnóstico de red, Wi-Fi, FTP, archivos, PortMaster/runtimes, información del dispositivo, copias de seguridad y registros según firmware.
- Apariencia, colores, tamaño de texto y cuatro idiomas; catálogo válido y carátulas en caché sin conexión.

## Instalación y migración

Haga una copia de seguridad. Extraiga el ZIP completo en `ports/` de la tarjeta. La nueva estructura contiene `R36S ROM STORE.sh` junto a `r36sromstore/` con `game.love`. Abra desde Ports de EmulationStation con LÖVE 11.5 disponible. Conéctese a internet para sincronizar inicialmente.

Migre primero con el instalador completo. Conserve la carpeta, el lanzador y las copias de seguridad anteriores hasta comprobar los datos de la tarjeta. La nueva estructura tiene su propio canal OTA. El canal anterior continúa en 0.7.0-beta.

## Controles

| Botón | Acción |
|---|---|
| Dirección / analógico izquierdo | Navegar |
| A / B | Detalles/confirmar / volver/cancelar |
| X | Buscar ROMs, instalar temas, borrar historial de descargas |
| Y | Acción contextual, eliminar tema, información/acciones de descargas |
| L1/R1 | Categorías y filtros |
| L2/R2 | Vistas de ROMs y vistas previas de temas |
| SELECT | Favorito ROM; seleccionar sistema/pantalla de temas |
| START | Descargas; opciones de temas; apoyo en Acerca de |
| FN | Captura si es compatible |

## Compatibilidad y ayuda

El responsable ha probado físicamente R36S y R36H. dArkOSen se probó con diferencias de controles; también se probó la instalación en ArchR. dArkOSRE, dArkOS y ArkOS son sistemas de referencia; falta la validación completa de cada combinación de modelo y firmware. AmberELEC, ROCKNIX, JELOS, KNULLI y Batocera tienen datos de detección/compatibilidad de temas, no certificación integral. No se probó físicamente el aviso automático de actualización de temas ni la eliminación de un tema instalado estrictamente de forma manual; sí la eliminación mediante ThemeMaster y de temas fuera del catálogo. El responsable aprobó la lista de pruebas físicas y la migración; no se confirmó por separado la OTA en vivo ni el SH del nuevo canal en la consola.

Internet es necesario para la primera sincronización y nuevas descargas. Cambie el tema activo antes de eliminarlo. Informe versión, firmware y error sin datos privados.

[Telegram](https://t.me/r36sportsromstorebr) · [Issues](https://github.com/JammesPark/R36S-ROM-STORE/issues) · [Guía de ayuda (PT-BR)](SUPORTE.md)

## Desarrollo y créditos

Código en `src/`; compilación: `sh tools/build.sh`. [Historial](../CHANGELOG.md) · [Roadmap posterior al lanzamiento](ROADMAP.md) · [Publicación](HISTORICO_RELEASES.md). Las clasificaciones y otras propuestas son mejoras futuras, no funciones actuales.

[JammesPark](https://github.com/JammesPark) · [Lag do Lira](https://github.com/liralflsti-wq/r36s-port-hub) · [ChatGPT (OpenAI)](https://chatgpt.com/) · [NOTICE](../NOTICE.md) · [Contributors](../CONTRIBUTORS.md) · [GPL-3.0](../LICENSE)

Lag do Lira es autor del proyecto base, temas originales Matrix/Pulse y herramientas heredadas. JammesPark mantiene la adaptación; ChatGPT asiste al desarrollo. Vistas ThemeGallery: Dave, MIT. Créditos y licencias de terceros se mantienen.
