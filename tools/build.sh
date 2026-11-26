#!/bin/sh
# Adaptado de tools/build.sh do R36S PORT HUB, por Lag do Lira (GPL-3.0).
# Reconstroi a versao da R36S ROM STORE somente na pasta build/.
# Uso: sh tools/build.sh [--dev]  (--dev inclui src/dev/)
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/build"
case "${1:-}" in
  ""|--dev) ;;
  *) echo "Uso: sh tools/build.sh [--dev]" >&2; exit 2 ;;
esac
for cmd in zip python3 cp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Dependencia ausente: $cmd" >&2; exit 1; }
done
test -f "$ROOT/src/main.lua"
test -f "$ROOT/src/config.lua"
test -f "$ROOT/port/R36S ROM STORE.sh"
test -d "$ROOT/port/r36sromstore"
mkdir -p "$OUT"
rm -rf "$OUT/ports"
mkdir -p "$OUT/ports/r36sromstore"
cp -a "$ROOT/port/r36sromstore/." "$OUT/ports/r36sromstore/"
LOGO="$ROOT/port/r36sromstore/logo_hd.png"
[ -f "$LOGO" ] || LOGO="$ROOT/src/assets/logo/logo_splash.png"
"${ART_PYTHON:-python3}" "$ROOT/tools/render_romstore_art.py" --logo "$LOGO" --out "$OUT/ports/r36sromstore"
rm -f "$OUT/ports/r36sromstore/logo_hd.png"
cp "$ROOT/port/R36S ROM STORE.sh" "$OUT/ports/"
cp "$ROOT/README.md" "$ROOT/NOTICE.md" "$ROOT/LICENSE" "$OUT/ports/"
rm -f "$OUT/ports/r36sromstore/game.love"
if [ "${1:-}" = "--dev" ]; then
  ( cd "$ROOT/src" && zip -q -9 -n .ogg -r "$OUT/ports/r36sromstore/game.love" . )
else
  ( cd "$ROOT/src" && zip -q -9 -n .ogg -r "$OUT/ports/r36sromstore/game.love" . -x 'dev/*' )
fi
chmod +x "$OUT/ports/R36S ROM STORE.sh" "$OUT/ports/r36sromstore/bin/7zzs"
for file in "$OUT/ports/r36sromstore/bin/"*.sh "$OUT/ports/r36sromstore/tools/"*.sh; do
  [ -f "$file" ] && chmod +x "$file"
done
python3 "$ROOT/tools/version.py" check
VERSION=$(python3 "$ROOT/tools/version.py" get)
python3 "$ROOT/tools/make_update.py" full "$OUT/ports"
PACKAGE="$OUT/R36S_ROM_STORE_$VERSION.zip"
rm -f "$PACKAGE"
( cd "$OUT/ports" && zip -q -9 -r "$PACKAGE" "R36S ROM STORE.sh" r36sromstore README.md NOTICE.md LICENSE update_manifest.json )
unzip -tq "$PACKAGE"
echo "Pacote: $PACKAGE"
