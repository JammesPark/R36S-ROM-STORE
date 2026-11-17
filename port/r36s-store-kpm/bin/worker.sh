#!/usr/bin/env bash
# Instalador independente. Nao executa scripts obtidos da internet.
set -Eeuo pipefail
umask 077
APP="${R36S_STORE_HOME:-/roms/ports/r36s-store-kpm}"
STATE="$APP/state"
mkdir -p "$STATE/installations" "$STATE/logs"
STATUS="$STATE/job.status"
LOCK="$STATE/worker.lock"
HAVE_LOCK=0
TMP=''
ROOT=''
MOVED=()
COMMITTED=0
PHASE='idle'
log() { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" >> "$STATE/logs/worker.log"; }
write_status() {
  PHASE="$1"
  local msg="${2//$'\n'/ }"
  printf 'phase=%s\nmessage=%s\n' "$PHASE" "$msg" > "$STATUS.tmp.$$"
  mv -f "$STATUS.tmp.$$" "$STATUS"
}
rollback() {
  if (( COMMITTED == 0 )) && [[ -n "$ROOT" && -n "$TMP" ]]; then
    for entry in "${MOVED[@]}"; do
      [[ ! -e "$ROOT/$entry" ]] || mv -- "$ROOT/$entry" "$TMP/unpacked/$entry" 2>/dev/null || :
    done
  fi
}
finish() {
  local code=$?
  if (( code != 0 )); then
    rollback
    if [[ "$PHASE" != 'error' ]]; then
      write_status error "Falha na etapa $PHASE. Consulte state/logs/worker.log"
    fi
  fi
  [[ -z "$TMP" ]] || rm -rf -- "$TMP"
  if (( HAVE_LOCK == 1 ));then rmdir "$LOCK" 2>/dev/null || :;fi
  exit "$code"
}
trap finish EXIT
trap 'log "ERRO na linha $LINENO"' ERR
fail() { log "$*"; write_status error "$*"; exit 1; }
valid_id() { [[ "$1" =~ ^[a-z0-9][a-z0-9_-]{0,63}$ ]]; }
valid_name() {
  [[ -n "$1" && "$1" != '.' && "$1" != '..' && "$1" != *'/'* && "$1" != *'\\'* && "$1" != *':'* && "$1" != *$'\n'* && "$1" != *$'\r'* ]] || return 1
  case "${1,,}" in "portmaster"|"r36s-store-kpm"|"gamelist.xml"|"r36s ports br store kpm.sh"|"r36s roms store.sh") return 1;; esac
}
valid_root() {
  [[ "$1" == /roms/ports || "$1" == /roms2/ports ]] || fail 'Destino invalido'
  [[ -d "$1" && -w "$1" && ! -L "$1" ]] || fail 'Cartao ausente, inacessivel ou link simbolico'
  if [[ "$1" == /roms2/ports ]]; then
    command -v findmnt >/dev/null || fail 'findmnt necessario para validar SD2'
    local a b
    a="$(findmnt -T /roms -no SOURCE 2>/dev/null || :)"
    b="$(findmnt -T /roms2 -no SOURCE 2>/dev/null || :)"
    [[ -n "$b" && "$a" != "$b" ]] || fail 'SD2 nao esta montado separadamente'
  fi
}
begin() {
  mkdir "$LOCK" 2>/dev/null || fail 'Ja existe operacao em andamento'
  HAVE_LOCK=1
}
fetch_url() {
  local url="$1" output="$2"
  [[ "$url" =~ ^https://[^[:space:]\;\|]+$ ]] || fail 'O link deve usar HTTPS'
  if command -v curl >/dev/null; then
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 0 --silent --show-error --output "$output" "$url" >> "$STATE/logs/worker.log" 2>&1 || fail 'Download falhou'
  elif command -v wget >/dev/null; then
    wget -q -T 45 -O "$output" "$url" >> "$STATE/logs/worker.log" 2>&1 || fail 'Download falhou'
  else
    fail 'Instale curl ou wget'
  fi
  [[ -s "$output" ]] || fail 'Download vazio'
}
install() {
  local id="${1:-}" root="${2:-}" url="${3:-}" hash="${4:-}" size="${5:-0}" name="${6:-}"
  valid_id "$id" || fail 'ID do port invalido'
  valid_root "$root"
  [[ "$hash" =~ ^[a-fA-F0-9]{64}$ ]] || fail 'SHA-256 obrigatorio: informe hash valido no catalogo'
  [[ "$size" =~ ^[0-9]+$ ]] || fail 'Tamanho invalido'
  [[ "$name" != *$'\n'* && "$name" != *$'\r'* ]] || fail 'Nome invalido'
  local card=sd1
  [[ "$root" == /roms2/ports ]] && card=sd2
  local manifest="$STATE/installations/$id.$card.json"
  [[ ! -e "$manifest" ]] || fail 'Port ja instalado neste cartao'
  begin
  ROOT="$root"
  if (( size > 0 )); then
    local kb
    kb="$(df -Pk "$root" | awk 'END {print $4}')"
    (( kb * 1024 > size * 2 + 67108864 )) || fail 'Espaco insuficiente no cartao'
  fi
  TMP="$(mktemp -d "$root/.kpm_${id}.XXXXXX")"
  mkdir "$TMP/unpacked"
  local archive="$TMP/download"
  write_status downloading "Baixando $name no $card"
  printf 'file=%s\nexpected=%s\n' "$archive" "$size" >> "$STATUS"
  fetch_url "$url" "$archive"
  write_status verifying "Verificando SHA-256 de $name"
  local actual
  actual="$(sha256sum "$archive" | awk '{print $1}')"
  [[ "${actual,,}" == "${hash,,}" ]] || fail 'Checksum SHA-256 nao confere'
  write_status extracting "Validando e extraindo o pacote"
  python3 "$APP/bin/archive_safe.py" "$archive" "$TMP/unpacked" >> "$STATE/logs/worker.log" 2>&1 || fail 'Pacote invalido ou extracao falhou'
  local stage="$TMP/unpacked"
  local -a top=()
  local entry base
  while IFS= read -r -d '' entry; do
    base="$(basename "$entry")"
    case "$base" in __MACOSX|.DS_Store|Thumbs.db) continue ;; esac
    top+=("$entry")
  done < <(find "$stage" -mindepth 1 -maxdepth 1 -print0)
  if ! find "$stage" -mindepth 1 -maxdepth 1 -type f -iname '*.sh' | grep -q .; then
    if (( ${#top[@]} == 1 )) && [[ -d "${top[0]}" && ! -L "${top[0]}" ]]; then
      stage="${top[0]}"
    fi
  fi
  find "$stage" -mindepth 1 -maxdepth 1 -type f -iname '*.sh' | grep -q . || fail 'Launcher .sh nao encontrado'
  local -a items=()
  local script=''
  while IFS= read -r -d '' entry; do
    base="$(basename "$entry")"
    valid_name "$base" || fail "Arquivo reservado ou inseguro: $base"
    [[ ! -e "$root/$base" && ! -L "$root/$base" ]] || fail "Conflito com arquivo existente: $base"
    items+=("$base")
    if [[ -z "$script" && "${base,,}" == *.sh ]]; then script="$base"; fi
  done < <(find "$stage" -mindepth 1 -maxdepth 1 -print0)
  [[ -n "$script" && "${#items[@]}" -gt 0 ]] || fail 'Pacote sem launcher'
  write_status installing "Instalando $name no $card"
  for base in "${items[@]}"; do
    mv -- "$stage/$base" "$root/$base" || fail 'Falha ao mover arquivos; instalacao revertida'
    MOVED+=("$base")
  done
  # Manifesto JSON escrito com serializacao correta pelo Python.
  python3 - "$manifest.new" "$id" "$root" "$script" "$name" "${items[@]}" <<'PY'
import json,sys
out,id,root,script,name,*items=sys.argv[1:]
with open(out,"w",encoding="utf-8") as f:
    json.dump(dict(id=id,root=root,script=script,name=name,items=items),f,ensure_ascii=False)
PY
  mv -f "$manifest.new" "$manifest"
  COMMITTED=1
  write_status done "Instalado: $name ($card)"
  log "Instalado: id=$id, card=$card, itens=${#items[@]}"
}
uninstall() {
  local id="${1:-}" root="${2:-}"
  valid_id "$id" || fail 'ID invalido'
  valid_root "$root"
  local card=sd1
  [[ "$root" == /roms2/ports ]] && card=sd2
  local manifest="$STATE/installations/$id.$card.json"
  [[ -f "$manifest" && ! -L "$manifest" ]] || fail 'Instalacao nao gerenciada pela loja'
  begin
  local list="$STATE/remove.$$"
  # Valida integralmente o manifesto antes de excluir qualquer arquivo.
  python3 - "$manifest" "$id" "$root" > "$list" <<'PY'
import json,sys
manifest,id,root=sys.argv[1:]
with open(manifest,encoding="utf-8") as f: obj=json.load(f)
assert obj["id"] == id and obj["root"] == root
assert isinstance(obj["items"],list) and obj["items"]
seen=set()
for item in obj["items"]:
    assert isinstance(item,str) and item not in ("",".","..") and "/" not in item and "\\" not in item and "\n" not in item and "\r" not in item and ":" not in item
    assert item.lower() not in ("portmaster","r36s-store-kpm","gamelist.xml","r36s ports br store kpm.sh","r36s roms store.sh")
    assert item not in seen
    seen.add(item)
    print(item)
PY
  local ok=$?
  (( ok == 0 )) || fail 'Manifesto invalido'
  write_status uninstalling "Desinstalando $id de $card"
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    rm -rf -- "$root/$entry" || fail "Falha ao remover $entry"
  done < "$list"
  rm -f -- "$list" "$manifest"
  write_status done "Removido: $id ($card)"
}
case "${1:-}" in
  install) shift; install "$@" ;;
  uninstall) shift; uninstall "$@" ;;
  *) fail 'Acao desconhecida' ;;
esac