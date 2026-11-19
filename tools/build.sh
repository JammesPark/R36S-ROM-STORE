#!/bin/sh
# Adaptado de tools/build.sh do R36S PORT HUB, por Lag do Lira (GPL-3.0).
# Reconstroi a versao da R36S ROMS STORE somente na pasta build/.
# Uso: sh tools/build.sh [--dev]  (--dev inclui game/dev/)
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
test -f "$ROOT/game/main.lua"
test -f "$ROOT/game/config.lua"
test -f "$ROOT/R36S ROMS STORE.sh"
test -d "$ROOT/r36sromsstore"
mkdir -p "$OUT"
rm -rf "$OUT/ports"
mkdir -p "$OUT/ports/r36sromsstore"
cp -a "$ROOT/r36sromsstore/." "$OUT/ports/r36sromsstore/"
cp "$ROOT/R36S ROMS STORE.sh" "$OUT/ports/"
cp "$ROOT/README.md" "$ROOT/NOTICE.md" "$ROOT/LICENSE" "$OUT/ports/"
rm -f "$OUT/ports/r36sromsstore/game.love"
if [ "${1:-}" = "--dev" ]; then
  ( cd "$ROOT/game" && zip -q -9 -n .ogg -r "$OUT/ports/r36sromsstore/game.love" . )
else
  ( cd "$ROOT/game" && zip -q -9 -n .ogg -r "$OUT/ports/r36sromsstore/game.love" . -x 'dev/*' )
fi
chmod +x "$OUT/ports/R36S ROMS STORE.sh" "$OUT/ports/r36sromsstore/bin/7zzs"
for file in "$OUT/ports/r36sromsstore/bin/"*.sh "$OUT/ports/r36sromsstore/tools/"*.sh; do
  [ -f "$file" ] && chmod +x "$file"
done
python3 "$ROOT/tools/version.py" check
VERSION=$(python3 "$ROOT/tools/version.py" get)
python3 "$ROOT/tools/make_update.py" full "$OUT/ports"
PACKAGE="$OUT/R36S_ROMS_STORE_$VERSION.zip"
rm -f "$PACKAGE"
( cd "$OUT/ports" && zip -q -9 -r "$PACKAGE" "R36S ROMS STORE.sh" r36sromsstore README.md NOTICE.md LICENSE update_manifest.json )
unzip -tq "$PACKAGE"
echo "Pacote: $PACKAGE"
