#!/bin/sh
# R36S ROMS STORE - instalador do pacote completo publicado (GPL-3.0)
# Executar com: sh INSTALAR_R36S_ROM_STORE.sh
set -eu
# Preserva a saida original para entregar o controle ao launcher oficial.
exec 3>&1 4>&2
# Adaptado do instalador independente R36SPORTSBR STORE; colaboracao JammesPark e ChatGPT.
# Projeto-base R36S PORT HUB por Lag do Lira (GPL-3.0).
# O preload do HUD do Omni36OS pode ser ELF32 enquanto Python/curl sao ELF64.
# Retira apenas do processo do instalador e dos seus filhos; nao altera o console.
unset LD_PRELOAD 2>/dev/null || :
# Capture failures that happen before the installation log on the SD is ready.
BOOT_LOG=/tmp/R36S_ROMS_STORE_instalador_inicio.log
( umask 077; : > "$BOOT_LOG" ) 2>/dev/null || :
exec 2>> "$BOOT_LOG"
printf 'Installer started: %s\n' "$(date 2>/dev/null || echo now)" >> "$BOOT_LOG" 2>/dev/null || :
FEED_ROOT='https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE-UPDATES/main/ota'
APP_NAME=''
LAUNCHER_NAME=''
# Escolhe automaticamente o idioma do EmulationStation (prioritario) ou do Linux.
# Idiomas: pt, en, es, ru. Locale nao reconhecido: ingles.
# Ainda aceita selecao manual por --lang=pt|en|es|ru, sem solicitar teclado.
DEST=''
INSTALL_LANG="${R36SBR_INSTALL_LANG:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    sd1|sd2|/roms/ports|/roms2/ports) DEST="$1" ;;
    pt|pt-BR|pt_BR|portugues|português) INSTALL_LANG=pt ;;
    en|en-US|en_US|english) INSTALL_LANG=en ;;
    es|es-ES|es_ES|espanol|español) INSTALL_LANG=es ;;
    ru|ru-RU|ru_RU|русский) INSTALL_LANG=ru ;;
    --lang=*) INSTALL_LANG="${1#--lang=}" ;;
    --lang) shift; [ "$#" -gt 0 ] || exit 2; INSTALL_LANG="$1" ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
if [ -z "$INSTALL_LANG" ]; then
  INSTALL_LANG="$(python3 - <<'PY_LOCALE' 2>/dev/null || printf en
import os,re,pathlib,xml.etree.ElementTree as ET
cfg=[pathlib.Path.home()/'.emulationstation/es_settings.cfg',
     pathlib.Path('/home/ark/.emulationstation/es_settings.cfg'),
     pathlib.Path('/userdata/system/configs/emulationstation/es_settings.cfg'),
     pathlib.Path('/etc/emulationstation/es_settings.cfg')]
def normal(v):
    t=v.lower().replace('-', '_').strip()
    if re.search(r'(^|[^a-z])(pt|portug|brazil|brasil)',t):return 'pt'
    if re.search(r'(^|[^a-z])(es|spanish|espan|castell)',t):return 'es'
    if re.search(r'(^|[^a-z])(ru|russian|рус)',t):return 'ru'
    if re.search(r'(^|[^a-z])(en|english|ingl)',t):return 'en'
    return None
for path in cfg:
    if not path.is_file():continue
    try:
        root=ET.parse(path).getroot()
        for node in root.iter():
            if node.attrib.get('name','').lower() in ('language','locale','uilanguage'):
                candidate=normal(node.attrib.get('value',''))
                if candidate:print(candidate);raise SystemExit(0)
    except (OSError,ET.ParseError):pass
for k in ('LC_ALL','LC_MESSAGES','LANGUAGE','LANG'):
    v=os.environ.get(k,'')
    if v:
        candidate=normal(v)
        if candidate:print(candidate);raise SystemExit(0)
for loc in ('/etc/default/locale','/etc/locale.conf'):
    try:
        for line in pathlib.Path(loc).read_text().splitlines():
            m=re.search(r'^(?:LANG|LC_ALL)=.?([^\"\s]+)',line)
            if m:
                candidate=normal(m.group(1))
                if candidate:print(candidate);raise SystemExit(0)
    except OSError:pass
print('en')
PY_LOCALE
)"
fi
case "$(printf '%s' "$INSTALL_LANG" | tr '[:upper:]' '[:lower:]')" in
  pt*|portug*|brasil*) INSTALL_LANG=pt ;;
  es*|spanish*|espan*) INSTALL_LANG=es ;;
  ru*|russian*) INSTALL_LANG=ru ;;
  en*|english*) INSTALL_LANG=en ;;
  *) INSTALL_LANG=en ;;
esac
if [ "$INSTALL_LANG" = es ]; then
  TX_FAIL='FALLO'; TX_ERROR='ERROR'; TX_CANCEL='Instalación cancelada';
  TX_LOG_FOLDER='Consulta el registro en ports de la tarjeta.'
  TX_LOG_SEND='Si la pantalla se cierra, envía instalador_ultimo.log.'
  TX_ENTER='Pulsa ENTER para volver al menú... '
  TX_MISSING_SD='Carpeta /roms/ports no encontrada. ¿Está montada la tarjeta?'
  TX_INVALID_DEST='Destino no válido. Usa sd1 o sd2.'
  TX_SD_UNAVAILABLE='Tarjeta no disponible o de solo lectura'
  TX_MKLOG='No se pudo crear la carpeta de registros'
  TX_PREP_UI='No se pudo preparar la interfaz'
  TX_PREP_CHANNEL='No se pudo crear el canal de pantalla'
  TX_NO_PY='Python 3 no está instalado en la consola.'
  TX_NO_SHA='No se encontró sha256sum.'
  TX_SYMLINK='El destino contiene un enlace simbólico; operación cancelada.'
  TX_PENDING='Hay una actualización pendiente; abre la tienda antes de instalar.'
  TX_NO_SPACE='Sin espacio disponible para archivos temporales'
  TX_EDITION='Edición azul metálico · instalación segura'
  TX_TARGET='Destino'; TX_SOURCE='Fuente'; TX_LANGUAGE='Idioma'
  TX_STEP1='[1/4] BUSCANDO VERSIÓN OFICIAL'
  TX_STEP2='[2/4] DESCARGANDO PAQUETE COMPLETO'
  TX_STEP3='[3/4] VERIFICANDO INTEGRIDAD SHA-256'
  TX_STEP4='[4/4] VALIDANDO E INSTALANDO ARCHIVOS'
  TX_FEED_ERR='No se pudo consultar la versión. Comprueba la conexión Wi-Fi.'
  TX_VERSION='Versión oficial encontrada'
  TX_RECEIVED='Recibidos'
  TX_DL_END='Descarga completada'; TX_DL_OK='Paquete recibido correctamente'
  TX_DL_ERR='Falló la descarga. No se instaló nada.'
  TX_SHA_ERR='SHA-256 incorrecto: instalación cancelada.'
  TX_SHA_OK='SHA-256 correcto: paquete auténtico e íntegro'
  TX_IDENTITY='IDENTIDAD OFICIAL'; TX_DONE='INSTALACIÓN COMPLETADA'
  TX_OPEN='Abriendo R36S ROMS STORE automáticamente...'
  TX_LOVE='Requiere LÖVE 11.5 de PortMaster; reinicia EmulationStation si no aparece.'
elif [ "$INSTALL_LANG" = pt ]; then
  TX_FAIL='FALHA'; TX_ERROR='ERRO'; TX_CANCEL='Instalacao cancelada';
  TX_LOG_FOLDER='Confira o log na pasta ports do cartao.'
  TX_LOG_SEND='Se a tela fechar, envie o arquivo instalador_ultimo.log.'
  TX_ENTER='Pressione ENTER para voltar ao menu... '
  TX_MISSING_SD='Pasta /roms/ports nao encontrada; cartao SD desmontado?'
  TX_INVALID_DEST='Destino invalido. Use sd1 ou sd2.'
  TX_SD_UNAVAILABLE='SD indisponivel ou somente leitura'
  TX_MKLOG='Nao foi possivel criar pasta de logs em'
  TX_PREP_UI='Nao foi possivel preparar a interface'
  TX_PREP_CHANNEL='Nao foi possivel criar canal de tela'
  TX_NO_PY='Python 3 nao encontrado no console; instalador precisa desta dependencia.'
  TX_NO_SHA='sha256sum nao encontrado no console.'
  TX_SYMLINK='Destino contem link simbolico; abortando.'
  TX_PENDING='Atualizacao anterior pendente; abra a loja antes de instalar.'
  TX_NO_SPACE='Sem espaco para baixar pacote temporario'
  TX_EDITION='Edicao azul-metalica · instalacao segura'
  TX_TARGET='Destino'; TX_SOURCE='Fonte'; TX_LANGUAGE='Idioma'
  TX_STEP1='[1/4] CONSULTANDO VERSAO OFICIAL'
  TX_STEP2='[2/4] BAIXANDO PACOTE COMPLETO'
  TX_STEP3='[3/4] VERIFICANDO INTEGRIDADE SHA-256'
  TX_STEP4='[4/4] VALIDANDO E INSTALANDO ARQUIVOS'
  TX_FEED_ERR='Falha ao consultar atualizacao oficial; verifique Wi-Fi.'
  TX_VERSION='Versao oficial encontrada'
  TX_RECEIVED='Recebidos'
  TX_DL_END='Download concluido'; TX_DL_OK='Pacote recebido com sucesso'
  TX_DL_ERR='Falha no download. Nada foi instalado.'
  TX_SHA_ERR='SHA-256 incorreto: instalacao cancelada.'
  TX_SHA_OK='SHA-256 validado: pacote autentico e integro'
  TX_IDENTITY='IDENTIDADE OFICIAL'; TX_DONE='INSTALACAO FINALIZADA'
  TX_OPEN='Abrindo R36S ROMS STORE automaticamente...'
  TX_LOVE='Requer runtime LÖVE 11.5 do PortMaster; reinicie o EmulationStation se nao aparecer.'
elif [ "$INSTALL_LANG" = ru ]; then
  TX_FAIL='ОШИБКА'; TX_ERROR='ОШИБКА'; TX_CANCEL='Установка отменена';
  TX_LOG_FOLDER='Журнал установки сохранён на карте памяти.'
  TX_LOG_SEND='При ошибке отправьте instalador_ultimo.log.'
  TX_ENTER='Нажмите ENTER, чтобы выйти... '
  TX_MISSING_SD='Папка /roms/ports не найдена.'
  TX_INVALID_DEST='Неправильная карта памяти. Выберите sd1 или sd2.'
  TX_SD_UNAVAILABLE='Карта недоступна или защищена от записи'
  TX_MKLOG='Не удалось создать папку журнала'
  TX_PREP_UI='Ошибка графического интерфейса'
  TX_PREP_CHANNEL='Не удалось открыть экран'
  TX_NO_PY='Python 3 не установлен.'
  TX_NO_SHA='Команда sha256sum не найдена.'
  TX_SYMLINK='Обнаружена символическая ссылка.'
  TX_PENDING='Сначала завершите предыдущее обновление.'
  TX_NO_SPACE='Недостаточно свободного места'
  TX_EDITION='Безопасная установка · Синий интерфейс'
  TX_TARGET='Карта'; TX_SOURCE='Источник'; TX_LANGUAGE='Язык'
  TX_STEP1='[1/4] ПРОВЕРКА ВЕРСИИ'
  TX_STEP2='[2/4] ЗАГРУЗКА ПАКЕТА'
  TX_STEP3='[3/4] ПРОВЕРКА SHA-256'
  TX_STEP4='[4/4] УСТАНОВКА ФАЙЛОВ'
  TX_FEED_ERR='Нет подключения к GitHub. Проверьте Wi-Fi.'
  TX_VERSION='Найдена версия'
  TX_RECEIVED='Получено'
  TX_DL_END='Загрузка завершена'; TX_DL_OK='Файлы загружены'
  TX_DL_ERR='Ошибка загрузки. Ничего не установлено.'
  TX_SHA_ERR='Неверный SHA-256. Установка отменена.'
  TX_SHA_OK='SHA-256 проверен'
  TX_IDENTITY='ОФИЦИАЛЬНАЯ ЭМБЛЕМА'; TX_DONE='УСТАНОВКА ЗАВЕРШЕНА'
  TX_OPEN='Автоматический запуск R36S ROMS STORE...'
  TX_LOVE='Требуется LÖVE 11.5 из PortMaster.'
else
  TX_FAIL='FAILED'; TX_ERROR='ERROR'; TX_CANCEL='Installation cancelled';
  TX_LOG_FOLDER='Check the installer log on the SD card.'
  TX_LOG_SEND='If the screen closes, send instalador_ultimo.log.'
  TX_ENTER='Press ENTER to return to menu... '
  TX_MISSING_SD='/roms/ports is missing. Insert the SD card.'
  TX_INVALID_DEST='Invalid destination. Use sd1 or sd2.'
  TX_SD_UNAVAILABLE='SD card missing or read-only'
  TX_MKLOG='Could not create the logs folder'
  TX_PREP_UI='Could not initialize the installer screen'
  TX_PREP_CHANNEL='Could not open the screen output'
  TX_NO_PY='Python 3 is required.'
  TX_NO_SHA='sha256sum is missing.'
  TX_SYMLINK='Unsafe symbolic link detected in destination.'
  TX_PENDING='A previous update is pending. Launch the store first.'
  TX_NO_SPACE='Not enough free space'
  TX_EDITION='Blue-metallic edition · secure installation'
  TX_TARGET='Target'; TX_SOURCE='Source'; TX_LANGUAGE='Language'
  TX_STEP1='[1/4] CHECKING OFFICIAL VERSION'
  TX_STEP2='[2/4] DOWNLOADING FULL PACKAGE'
  TX_STEP3='[3/4] CHECKING SHA-256 INTEGRITY'
  TX_STEP4='[4/4] VALIDATING AND INSTALLING FILES'
  TX_FEED_ERR='Could not check the official version. Check Wi-Fi.'
  TX_VERSION='Official version found'
  TX_RECEIVED='Received'
  TX_DL_END='Download complete'; TX_DL_OK='Package downloaded successfully'
  TX_DL_ERR='Download failed. Nothing was installed.'
  TX_SHA_ERR='SHA-256 mismatch: installation cancelled.'
  TX_SHA_OK='SHA-256 validated: package is authentic'
  TX_IDENTITY='OFFICIAL BRAND'; TX_DONE='INSTALLATION COMPLETE'
  TX_OPEN='Opening R36S ROMS STORE automatically...'
  TX_LOVE='Requires PortMaster LÖVE 11.5; restart EmulationStation if needed.'
fi
TMP=''
GUI=0; GUI_PID=''
INSTALL_SUCCESS=0
LOG='/tmp/R36S_ROMS_STORE_instalador_ultimo.log'
DISPLAY_TARGET=''
if [ -c /dev/tty0 ] && [ -w /dev/tty0 ]; then DISPLAY_TARGET=/dev/tty0
elif [ -c /dev/tty1 ] && [ -w /dev/tty1 ]; then DISPLAY_TARGET=/dev/tty1; fi
SCRIPT_PATH="$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")"
ui_state() {
  [ "$GUI" -eq 1 ] || return 0
  printf '%s|%s|%s\n' "$1" "$2" "${3:-}" > "$TMP/ui.state.next" 2>/dev/null &&
    mv -f "$TMP/ui.state.next" "$TMP/ui.state" 2>/dev/null || :
}
finish_installer() {
  status=$?
  trap - 0 1 2 3 15
  if [ "$status" -ne 0 ]; then
    # Display the LAST concrete error, not only the generic "installation failed".
    message=''
    if [ -f "$LOG" ]; then
      message="$(grep -E 'ValueError:|FileNotFoundError:|PermissionError:|Traceback|SHA-256|ERROR:|ERRO:|FALHA:|error:|unexpected file:|arquivo inesperado:|no such file|not found' "$LOG" 2>/dev/null | tail -n 1 | tr '|\r\n' '   ' | cut -c 1-68 || :)"
    fi
    [ -n "$message" ] || message="$TX_CANCEL ($status)"
    ui_state error 0 "$message"
    printf '\n  [%s] %s (code %s).\n' "$TX_FAIL" "$TX_CANCEL" "$status"
    printf '  Detalhe: %s\n' "$message"
    printf '  LOG: %s\n' "$LOG"
    printf '  %s\n' "$TX_LOG_SEND"
    if [ -n "${DEST:-}" ] && [ -d "$DEST" ] && [ -f "$LOG" ] && [ ! -L "$DEST/instalador_ultimo.log" ]; then
      cp "$LOG" "$DEST/instalador_ultimo.log" 2>/dev/null || :
    fi
    if [ "$GUI" -eq 0 ] && [ -n "$DISPLAY_TARGET" ]; then
      printf '\n[%s] %s\nLOG: %s\n' "$TX_FAIL" "$message" "$LOG" > "$DISPLAY_TARGET" 2>/dev/null || :
    fi
  else
    ui_state done 100 "$TX_DONE"
  fi
  # The progress window remains on screen before EmulationStation resumes.
  if [ "${R36SBR_INSTALLER_TEST:-0}" != 1 ] && [ "${R36SBR_INSTALLER_FAST_TEST:-0}" != 1 ]; then
    if [ "$GUI" -eq 1 ]; then
      if [ "$status" -eq 0 ]; then sleep 10; else sleep 40; fi
    elif [ -t 0 ]; then
      printf '\n  %s' "$TX_ENTER"; IFS= read -r _ || sleep 20
    else
      sleep 25
    fi
  fi
  if [ -n "${TMP:-}" ] && [ -s "$TMP/ui.error" ] && [ -f "$LOG" ]; then
    printf '\n[SDL GRAPHICS DIAGNOSTICS]\n' >> "$LOG"
    cat "$TMP/ui.error" >> "$LOG"
  fi
  if [ -n "${GUI_PID:-}" ]; then
    kill "$GUI_PID" 2>/dev/null || :
    wait "$GUI_PID" 2>/dev/null || :
  fi
  if [ -n "${TMP:-}" ] && [ -d "$TMP" ]; then rm -rf -- "$TMP"; fi
  # So entrega o controle ao launcher apos instalar e fechar a interface SDL.
  # Nao usa processo em segundo plano: o EmulationStation aguarda a loja sair.
  if [ "$status" -eq 0 ] && [ "$INSTALL_SUCCESS" -eq 1 ] &&
     [ "${R36SBR_INSTALLER_TEST:-0}" != 1 ]; then
    LAUNCHER="$DEST/$LAUNCHER_NAME"
    if [ ! -f "$LAUNCHER" ] || [ -L "$LAUNCHER" ] || ! command -v bash >/dev/null 2>&1; then
      printf 'ERROR: official launcher or bash unavailable: %s\n' "$LAUNCHER" >&2
      exit 1
    fi
    if [ "$(dirname -- "$SCRIPT_PATH")" = "$(readlink -f -- "$DEST")" ]; then
      case "$(basename -- "$SCRIPT_PATH")" in
        INSTALAR_R36S_ROM_STORE*.sh|INSTALAR_R36S_ROMS_STORE*.sh)
          rm -f -- "$SCRIPT_PATH" || { printf 'ERROR: installer could not remove itself.\n' >&2; exit 1; } ;;
      esac
    fi
    sync
    printf 'Opening official launcher: %s\n' "$LAUNCHER"
    cd "$DEST" || exit 1
    exec 1>&3 2>&4 3>&- 4>&-
    exec bash "$LAUNCHER"
  fi
  exit "$status"
}
trap 'finish_installer' 0
trap 'exit 130' 2
trap 'exit 143' 15
fail() { printf '\n  [%s] %s\n' "$TX_ERROR" "$*" >&2; exit 1; }
case "$DEST" in
  '')
    for candidate in /roms/ports /roms2/ports; do
      if [ -d "$candidate" ] && [ "$(dirname -- "$SCRIPT_PATH")" = "$(readlink -f -- "$candidate")" ]; then DEST="$candidate"; break; fi
    done
    if [ -z "$DEST" ]; then
      if [ -d /roms/ports ]; then DEST=/roms/ports
      elif [ -d /roms2/ports ]; then DEST=/roms2/ports
      else fail "$TX_MISSING_SD"; fi
    fi ;;
  sd1) DEST=/roms/ports ;;
  sd2) DEST=/roms2/ports ;;
esac
case "$DEST" in /roms/ports|/roms2/ports) ;; *) fail "$TX_INVALID_DEST" ;; esac
[ -d "$DEST" ] && [ -w "$DEST" ] || fail "$TX_SD_UNAVAILABLE: $DEST"
[ ! -L "$DEST/instalador_ultimo.log" ] || fail "$TX_SYMLINK"
LOG="$DEST/instalador_ultimo.log"
# Permanent log is created BEFORE SDL startup, download, and ZIP extraction.
if [ -f "$BOOT_LOG" ]; then cp "$BOOT_LOG" "$LOG" 2>/dev/null || :; fi
: >> "$LOG" || fail "$TX_MKLOG: $LOG"
exec >> "$LOG" 2>&1
printf 'Installer log enabled: %s\n' "$LOG"
command -v python3 >/dev/null 2>&1 || fail "$TX_NO_PY"
command -v sha256sum >/dev/null 2>&1 || fail "$TX_NO_SHA"
for folder in r36sromsstore r36sromstore; do
  [ ! -L "$DEST/$folder" ] && [ ! -L "$DEST/$folder/backups" ] || fail "$TX_SYMLINK"
  [ ! -f "$DEST/$folder/backups/.journal" ] || fail "$TX_PENDING"
done
TMP="$(mktemp -d "$DEST/.r36sbr_instalador.XXXXXXXX")" || fail "$TX_NO_SPACE"
# GUI is embedded into THIS .sh. It uses SDL2 available on most R36S systems.
# Its failure never affects installation: terminal remains a safe fallback.
if [ "${R36SBR_INSTALLER_TEST:-0}" != 1 ] && [ "${R36SBR_INSTALL_GUI:-1}" != 0 ]; then
  cat > "$TMP/ui.py" <<'R36S_GUI_PY'
#!/usr/bin/env python3
"""R36S ROMS STORE installer graphics (SDL2, no pygame/Pillow needed at runtime).
Called from the .sh, never installed as a persistent file.
"""
import base64, ctypes, ctypes.util, io, os, pathlib, struct, sys, time, zipfile, zlib

W,H=640,480
GW,GH=11,18
# Populated by build step; a zlib compressed glyph atlas, not a font file.
FONT_DATA='c-rlqcU%<57r^I0kS3sl0TspG6OAQUewHYfXe^Ovj2JN(V?krV-dn&HQBkpi-589D4V4HA5eq5^iXbXTI}n6}Yrq}z+nw2&JrxC&J>Wi>KhCeq+u5C+*_k(Q-n<1sm(zl*QgHrDiZh;59C!Dl@)anZUSS38%ZQaYZP)}toiK)vsIIg@WK>Y+fANSQPLo;weJi*=3X9$!XrZvw5ZKG&=n$}N4gS0LY7jX9V^n{O!Wsfq!P{7EU9vjV5#ih?%>ugoh4A=RD&UsXouJ;F*n+FWNDi0A$_CNQF8;y(yJdXcGo4<cr_*T93w7+&_gwhXQ+WPKQ_|>7eCCt;HQu=pfX|SC^psis-J9@nOV1-M5LBOYrYk2KI1KzOP8-jnKB$$}q)}2Gbi8(2qlU@2X2GP4j7fqvD31)N#N;UXoE#jMsYlQ#Z5F{LX-abIId&_Ptw4G!1`h+#`AgLcj2H}M%9#*;g%yylwzk>{C$RWca9;AxrDAJAi!m{x>{!{-58;FiUpNwUel8+-ej62)xDcuVN%IHha9{}nnx{EG6Y-bmPY;g{FSjy`yGBtjb|hu@Fp4c<1O6_@QjA|v0*WNg1Y5v{1n1qLmxyzs7rrh~t+d_Cf!CDJ_qM)hi@K|+H<SGu;ht;C&17FZUU*IYd~X{ppmADdPR=*qi+GTTDU)oKPF}Dj!M%lb2tL_CsDYwx<+@!6bymwf4lPSS;Zh4#3xYmp30cW|6I^zWP<1iwu3VE12*%7KG%%mu?iDXWpQ{=X^!tlmw4iHw7GYtU{Cqt`;}!ku{)2n-n?3-10l!37b7i_x#jog<W)-KDr5NYM7-Q5BxV4kHXV?*CChun(#0?D#(-jx$3tA5bKi-C1Z~x8FuORLCLHS`z)SoR8vJ{=qy-N2(Y9BZ`ymrG-I#hvS(3aq|qM96;#_uCT*<X=n9PWHVB!5pNW97osCgf}>Dn$<=OVQLXGt<8@zM1c9+x{I#|1t=E#*y8bdssOf0%4>L8L;h7-J@@Y6|b6D!*AGs&U80xbTY+)#lgY38K+tbK25??ASU&>QNW>Pd@Ch~$L0eL$KBQ^nArvp!~-DJUC3$gL?Mzldkfwe{rRIBm@iM+g?k?N0cKyt2GYOuhs_DvL8?*qgH2IgbTR!h8h3aj??|6}nG0JJ{ckHCc0<&y(7i^}bqFu;J))FX1>uY+`GXM{pLH_*t*AANMJt$}jNe$i$71FT7N?{#0tKiYiI%0x?++HV5V$>zCjT8PqYo{_k5F^?Kic}}dt;DEM~P8IHguGrv(QGxLkO--)ff1su-q?}-p1O$-{WScYZT~)?lW`ehOie>uw$E;tbAgE9_nrg6Wb!$?U60aS7jnu71N=La?pgZ7~xzNgCd*PSXzLDKRb{vy){tKQq()~QhEjtNg>zmY9GFhuy`l{^<jI2L)d1Irk>ZX)~kKE09AqA-><TkJaQ+w=u3a3EmVzi8#&6X%d_3+h{fUj<lhads6wP|JxZ9{sT`WQ^*ruP?R8WcjvCC&Sn<YIT&HlrgviZ`&Dhk2{HOP^f?HGvv7Ub#RFd@CtnQ-(Dl8r9PH}I3w3`Ldq9%k%_jRO-Rt~;(GuMA*`#Z7ZD~*}X$sX>Z&HJss=&|e;R`mz3X<YLNZ%+F`MT~~^;(Q1t`jD=F^=+DmuYXB7`v;bU0;R!W(qs?R54t7|HEnWjC9>VHFJ|LZ7LS0|w{mvKSks@2DB8WoV#unpU)xDUKwrUP54&7~Kk)+o%xSqh@>mr2r5Ed$Im?DvsahRQFMLqFyozxPk~U(izPXyiDfe8WIlQ#eT8*`A^MZ~bd=A1fsUol_6ycxjYoSJ+kc1ts6J1$Uvz^%iq)6Roe_Rx10#-!=gwlK1=#{Vr7*A4v&LOA{T{twES=fq`h0<|E*3?PXo5+HI6BPXeNM-|NleyDm4`&P8qFM(?#G8#-vd`ITZ|RO^2m2%G-_zFez0njNCzmAPd!J(C+}#a6oB0hkz@5+IE+Je;Dt|B!zp>ECq;JAO4p|ku4MBsV=>$Qh2gM9eg4K9|zT`CHKJkaRODLk}R}*+(rYl9qgZQH*Ba-b@HrY2%^Axfallk?m$twP6$%tgzmQA)q6fAvnQ~ne;si6fktePzU0%<#Y_$J5CZ?KY!u_fpY;YNgPM;eCk*#?SE%1JfrJw^zIM<`Pc*$et!unjzAMcELg6(4*Wk3uCsbZ1;&zC=uqmm|J*34xOPYj57;4?z!#Pw|sxMtptwF9=`sF`HY2S7hcrl0|(hu*%9*xB0Dqj4_&qT{GeO$*ce3rw7Ld-s0xsFb$FgFBth_aX*@aZ?Yvp%akKD-@$McZBYlZZ3QfaXM*sET9lw`GSC+Q2Ru7SOEU#K;}9n7A6GqfHO5{+-ye6!C`yPJ#35Lbu1}C{mt{l2N|C~hstL#x4Amnkp1DfVNz$6&z-`_XTS{sW1VK|Nj)<YC|3XC&EE3k*tmm1bxQZvpi?h4cIr<#w$|;O)`xzWgTXpIhIx@r{!v_4C#a(X*q^)94Lw2{NS>3FUCZf#r*Jmn2S_`d#C}U?6rNMZN>Q|~iTslwj$^{OM#;T{1)8gifK2#a0Jaw^)uZx{;2&AIA7)tBnnGshPP(tgXO+MeYMjq2EH{(FYDQq={&Y)pXLUj&74?KHfu^a5pq3zjN12T;NQ=2<Y^kw=Yk^>m6Xh=|W-;W^pRxM<kGToRYxrA*62g6&L^~7do*$67|Y72FQ7_Ut78^sy<>P|h8e}~Q)8p>Sg3D0JtsrDc%i&=&3Sab+@DY>ByYcs?)&QhK4J{<)r#YE;u>GlbzLWnwrtZB?!p#Gl4V^Pg4mn+bCZLvK~8YZk^Cx=zaJyOt}IWRvF$Y}F)DFC(As1<Ap1z?m6wH?Qz8eq>Ebedt_P>}cwXQ$cLte8_T#>Y*)LkxrJyUWN$Zs6rw;SzEo6BYcx{G$1DUD$!OiJ|rkS%Xw4IG{2cm5ekz5dW;NJL)%8HW^EoZbLTLBDa&h0?(jTnE0^Yj54B-k^gLQ2M|__7P>d)>H!a>o{*)Gv#xUIgV{HDzSta$kfZgiYEhd_lICIwhk_G#h$-z5{E8#X^ju;!*mt|T5}R-P7IgrJLa>(0OpxkIksn?n`!E(|))KH3*=*)MafZxq>=po8tI(5lENlTTa;D<H&pIkN=YfWD@k(kE&olm*S%)y`ChDRd(=IcA9l=YFj5wO0>O$;pIdo2ODu&qgMyWb+R6B!Obq+@x63j)H5MuHj1L;acj2nMc3kZc+k<oA}(Qq}<a6r*;OVM;z(QskWbZpUZchPWy(R7W`aF_utRG+k%e;C4k{E(qVeC@*Jn5u;qlEsS6k3G|{*TkswMqqacvge7JMz4QvBls_sO$%}>i>xScJ7wz>ezB+z-<#-Ivf7#~55bneIn!!cY)aPfzCp&rCMPqBA=cNUj@yYWvEvXsCicOY>}A^S7RGM(l@Ess;8}FqyEHs-RvCvKR8AL<w^){s{G(3aWL}XBG}k-r%i1zG@wkBsh$nNWnJ><><T5LG>{t<%(fo`=ya}~5(-(*Atf#PwB5)Ja1*}~cK?&%VVMOOG$w%z0esRE=1>}i6gmFG-%5QLa8_kZ&lHD+FdDysdG)C!90Q`uNZ9DBb>_Rbr92M}2ZbVKqJ0^cItwOfb%zP%liyOh@r(H}&V;wP_)qH~&qFYy~)WvWYDG-;$bdv*^nmyF4jTiP{n;uv2aF!5VNX-i}GW;xzrUUZcBOLgnu8$M&JIoL7pN!f}CP(Bi+;Jn=7}ug<B*wg-0T}aki{ep3;E%YL4I(g_9+M}{g!M??y$jJ)qwhl7x|fe)wdMD8vEPR)?*2Zdp`V{L5!<=_6;5XB#b_A!XC_EZ@YV$XJ+#whPqV@cG^JuWr-90nkfz=cDoc?qJ7VR3fe>vb#knLT$&$IOb1AYPiCNT0G(gQM&Os2n9e!Y%C@uqjD;dDy5KIgX<_JtIkV&|{b7EniOV{<tY4vgz&>Wl#JJ5Xn9~zZ+MTjBftzaqTiSfVk=Gk*}N^2ihR1w~4SwWdIVp7nPEN;F<(O@rHbA1WM#)4^=(TxMANH8&!$FMS?c2gDUqe`1PZOBkwLq=BMp4Qpwz;mPpJ!OV%D;08+RiRA`GbyJ2Mg(eOfqAJNYx^dm(+oDfEC~Ig0!F=a`!6UT^}?ujwpg8wRw~ait-|0HvN4@wn^?qZ9@p{$Ka<l|=AvcIbH0HEv0vlN_&I#ZSgy%nN1pf>Wbp*^UbM5lhB09tJCZn%3b4Vb9!l}qTq>|QsjY1=M#J6tVpohvIV=s!FM0mE=Os+R2z|*$7SBwo(|PjS2R(zzj#^EkwJCY$kRA(0XMbTjU=_mo52--2%sZ?4bEa2wr>&Bs^e;{-WDcD-t!~ZzcwN=nJ2f{@;Qbetu+!U!r}LKY7I+7mXtay8HMHVJB&aH4y!epb^DiHEF%RM1qpYPJ;gqb_bpkLN|0#Vkt|EF`v_Iqua+kQbnCU%>(A<B1B%@BGpan8}*bD^zfrW1^s#(a*lxE+bkjQ0Gzc_}Pe8Z@NrB)O6;Ll`NOE=@2W_>inz})9x6mlhyS393#zX5sFDZYHNWI_nCDTM7h=5Qnr4fz`s6ZJEsXs{ds8-ak33MfT1^B7y;SO)E6y{g^Wf)7tm@_Im&x=X6IWZw8f=}KB+;1DTZu$`1;3w-XPH-la3G>zY&{Zgn|8}vc6fN^OD^U~%cb^6C_Log;A-I=juI5^K)e)gQSD(Z}}yK-qP$>T{Ool-1O+Y#JAd)?+aTsR95q}U-6q7?2L3$IMt{fL-w#>$9$e=F7^f{iv0=~nN9QACfOkVm&(?R`D7@>G=kUS)FFSKX1Ux&6dPVR7Ln8<Ss9!{Fs}<mti;Is({)^0s`p7bWH3%;(#aznbVk&dX0Lg-b+b#j>Zx%6oL_)-vz}J-*~$iVJwJtl7MybH9Rabi3CfNY>&VRegxl@9gN3a#$Qn$ov8^7A+}=tOz~#wRBSQc(zqbq>GL=@3>DAJ4AceZYycWkzP2RTFy98#cbyFb9xaBSWakEh+fsQaF)3)Dz!bT%%!N*GuASfqH5^0UM~kN$6G=~&ulIy)vHo(cbQ9}8#WLDSH!G>>9}beP0F^aFydokmTk!<@feyVtl!Mx=^=)Z&8kp~0t*!+LQ<W?Wyd)5nJBvMP|3%O4_URZ8g&ur)%3mD>PAni8`fq<e}Fb6;A=_>-J>&HLAsr4mq~{uI+Q|YsjdoIf`fb{v^ja*%)iAei3VFUvre}Wq7)zE(>soz<7fox)Ck|H1z%xZ*o~_jdna{cr<-o<h0zUfdEI!sb)!XTeXqT35Vgsg#F5x~>kDt1{P$jfZjW+_Q9i0`%`05gi|Edlm$+!GeV#}*0i8;fEDq5Jq;}D{B%JekrZ;NDqdg}OLj|gC`VjwW?WcwpNDpEhxs)9AIg5K35g3%nwWtV}q(0nVFBDT>h~E2+E4&2NCI{W|#<3KGH`<$h7lYh6Q2?@fk6AkhwsmYDz-vwHz6%`d>I6FxKgLcu98o06Ww%_1@3?{2lA12?7^bJKQW%(Sil~R5^|c|UriS-X*M-akbsO?x{rC-Ri+G>9#_ZH_0ei1sqi$~H$Zo^U&T;ce7f<U7sTV%Vo<j&7uq1y>WD@eefx&@HLi>-GpXXN@+gG|*M8x0RgzbpgGE7QA`}No|1d8bz(%?uML(R61_HI!}A}=usnN}0l@JCBV2xWJtlcT0ig}+dNfB=gAXE`(;D4R-76FBmcZp4q$2y>x@pc+CY>}7zSx_d4&P`rf;vnYC|P}~ti@yIobp?^}$`-37kxU*J=iRhZrH}F3j2=`v-yCr}*nd}@zKGrS4C=Hp!H%CuTn3jV)FzYI>B)!0UaE&C)-QbzhNT~wmVb?+bBRk|Hi;*EvG1M(Vl!S)(Ttg<`_2>&YzJS3Fu!Vr7(2cmwY~YlIki<~Ydrrft40%X{temHzSL}0XKo(CLre$ab4c>B)59y-d1HJI!U&<l%doJBw^-EE5UFbyQB`ZGgyA?Zxi#Z%junybgG1|ZZ1RKCU1Y5FO-7xlt)&$S8Q5-OawxuXoUFb&SC7p;4rz6(pPkz3Yp)PbIew41nMAe0uMJjfF8Fmt>KB4S#_CTyKH3ch^kn*ITvRd?%bI)6y)Qfm2+p8a5AbDJZbSL4;RN~FqG>hyc3{q?p-graT--g5#!K|IATakNsio0ebyQRvQ5!i)7dt|b*%X4^qg#?VKfMl(Q*dYsP#a~Aj!R%c|Z(KsCq#MzGm`NQNh+hk#kbCuLwBV*C;-`<@Sqt8SV<;y2ni!2xB6N&X<(`!BewkSxfI{?9X3Ruv?{Ps9rQ<@D;xxFq1mK`iLZOEB0K923C@1RygcEr#8KEL-964$_i<_IW0{4$n^uJE=9yw|<0}h}$j1{zxLJITYkar_ghC7g>#_MwG5CK#5&s6r+GJ-}ba@2TzwiU_YMi(vz!StvPGs!3)yA$Qf*jYV=3S7SMw)$l>N;Ub7(}YScj}>>h4^R5Fv>1~|zwZJTC({wPD@4AvZm50JD2{C*-L5bU(vP4XOF@H+Zwr%O)i|>Waf-W6!j5_oz#&e4zyM?Xy84O8(>J0sv;k|;o|1_1asXUk;r5*g!02LhbZQ30@2NmUTmCdr0+ZQnoNw27#X&(oZ)33RNg;%&(XNm>8glJ7%8$MmvHK``<n*Y<q5ev?T5wyRAhY9+T4pRHvfJYg38J1#*!SWcHifF;72I!sxE}(;1DPv^<Il-$JVe*w^VdCBhT*0TQ#;n)kNwOc^Q3EGH*(1PnHTeZ=Bd2E^3;yC_H%ybYZH|f;%Dv+Vg3bdK=M8fYJ~6PaWxTuPwJDSMo0c72qwr0nq9n2WaZb|R6r?uv#mab!)pA|Petvf9(*Z!F!$g>P@iCLC?Ysm3J5wUQ}nn`5i20*12^auAO0o^ma0bls8Ui<C+7$df<l?>3m+FTA|KiNZDd!X;;}P@WdZYeQF(xCYBmgdfbfdvyaa3f)jd@kCWi~?CAtR~9QQ=~rKqz#O>!N7RBx_}RjrLVWU^=J8AsdPvsP4mQ!@Q5pBe6d_jEI<yEz-JUv$2lpAk?Ii}<XA`%n0*BMh3RQe69hpuNnI;9q;JIE<FmAqd?8!6$|U%USQ}RwuY8zp5dsnx!Z$Rf)(;rKa}$cWl~2OY$V!Lkogkpc%oQO#jQ_cNu_Iz!8e!4M4@zMH;)Jv<P_yvMV&TB?t@itbtb{!hpD~jS4m(^dDGwHMkQ-aJr~1K_<P0+JC#P=*v(N@|9J(tWO2ig>LLR{K!XL$?8Hk;zw1Pn5gef3pBT{IPt3wpN`s0RU|gc%*gj*<8!j&DEtZLXMW40zQbX*p*<sT4SxcyI)lefP(1!8!p01SB7ua1%cDjXq0{V{%pQy`+l9+D=|;34cHzPMba^34e27|?5>c?R`^{ab$9Gd)5nIpj8;lkK^1Q43HdU+AP>XfJPS3o&%LyU>)p_lXdf@mHkT~#@af~4?g+_e;uo6*#y5PTBZSxL<F#BYEa<u;Si&S7*I>EZZmx*l7S$pl*g%sHe1K*8MowQoS9o6qCb)^EK+sM)G`ICrj@;beZf!Z%c>4BXgEQlFHjvD={Zbbz2RHHep{&O+W;tOKOSHRf)MX>z&Qf&8F;9%<Th<*(Q^i|*i<0e&l+0>H9DOkY0v)Q1R__Wr+3X++2Qv_%jlCz6j)wp`LK@ze;MVJ@&1FO(#Swsie0JuoGE~q|mm7$|{uqXKa5kBqmpY@)vz-W6lXJ-Xi)kN!FLWnh<k@;;%IM7A6Xk^e~`K@S>&{dGgg7L8i+)?v%M<TH4l;8nHb;Cm&ct-&7f~sSu{Xef@>lX'
try:
    glyphbuf=zlib.decompress(base64.b85decode(FONT_DATA.encode('ascii')))
    glyphmap={c: glyphbuf[i*GW*GH:(i+1)*GW*GH] for i,c in enumerate(' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~áéíóúãõçâêàüñ¿¡ÁÉÍÓÚÃÕÇÜ°·•—✓○◌←→АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяЁё')}
except Exception:
    glyphmap={}

class Rect(ctypes.Structure):
    _fields_=[('x',ctypes.c_int),('y',ctypes.c_int),('w',ctypes.c_int),('h',ctypes.c_int)]

sdl=None
for lib in (ctypes.util.find_library('SDL2'), 'libSDL2-2.0.so.0','libSDL2.so','/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0','/usr/lib/arm-linux-gnueabihf/libSDL2-2.0.so.0'):
    if not lib: continue
    try: sdl=ctypes.CDLL(lib);break
    except OSError: pass
if sdl is None: sys.exit(10)

def setup(name,restype,args):
    f=getattr(sdl,name);f.restype=restype;f.argtypes=args;return f
P=ctypes.c_void_p; I=ctypes.c_int; U=ctypes.c_uint32; B=ctypes.c_uint8
setup('SDL_Init', I,[U]);setup('SDL_Quit',None,[])
setup('SDL_CreateWindow',P,[ctypes.c_char_p,I,I,I,I,U]);setup('SDL_DestroyWindow',None,[P])
setup('SDL_CreateRenderer',P,[P,I,U]);setup('SDL_DestroyRenderer',None,[P]);setup('SDL_RenderSetLogicalSize',I,[P,I,I])
setup('SDL_SetRenderDrawColor',I,[P,B,B,B,B]);setup('SDL_RenderClear',I,[P]);setup('SDL_RenderFillRect',I,[P,ctypes.POINTER(Rect)])
setup('SDL_RenderDrawRect',I,[P,ctypes.POINTER(Rect)]);setup('SDL_RenderPresent',None,[P])
setup('SDL_CreateRGBSurfaceFrom',P,[P,I,I,I,I,U,U,U,U]);setup('SDL_CreateTextureFromSurface',P,[P,P]);setup('SDL_FreeSurface',None,[P])
setup('SDL_RenderCopy',I,[P,P,P,ctypes.POINTER(Rect)]);setup('SDL_DestroyTexture',None,[P])
setup('SDL_SetTextureBlendMode',I,[P,I]);setup('SDL_PollEvent',I,[P]);setup('SDL_ShowCursor',I,[I])
try:setup('SDL_GetError',ctypes.c_char_p,[])
except AttributeError: pass

# Inherit platform SDL configuration (X11/Wayland/KMSDRM). Try KMSDRM only if default fails.
if sdl.SDL_Init(0x20)!=0:
    if os.environ.get('SDL_VIDEODRIVER'):sys.exit(11)
    os.environ['SDL_VIDEODRIVER']='kmsdrm'
    if sdl.SDL_Init(0x20)!=0:sys.exit(11)
window=sdl.SDL_CreateWindow(b'R36S ROM STORE Installer',0,0,W,H,0x00001001)
if not window:
    window=sdl.SDL_CreateWindow(b'R36S ROM STORE Installer',0,0,W,H,0x00000004)
if not window: sdl.SDL_Quit();sys.exit(12)
renderer=sdl.SDL_CreateRenderer(window,-1,0x2|0x4)
if not renderer:renderer=sdl.SDL_CreateRenderer(window,-1,0x1)
if not renderer:
    sdl.SDL_DestroyWindow(window);sdl.SDL_Quit();sys.exit(13)
sdl.SDL_RenderSetLogicalSize(renderer,W,H);sdl.SDL_ShowCursor(0)

# Maior contraste para telas LCD 640x480 e fontes sem anti-aliasing.
NAVY=(7,14,26); PANEL=(24,48,77); PANEL2=(26,59,95)
BORDER=(90,135,177); BLUE=(105,190,255); CYAN=(156,227,255)
SILVER=(255,255,255); DIM=(222,234,247); GREEN=(140,255,197); FAINT=(193,211,230)

def rect(x,y,w,h,col,border=None):
    sdl.SDL_SetRenderDrawColor(renderer,*col,255)
    r=Rect(int(x),int(y),int(w),int(h));sdl.SDL_RenderFillRect(renderer,ctypes.byref(r))
    if border:
        sdl.SDL_SetRenderDrawColor(renderer,*border,255);sdl.SDL_RenderDrawRect(renderer,ctypes.byref(r))

def surface_texture(rgba,w,h):
    # Memory layout RGBA bytes; explicit component masks support little and big endian.
    buf=(ctypes.c_ubyte*len(rgba)).from_buffer_copy(rgba)
    if sys.byteorder=='little': masks=(0xff,0xff00,0xff0000,0xff000000)
    else: masks=(0xff000000,0xff0000,0xff00,0xff)
    surf=sdl.SDL_CreateRGBSurfaceFrom(ctypes.cast(buf,P),w,h,32,w*4,*masks)
    if not surf:return None
    tex=sdl.SDL_CreateTextureFromSurface(renderer,surf);sdl.SDL_FreeSurface(surf)
    if tex:sdl.SDL_SetTextureBlendMode(tex,1)
    return tex

cache={}
def txt(s,x,y,size=13,color=SILVER):
    s=str(s).upper() if size==0 else str(s)
    if not s:return
    key=(s,color)
    if key not in cache:
        tw=GW*len(s); pixels=bytearray(tw*GH*4)
        for j,c in enumerate(s):
            g=glyphmap.get(c,glyphmap.get('?'))
            if not g:continue
            for yy in range(GH):
                for xx in range(GW):
                    aa=g[yy*GW+xx]
                    if aa:
                        idx=(yy*tw+j*GW+xx)*4
                        pixels[idx:idx+4]=bytes((*color,aa))
        cache[key]=surface_texture(pixels,tw,GH)
        if len(cache)>180:
            for k,t in list(cache.items())[:60]:
                if t:sdl.SDL_DestroyTexture(t)
                del cache[k]
    tex=cache.get(key)
    if tex:
        factor=size/14.0
        r=Rect(int(x),int(y),int(GW*len(s)*factor),int(GH*factor))
        sdl.SDL_RenderCopy(renderer,tex,None,ctypes.byref(r))

# Logo removida a pedido: titulo completo, renderizado como texto.
path_state=pathlib.Path(sys.argv[1]);path_ready=pathlib.Path(sys.argv[2])
lang=sys.argv[3];destination=sys.argv[4]
words={
'pt':('INSTALADOR AUTOMÁTICO','CONSULTANDO VERSÃO OFICIAL','BAIXANDO ARQUIVOS','VERIFICANDO INTEGRIDADE SHA-256','INSTALANDO ARQUIVOS','INSTALAÇÃO CONCLUÍDA','FALHA NA INSTALAÇÃO','AGUARDE','CONCLUÍDO','PENDENTE','EM ANDAMENTO','BAIXANDO PACOTE OFICIAL','PRESERVANDO CONFIGURAÇÕES','VERIFICANDO ARQUIVOS','PACOTE INSTALADO COM SUCESSO','FONTE'),
'en':('AUTOMATIC INSTALLER','CHECKING OFFICIAL VERSION','DOWNLOADING FILES','VERIFYING SHA-256 INTEGRITY','INSTALLING FILES','INSTALLATION COMPLETE','INSTALLATION FAILED','PLEASE WAIT','COMPLETE','PENDING','IN PROGRESS','DOWNLOADING OFFICIAL PACKAGE','PRESERVING SETTINGS','VERIFYING FILES','STORE INSTALLED SUCCESSFULLY','SOURCE'),
'es':('INSTALADOR AUTOMÁTICO','CONSULTANDO VERSIÓN OFICIAL','DESCARGANDO ARCHIVOS','VERIFICANDO INTEGRIDAD SHA-256','INSTALANDO ARCHIVOS','INSTALACIÓN COMPLETADA','ERROR DE INSTALACIÓN','ESPERA','COMPLETADO','PENDIENTE','EN PROGRESO','DESCARGANDO PAQUETE OFICIAL','CONSERVANDO AJUSTES','VERIFICANDO ARCHIVOS','TIENDA INSTALADA CORRECTAMENTE','FUENTE'),
'ru':('АВТОМАТИЧЕСКАЯ УСТАНОВКА','ПРОВЕРКА ВЕРСИИ','ЗАГРУЗКА ФАЙЛОВ','ПРОВЕРКА SHA-256','УСТАНОВКА ФАЙЛОВ','УСТАНОВКА ЗАВЕРШЕНА','ОШИБКА УСТАНОВКИ','ПОЖАЛУЙСТА, ПОДОЖДИТЕ','ГОТОВО','ОЖИДАНИЕ','ВЫПОЛНЯЕТСЯ','ЗАГРУЗКА ОФИЦИАЛЬНОГО ПАКЕТА','СОХРАНЕНИЕ НАСТРОЕК','ПРОВЕРКА ФАЙЛОВ','ПРОГРАММА УСТАНОВЛЕНА','ИСТОЧНИК')
}
L=words.get(lang,words['en'])
state={'phase':'check','pct':0,'message':''}
laststate=None

def fitted_text(value,x,y,preferred=18,color=SILVER,maxwidth=460,minsize=15):
    """Draw readable text without clipping at 640x480 in any of four languages."""
    value=str(value)
    if not value:
        return
    # Keep text at >= 15 logical points; messages may be split into two rows.
    width=len(value)*GW*preferred/14.0
    size=preferred if width<=maxwidth else max(minsize,int(preferred*maxwidth/width))
    if len(value)*GW*size/14.0>maxwidth:
        length=max(1,int(maxwidth*14/(GW*size))-1)
        value=value[:length-1]+'…'
    txt(value,x,y,size,color)

def draw():
    sdl.SDL_SetRenderDrawColor(renderer,*NAVY,255)
    sdl.SDL_RenderClear(renderer)
    rect(13,12,614,456,(13,26,45),BORDER)
    rect(14,13,612,6,BLUE)

    # Titulo grande: apenas o nome oficial, sem imagem/logotipo.
    title='R36S ROM STORE'
    title_size=23
    title_width=GW*len(title)*title_size/14.0
    txt(title,(W-title_width)/2,34,title_size,CYAN)
    subtitle=L[0]
    subtitle_size=17
    subtitle_width=GW*len(subtitle)*subtitle_size/14.0
    txt(subtitle,(W-subtitle_width)/2,82,subtitle_size,SILVER)
    rect(46,123,548,2,BLUE)

    # Informacoes de destino e fonte em duas areas, ambas com alto contraste.
    dest_label='SD1 / PORTS' if destination=='/roms/ports' else 'SD2 / PORTS'
    fitted_text(dest_label,53,132,16,SILVER,220)
    fitted_text('GITHUB RELEASES',374,132,16,CYAN,240)

    phase=state['phase']
    pct=max(0,min(100,state['pct']))
    done1=phase in ('download','verify','install','done')
    done2=phase in ('verify','install','done')
    done3=phase in ('install','done')
    done4=phase=='done'
    failed=phase=='error'

    # Etapa 1 — cartao com titulo e estado em linha propria (sem sobreposicao).
    rect(49,162,542,57,PANEL,BORDER)
    txt('✓' if done1 else '○',61,174,21,GREEN if done1 else CYAN)
    fitted_text('01  '+L[1],91,172,18,SILVER,482)
    fitted_text(L[8] if done1 else L[7],91,197,14,GREEN if done1 else DIM,470,14)

    # Etapa 2 — barra alta; percentual e titulo bem destacados.
    active=phase=='download'
    rect(49,225,542,89,PANEL2,BLUE if active else BORDER)
    fitted_text('02  '+L[2],63,233,19,SILVER,400)
    txt(str(pct if phase=='download' else (100 if done2 else 0))+'%',521,233,18,CYAN)
    shown_pct=pct if phase=='download' else (100 if done2 else 0)
    rect(64,268,510,17,(5,18,32),BORDER)
    if shown_pct:rect(66,270,int(506*shown_pct/100),13,BLUE)
    fitted_text(L[11] if not done2 else L[8],64,290,14,DIM,495,14)

    # Etapa 3 — mesma hierarquia visual da etapa 1.
    rect(49,320,542,55,PANEL,BORDER)
    txt('✓' if done3 else ('◌' if phase=='verify' else '○'),61,332,21,GREEN if done3 else CYAN)
    fitted_text('03  '+L[3],91,330,18,SILVER,488)
    fitted_text(L[8] if done3 else (L[10] if phase=='verify' else L[9]),91,354,14,GREEN if done3 else DIM,460,14)

    # Etapa 4 — instalar e confirmar preservacao de dados.
    rect(49,382,542,55,PANEL,BORDER)
    txt('✓' if done4 else ('◌' if phase=='install' else '○'),61,394,21,GREEN if done4 else CYAN)
    fitted_text('04  '+L[4],91,391,18,SILVER,488)
    detail=(L[8] if done4 else (str(pct)+'%   '+L[10] if phase=='install' else L[9]))
    fitted_text(detail,91,416,14,GREEN if done4 else DIM,468,14)

    # Rodape reservado exclusivamente a status/erros: letras claras sobre fundo.
    if done4:
        txt('✓',47,446,16,GREEN)
        fitted_text(L[14],74,447,15,GREEN,520,14)
    elif failed:
        message=(state.get('message') or L[6]).replace('\n',' ')
        fitted_text('! '+message,46,446,15,(255,185,163),545,14)
    else:
        message=(state.get('message') or L[7]).replace('\n',' ')
        fitted_text(message,47,447,14,DIM,540,14)
    sdl.SDL_RenderPresent(renderer)

try:
    draw();path_ready.write_text('OK')
    while True:
        event=ctypes.create_string_buffer(64)
        while sdl.SDL_PollEvent(event):
            event_id=int.from_bytes(event.raw[:4],sys.byteorder)
            if event_id==0x100:raise KeyboardInterrupt()
        try:
            val=path_state.read_text(encoding='utf-8').strip()
            if val!=laststate:
                p=val.split('|',2)
                if len(p)>=2:state={'phase':p[0],'pct':int(p[1]),'message':p[2] if len(p)>2 else ''}
                laststate=val
        except (OSError,ValueError):pass
        draw()
        time.sleep(.16)
except (KeyboardInterrupt, OSError): pass
finally:
    for tex in cache.values():
        if tex:sdl.SDL_DestroyTexture(tex)
    sdl.SDL_DestroyRenderer(renderer);sdl.SDL_DestroyWindow(window);sdl.SDL_Quit()

R36S_GUI_PY
  printf 'check|0|GitHub\n' > "$TMP/ui.state"
  python3 "$TMP/ui.py" "$TMP/ui.state" "$TMP/ui.ready" "$INSTALL_LANG" "$DEST" > "$TMP/ui.error" 2>&1 &
  GUI_PID=$!
  i=0
  while [ "$i" -lt 16 ]; do
    [ -s "$TMP/ui.ready" ] && { GUI=1; break; }
    kill -0 "$GUI_PID" 2>/dev/null || break
    sleep .25
    i=$((i+1))
  done
  if [ "$GUI" -eq 0 ]; then
    kill "$GUI_PID" 2>/dev/null || :
    wait "$GUI_PID" 2>/dev/null || :
    GUI_PID=''
  fi
fi
# Logs use a direct file descriptor. No background logger, FIFO or dangling pipes.
# GUI draws its own screen, while terminal mode mirrors essential status to tty.
ui_echo() {
  printf '%b\n' "$*"
  if [ "$GUI" -eq 0 ] && [ -n "$DISPLAY_TARGET" ]; then
    printf '%b\n' "$*" > "$DISPLAY_TARGET" 2>/dev/null || :
  fi
}
printf 'R36S ROMS STORE installer: %s\n' "$(date 2>/dev/null || echo now)"
printf 'Destination: %s | language: %s | graphic: %s\n' "$DEST" "$INSTALL_LANG" "$GUI"
printf 'LOG: %s\n' "$LOG"
TTY=0
if [ "$GUI" -eq 0 ] && { [ -t 1 ] || [ -n "$DISPLAY_TARGET" ]; } && [ "${TERM:-linux}" != dumb ]; then TTY=1; fi
if [ "$TTY" -eq 1 ]; then
  RESET='\033[0m'; BLUE='\033[38;2;82;171;255m'; CYAN='\033[38;2;126;222;255m'
  SILVER='\033[38;2;216;228;241m'; DIM='\033[38;2;138;165;190m'
  GREEN='\033[38;2;103;226;178m'; GOLD='\033[38;2;255;211;110m'
  BG='\033[48;2;13;22;37m'
else
  RESET=''; BLUE=''; CYAN=''; SILVER=''; DIM=''; GREEN=''; GOLD=''; BG=''
fi
ui_line() {
  printf '  '
  printf '%b' "$BLUE"
  printf '%s\n' '===================================================='
  printf '%b' "$RESET"
}
ui_bar() {
  pct="$1"; label="$2"
  ui_state download "$pct" "$TX_STEP2"
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  filled=$((pct * 32 / 100))
  n=0; bar=''
  while [ "$n" -lt 32 ]; do
    if [ "$n" -lt "$filled" ]; then bar="${bar}#"; else bar="${bar}."; fi
    n=$((n+1))
  done
  if [ "$TTY" -eq 1 ]; then
    printf '\r\033[2K  %b[%b%-32s%b] %b%3d%%%b  %s' "$DIM" "$CYAN" "$bar" "$DIM" "$SILVER" "$pct" "$RESET" "$label"
  else
    printf '  [%-32s] %3d%%  %s\n' "$bar" "$pct" "$label"
  fi
}
ui_finish_bar() { [ "$TTY" -eq 1 ] && printf '\n' || :; }
ui_step() {
  # Painel de etapa: legivel em tela pequena ou terminal de SSH.
  ui_finish_bar
  printf '\n  %b%s%b\n' "$CYAN" "$1" "$RESET"
  printf '  %b--------------------------------------------%b\n' "$DIM" "$RESET"
  ui_echo "$1"
}
ui_ok() { printf '  %b[OK]%b %s\n' "$GREEN" "$RESET" "$1"; ui_echo "[OK] $1"; }
ui_start() {
  if [ "$TTY" -eq 1 ]; then printf '\033[2J\033[H'; fi
  printf '\n'
  ui_line
  printf '  %bR36S ROMS STORE%b\n' "$SILVER" "$RESET"
  printf '  %bINSTALADOR  |  R36S / R36H  |  PORTMASTER%b\n' "$CYAN" "$RESET"
  ui_line
  printf '  %b%s%b\n' "$DIM" "$TX_EDITION" "$RESET"
  printf '  %b%s:%b %s\n' "$BLUE" "$TX_TARGET" "$RESET" "$DEST"
  printf '  %b%s:%b GitHub Releases\n' "$BLUE" "$TX_SOURCE" "$RESET"
  printf '  %b%s:%b %s\n' "$BLUE" "$TX_LANGUAGE" "$RESET" "$INSTALL_LANG"
  printf '\n'
  ui_echo "R36S ROM STORE - $TX_EDITION - $DEST ($INSTALL_LANG)"
}
# Apenas o nome do projeto: nenhum arquivo de imagem e requisitado/exibido.
ui_start
ui_state check 0 "$TX_STEP1"
fetch() {
  if command -v curl >/dev/null 2>&1; then curl -fLSs --connect-timeout 20 --retry 3 -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then wget -q --timeout=30 -O "$2" "$1"
  else case "$INSTALL_LANG" in es) echo 'Se necesita curl o wget.' >&2 ;; en) echo 'curl or wget is required.' >&2 ;; ru) echo 'Требуется curl или wget.' >&2 ;; *) echo 'Necessario curl ou wget.' >&2 ;; esac; return 1; fi
}
ui_step "$TX_STEP1"
# A nova estrutura tem prioridade. Somente HTTP 404 permite usar o canal legado.
# Uma falha de rede ou manifesto invalido nunca autoriza instalar uma versao anterior.
fetch_status() {
  if command -v curl >/dev/null 2>&1; then
    curl -sSL --connect-timeout 20 --max-time 90 --retry 2 -w '%{http_code}' -o "$2" "$1"
  else
    python3 - "$1" "$2" <<'PYHTTP'
import sys,urllib.request,urllib.error
try:
    with urllib.request.urlopen(sys.argv[1],timeout=30) as r:
        data=r.read(1024*1024+1)
        if len(data)>1024*1024:raise ValueError('Feed too large')
        open(sys.argv[2],'wb').write(data)
        print(r.status)
except urllib.error.HTTPError as e:
    print(e.code)
PYHTTP
  fi
}
STATUS="$(fetch_status "$FEED_ROOT/rom-store/update.json" "$TMP/update.json")" || fail "$TX_FEED_ERR"
case "$STATUS" in
  200) LAYOUT=new; APP_NAME=r36sromstore; LAUNCHER_NAME='R36S ROM STORE.sh' ;;
  404) LAYOUT=legacy; APP_NAME=r36sromsstore; LAUNCHER_NAME='R36S ROMS STORE.sh'
       fetch "$FEED_ROOT/update.json" "$TMP/update.json" || fail "$TX_FEED_ERR" ;;
  *) fail "$TX_FEED_ERR ($STATUS)" ;;
esac
APP="$DEST/$APP_NAME"
[ ! -L "$APP" ] && [ ! -L "$DEST/$LAUNCHER_NAME" ] || fail "$TX_SYMLINK"
VERSION="$(python3 - "$TMP/update.json" "$LAYOUT" <<'PYVER'
import json,re,sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
v=j.get('version','')
layout=sys.argv[2]
prefix='R36S_ROM_STORE' if layout=='new' else 'R36S_ROMS_STORE'
if not isinstance(v,str) or not re.fullmatch(r'\d+\.\d+\.\d+(?:-beta)?',v):
    raise ValueError('Invalid official version')
repos=['R36S-ROM-STORE-UPDATES']
if layout=='legacy':repos.append('R36S-ROMS-HUB-STORE-UPDATES')
urls={f'https://github.com/JammesPark/{r}/releases/download/store-v{v}/{prefix}_{v}_OTA.zip' for r in repos}
if j.get('url') not in urls or not re.fullmatch(r'[a-fA-F0-9]{64}',j.get('sha256','')) or type(j.get('size')) is not int or j['size']<=0:
    raise ValueError('Unexpected OTA feed')
print(v)
PYVER
)"
fetch "https://api.github.com/repos/JammesPark/R36S-ROM-STORE-UPDATES/releases/tags/store-v$VERSION" "$TMP/release.json" || fail "$TX_FEED_ERR"
python3 - "$TMP/release.json" "$TMP/info" "$VERSION" "$LAYOUT" <<'PYRELEASE'
import json,re,sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
v,layout=sys.argv[3:]
prefix='R36S_ROM_STORE' if layout=='new' else 'R36S_ROMS_STORE'
name=f'{prefix}_{v}.zip'
url=f'https://github.com/JammesPark/R36S-ROM-STORE-UPDATES/releases/download/store-v{v}/{name}'
if j.get('tag_name')!='store-v'+v or j.get('draft') is not False or j.get('prerelease') is not False:
    raise ValueError('Unexpected official release')
assets=[a for a in j.get('assets',[]) if a.get('name')==name]
if len(assets)!=1:
    raise ValueError('Official complete installer unavailable')
a=assets[0]
digest=a.get('digest') or ''
size=a.get('size')
if a.get('browser_download_url')!=url or not re.fullmatch(r'sha256:[a-fA-F0-9]{64}',digest) or type(size)!=int or not 0<size<128*1024*1024:
    raise ValueError('Invalid release asset or SHA-256')
with open(sys.argv[2],'w',encoding='utf-8') as f:
    f.write(url+'\n'+digest[7:].lower()+'\n'+str(size)+'\n')
PYRELEASE
URL="$(sed -n '1p' "$TMP/info")"
SHA="$(sed -n '2p' "$TMP/info")"
SIZE="$(sed -n '3p' "$TMP/info")"
ui_ok "$TX_VERSION: $VERSION"
ui_state download 0 "$TX_STEP2"
ui_step "$TX_STEP2"
# Download temporario; barra acompanha bytes recebidos / tamanho do manifesto.
# Falha de rede nunca instala um arquivo parcial.
(fetch "$URL" "$TMP/loja.zip") >"$TMP/download.log" 2>&1 &
PID=$!
LAST=-1
while kill -0 "$PID" 2>/dev/null; do
  if [ -f "$TMP/loja.zip" ]; then GOT="$(wc -c < "$TMP/loja.zip")"; else GOT=0; fi
  case "$GOT" in ''|*[!0-9]*) GOT=0 ;; esac
  if [ "$SIZE" -gt 0 ]; then
    PCT=$((GOT * 100 / SIZE)); [ "$PCT" -gt 99 ] && PCT=99
    [ "$PCT" -ne "$LAST" ] && ui_bar "$PCT" "$(($GOT / 1024)) KiB" && LAST="$PCT"
  elif [ "$GOT" != "$LAST" ]; then
    if [ "$TTY" -eq 1 ]; then printf '\r  %s: %s KiB' "$TX_RECEIVED" "$((GOT/1024))"; else printf '  %s: %s KiB\n' "$TX_RECEIVED" "$((GOT/1024))"; fi
    LAST="$GOT"
  fi
  sleep 1
done
if ! wait "$PID"; then
  ui_finish_bar
  echo "$TX_DL_ERR" >&2
  cat "$TMP/download.log" >&2
  exit 1
fi
ui_bar 100 "$TX_DL_END"
ui_finish_bar
ui_ok "$TX_DL_OK" 
ui_state verify 0 "$TX_STEP3"
ui_step "$TX_STEP3"
[ "$(wc -c < "$TMP/loja.zip")" -eq "$SIZE" ] || fail "$TX_SHA_ERR"
printf '%s  %s\n' "$SHA" "$TMP/loja.zip" | sha256sum -c - >/dev/null || { echo "$TX_SHA_ERR" >&2; exit 1; }
ui_ok "$TX_SHA_OK"
ui_state verify 100 "$TX_SHA_OK"
ui_state install 0 "$TX_STEP4"
ui_step "$TX_STEP4"
python3 - "$TMP/loja.zip" "$TMP" "$DEST" "$VERSION" "$INSTALL_LANG" "$TMP/ui.state" "$GUI" "$APP_NAME" "$LAUNCHER_NAME" <<'PY'
import hashlib,json,os,pathlib,shutil,sys,zipfile,io,re
zip_path,tmp,dest,version,lang,progress_file,graphic,app_name,launcher_name=sys.argv[1:]
store_name='R36S ROM STORE' if app_name=='r36sromstore' else 'R36S ROMS STORE'
def tr(pt,es,en=None,ru=None):
    return {'pt':pt,'es':es,'en':en or pt,'ru':ru or en or pt}.get(lang,en or pt)
base=pathlib.Path(dest)
stage=pathlib.Path(tmp)/'stage';stage.mkdir()
backup=pathlib.Path(tmp)/'backup';backup.mkdir()
manifest_path='update_manifest.json'
def progress(part, done, total):
    percent=int(done*100/max(1,total))
    fill=percent*28//100
    bar='#'*fill+'-'*(28-fill)
    msg=f'  [{bar}] {percent:3d}%  {part}'
    if graphic=='1':
        step=int((done*40/max(1,total)) if part in ('Validando','Verificando','Validating','Проверка') else (40+done*60/max(1,total)))
        try:
            with open(progress_file+'.next','w',encoding='utf-8') as f:f.write('install|'+str(step)+'|'+part+'\n')
            os.replace(progress_file+'.next',progress_file)
        except OSError:pass
    if sys.stdout.isatty():
        print('\r\033[2K'+msg,end='\n' if done==total else '',flush=True)
    elif done==total or done==1 or done%max(1,total//5)==0:
        print(msg,flush=True)
allowed_docs={'README.md','LICENSE','NOTICE.md','CHANGELOG.md'}
# O ZIP completo de 0.7.0-beta contém esta cópia legada fora do manifesto.
# O hash do ZIP inteiro já foi conferido. Nunca extrair nem substituir este arquivo.
ignored_legacy={app_name+'/catalog.json'}
protected={'catalogo_proprio.zlib','catalogo_proprio.json','favorites.json','downloads.json','settings.txt','theme.txt','user_themes','saves','conf' ,'tmp','logs','gravacoes','update','backups','bios','bios_url.txt','catalog.json','catalog_url.txt','update_url.txt','stats_url.txt','log.txt','themes_url.txt','es_themes_url.txt','runtimes_url.txt','senhas.txt','catalogo_proprio_ultimo_valido.zlib','configuracoes','.legacy_migrated','.legacy_migrated_v2'}
def valid(p):
    if not isinstance(p,str) or '\\' in p or p.startswith('/') or '\x00' in p:return False
    parts=p.split('/')
    if any(x in ('','.','..') for x in parts):return False
    if p==launcher_name:return True
    return len(parts)>=2 and parts[0]==app_name and parts[1] not in protected and not parts[1].startswith('libs.')
def check_parents(rel):
    target=base/rel
    if target.is_symlink():raise ValueError(tr('link simbolico em destino: ','enlace simbólico en destino: ','unsafe link at destination: ','Символическая ссылка: ')+rel)
    for parent in target.parents:
        if parent==base:break
        if parent.is_symlink():raise ValueError(tr('pasta simbolica: ','carpeta simbólica: ','symbolic link in folder: ','Ссылка в папке: ')+str(parent))
with zipfile.ZipFile(zip_path) as z:
    info=z.infolist(); names=[x.filename for x in info if not x.is_dir()]
    if len(names)!=len(set(names)) or manifest_path not in names:raise ValueError(tr('ZIP sem manifesto ou com entradas duplicadas','ZIP sin manifiesto o con archivos duplicados','ZIP missing manifest or duplicate entries','ZIP без манифеста или с дубликатами'))
    for x in info:
        if x.is_dir():continue
        if x.filename!=manifest_path and x.filename not in allowed_docs and x.filename not in ignored_legacy and not valid(x.filename):raise ValueError(tr('arquivo inesperado: ','archivo inesperado: ','unexpected file: ','Неожиданный файл: ')+x.filename)
        if (x.external_attr>>16)&0o170000==0o120000:raise ValueError(tr('link simbolico no ZIP','enlace simbólico dentro del ZIP','symlink inside ZIP','Ссылка внутри ZIP'))
    m=json.loads(z.read(manifest_path))
    if m.get('name')!=store_name or m.get('type')!='full' or m.get('version')!=version:
        raise ValueError(tr('manifesto de identidade/versao inesperada','manifiesto de identidad o versión incorrecta','wrong package identity/version','Неверная версия пакета'))
    entries=m.get('files',[])
    paths=[e.get('path') for e in entries]
    # O ZIP oficial inclui documentos na raiz (README, LICENSE, NOTICE e CHANGELOG).
    # Sao extras legitimos assinados pelo SHA-256 do ZIP, fora do manifesto instalavel.
    expected=set(paths)|{manifest_path}
    if len(paths)!=len(set(paths)) or not expected.issubset(names) or set(names)-expected-allowed_docs-ignored_legacy:
        raise ValueError(tr('lista de arquivos divergente do manifesto','archivos distintos de los indicados en el manifiesto','package files do not match the manifest','Файлы не соответствуют списку'))
    if not {launcher_name,app_name+'/game.love'}<=set(paths):raise ValueError(tr('jogo ou launcher ausente','faltan archivos esenciales de la tienda','missing store or launcher files','Отсутствуют файлы магазина'))
    with zipfile.ZipFile(io.BytesIO(z.read(app_name+'/game.love'))) as game:
        cfg=game.read('config.lua').decode()
        if not re.search(r'^C\.VERSION_NUM\s*=\s*"'+re.escape(version)+r'"',cfg,re.M):
            raise ValueError('Embedded version mismatch')
        if re.search(r'^C\.EXPERIMENTAL_NO_OTA\s*=\s*true\b',cfg,re.M):
            raise ValueError('Experimental package rejected')
        if app_name=='r36sromstore' and (not re.search(r'^C\.EXPERIMENTAL_NO_OTA\s*=\s*false\b',cfg,re.M) or '/main/ota/rom-store/update.json' not in cfg):
            raise ValueError('Official OTA disabled or incorrect')
    for i,e in enumerate(entries,1):
        p=e['path'];check_parents(p)
        if not valid(p):raise ValueError(tr('arquivo fora da loja: ','archivo fuera de la tienda: ','file outside store: ','Файл вне папки: ')+p)
        data=z.read(p)
        if len(data)!=e['size'] or hashlib.sha256(data).hexdigest()!=e['sha256']:raise ValueError(tr('arquivo corrompido: ','archivo dañado: ','corrupted file: ','Повреждённый файл: ')+p)
        out=stage/p;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
        progress(tr('Validando','Verificando','Validating','Проверка'), i, len(entries))
# Prepara rollback por arquivo; nunca remove arquivos nao incluidos no pacote.
installed=[]
try:
    for i,p in enumerate(paths,1):
        target=base/p;src=stage/p
        if target.exists():
            save=backup/p;save.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,save)
        target.parent.mkdir(parents=True,exist_ok=True)
        os.replace(src,target)
        installed.append(p)
        if p.endswith('.sh') or p.startswith(app_name+'/bin/'):
            target.chmod(target.stat().st_mode|0o111)
        progress(tr('Instalando','Instalando','Installing','Установка'),i,len(paths))
except Exception:
    for p in reversed(installed):
        target=base/p;save=backup/p
        if save.exists():os.replace(save,target)
        elif target.exists():target.unlink()
    raise
print('\n  [OK] '+tr('INSTALACAO CONCLUIDA: ','INSTALACIÓN COMPLETADA: ','INSTALLATION COMPLETE: ','УСТАНОВКА ЗАВЕРШЕНА: ')+version)
print(tr('Launcher: ','Acceso: ','Launcher: ','Запуск: ')+str(base/launcher_name))
print(tr('Dados pessoais, catalogos locais, saves e configuracoes existentes foram preservados.', 'Se conservaron los datos personales, catálogos locales, partidas guardadas y ajustes.', 'Existing settings, local catalogs and saves were preserved.', 'Настройки, каталоги и сохранения не изменены.'))
PY
ui_line
printf '  %b%s%b\n' "$GREEN" "$TX_DONE" "$RESET"
printf '  %s\n' "$TX_OPEN"
printf '  %s\n' "$TX_LOVE"
printf '  LOG: %s\n' "$LOG"

# Em execucao pela tela do console, deixa o resultado visivel antes de sair.
# A tela de resultado e mantida visivel pelo tratamento central de saida.

# Only mark success after validation AND the Python installer finished normally.
INSTALL_SUCCESS=1
