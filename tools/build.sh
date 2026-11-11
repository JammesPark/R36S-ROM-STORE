#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
rm -f build/*.zip
(cd src && zip -q -X -r ../port/r36s-store-kpm/game.love .)
(cd port && zip -q -r ../build/R36S_PORTS_BR_STORE_KPM_INSTALAR.zip \
  "R36S PORTS BR STORE KPM.sh" r36s-store-kpm \
  -x 'r36s-store-kpm/state/*')
zip -q -r build/R36S_PORTS_BR_STORE_KPM_FONTE.zip \
  README.md src port tools tests .github \
  -x 'port/r36s-store-kpm/state/*'
echo 'Pacotes criados em build/'
