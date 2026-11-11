#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/app/bin" "$TMP/sd1" "$TMP/sd2" "$TMP/pkg/assets" "$TMP/fakebin"
cp port/r36s-store-kpm/bin/archive_safe.py "$TMP/app/bin/"
echo '#!/bin/bash' > "$TMP/pkg/Example.sh"
echo content > "$TMP/pkg/assets/data"
(cd "$TMP/pkg" && zip -q -r "$TMP/port.zip" .)
cat > "$TMP/fakebin/curl" <<'SH'
#!/usr/bin/env bash
out=""
while (($#)); do
  if [[ "$1" == "--output" ]]; then out="$2";shift 2
  else shift;fi
done
[[ -n "$out" ]] || exit 1
cp "$TEST_SOURCE" "$out"
SH
cat > "$TMP/fakebin/findmnt" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == *'/roms2'* || "$*" == *'/sd2'* ]]; then echo '/dev/mmcblk1p1';else echo '/dev/mmcblk0p2';fi
SH
chmod +x "$TMP/fakebin/"*
python3 - "$TMP/worker.sh" "$TMP/sd1" "$TMP/sd2" <<'PY'
from pathlib import Path
import sys
code=Path("port/r36s-store-kpm/bin/worker.sh").read_text()
code=code.replace("/roms2/ports",sys.argv[3]).replace("/roms/ports",sys.argv[2])
Path(sys.argv[1]).write_text(code)
PY
export R36S_STORE_HOME="$TMP/app" PATH="$TMP/fakebin:$PATH" TEST_SOURCE="$TMP/port.zip"
HASH="$(sha256sum "$TMP/port.zip" | awk '{print $1}')"
bash "$TMP/worker.sh" install example "$TMP/sd1" 'https://example.test/port.zip' "$HASH" 0 Example
[[ -e "$TMP/sd1/Example.sh" && -e "$TMP/sd1/assets/data" ]]
[[ -f "$TMP/app/state/installations/example.sd1.json" ]]
bash "$TMP/worker.sh" uninstall example "$TMP/sd1"
[[ ! -e "$TMP/sd1/Example.sh" && ! -e "$TMP/sd1/assets" ]]
bash "$TMP/worker.sh" install example "$TMP/sd2" 'https://example.test/port.zip' "$HASH" 0 Example
[[ -e "$TMP/sd2/Example.sh" ]]
bash "$TMP/worker.sh" uninstall example "$TMP/sd2"
if bash "$TMP/worker.sh" install wronghash "$TMP/sd1" 'https://example.test/port.zip' "$(printf '0%.0s' {1..64})" 0 Test; then
  echo 'ERRO: checksum invalido permitido';exit 1
fi
[[ ! -e "$TMP/sd1/Example.sh" ]]
python3 - "$TMP/evil.zip" <<'PY'
import sys,zipfile
with zipfile.ZipFile(sys.argv[1],"w") as z:z.writestr("../escape.sh","x")
PY
export TEST_SOURCE="$TMP/evil.zip"
EVIL_HASH="$(sha256sum "$TMP/evil.zip" | awk '{print $1}')"
if bash "$TMP/worker.sh" install traversal "$TMP/sd1" 'https://example.test/evil.zip' "$EVIL_HASH" 0 Evil; then
  echo 'ERRO: traversal permitido';exit 1
fi
[[ ! -e "$TMP/escape.sh" ]]
echo 'BACKEND: SD1/SD2, desinstalacao, hash e traversal OK'
