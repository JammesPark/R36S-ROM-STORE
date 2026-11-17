#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
rm -f build/*.zip port/r36s-roms-store/game.love
find port -type d -name __pycache__ -prune -exec rm -rf -- {} +
(cd src && zip -q -X -r ../port/r36s-roms-store/game.love .)
(cd port && zip -q -r ../build/R36S_ROMS_STORE_v0.2.7_TESTE.zip \
  "R36S ROMS STORE.sh" r36s-roms-store \
  -x 'r36s-roms-store/state/*')
zip -q -r build/R36S_ROMS_STORE_v0.2.7_FONTE.zip \
  README.md LICENSE THIRD_PARTY_NOTICES.txt src port tools tests .github \
  -x 'port/r36s-roms-store/state/*'
echo 'Pacotes criados em build/'
