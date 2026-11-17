#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
for lang in 1 2 3 4; do
  export R36S_STORE_HOME="$TMP/app-$lang"
  mkdir -p "$R36S_STORE_HOME/state"
  TEST_LANGUAGE_INDEX="$lang" TEST_FIRST_RUN=1 R36S_STORE_OFFLINE_TEST=1 lua5.4 tests/test_v027.lua
  TEST_LANGUAGE_INDEX="$lang" TEST_FIRST_RUN=0 R36S_STORE_OFFLINE_TEST=1 lua5.4 tests/test_v027.lua
done
printf 'ONBOARDING: 4 idiomas, persistencia e aviso em toda abertura OK\n'
