#!/usr/bin/env bash
set -Eeuo pipefail
BASE="$(cd "$(dirname "$0")" && pwd -P)"
APP="$BASE/r36s-store-kpm"
export R36S_STORE_HOME="$APP"
mkdir -p "$APP/state/installations" "$APP/state/logs"
cd "$APP"
if command -v love >/dev/null 2>&1; then LOVE_BIN="$(command -v love)"
elif [[ -x /usr/bin/love ]]; then LOVE_BIN=/usr/bin/love
else
  echo "ERRO: LÖVE 11.x nao encontrado. Instale um runtime compatível para R36S."
  exit 1
fi
while true; do
  rm -f "$APP/state/launch.request"
  "$LOVE_BIN" "$APP/game.love" || exit $?
  [[ -f "$APP/state/launch.request" ]] || exit 0
  read -r SCRIPT < "$APP/state/launch.request"
  [[ "$SCRIPT" == /roms/ports/*.sh || "$SCRIPT" == /roms2/ports/*.sh ]] || exit 1
  [[ -f "$SCRIPT" && ! -L "$SCRIPT" ]] || exit 1
  bash "$SCRIPT" || :
done
