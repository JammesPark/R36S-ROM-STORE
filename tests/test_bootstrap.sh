#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/ports/r36s-store-kpm" "$TMP/pm/runtimes/love_11.5" "$TMP/bin"
cp "port/R36S PORTS BR STORE KPM.sh" "$TMP/ports/"
printf 'LOVE TEST\n' > "$TMP/ports/r36s-store-kpm/game.love"
cat > "$TMP/pm/control.txt" <<'PM'
get_controls() { sdl_controllerconfig="MOCK_CONTROLLER"; }
pm_platform_helper() { echo "Mock platform helper"; }
pm_finish() { echo "Mock portmaster finish"; }
PM
cat > "$TMP/pm/runtimes/love_11.5/love.txt" <<'LOVE'
LOVE_RUN="$MOCK_LOVE_BIN"
LOVE_BINARY="$MOCK_LOVE_BIN"
LOVE
cat > "$TMP/bin/love_mock" <<'MOCK'
#!/usr/bin/env bash
echo "MOCK_LOVE: $1"
[[ "$1" == "$EXPECTED_GAME" ]] || exit 27
exit "${MOCK_LOVE_EXIT:-0}"
MOCK
chmod +x "$TMP/bin/love_mock" "$TMP/ports/R36S PORTS BR STORE KPM.sh"
export R36S_PORTMASTER_DIR="$TMP/pm"
export MOCK_LOVE_BIN="$TMP/bin/love_mock"
export EXPECTED_GAME="$TMP/ports/r36s-store-kpm/game.love"
bash "$TMP/ports/R36S PORTS BR STORE KPM.sh"
sleep 0.2
LOG="$TMP/ports/r36s-store-kpm/log.txt"
test -s "$LOG"
grep -Fq 'Runtime selecionado: portmaster' "$LOG"
grep -Fq "MOCK_LOVE: $EXPECTED_GAME" "$LOG"
grep -Fq 'Loja encerrada normalmente.' "$LOG"
export MOCK_LOVE_EXIT=19
if bash "$TMP/ports/R36S PORTS BR STORE KPM.sh"; then
  echo 'ERRO: falha do LÖVE ignorada' >&2
  exit 1
fi
sleep 0.2
grep -Fq 'FALHA DE INICIALIZACAO:' "$LOG"
grep -Fq 'codigo 19' "$LOG"
echo 'BOOTSTRAP: runtime PortMaster, logs e falhas de inicializacao OK'
