#!/usr/bin/env python3
"""Isolamento do feed público do R36S ROMS STORE."""
import importlib.util
from pathlib import Path

root=Path(__file__).resolve().parents[1]
p=root/'port/r36s-roms-store/bin/store_updater.py'
spec=importlib.util.spec_from_file_location('store_updater',p)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
repo='JammesPark/R36S-ROMS-STORE-UPDATES'
old='JammesPark/R36SPORTSBR-STORE-UPDATES'
assert module.PUBLIC_REPO==repo
assert module.FEED_URL=='https://raw.githubusercontent.com/'+repo+'/main/update.json'
assert module.expected_url('0.3.1-beta').startswith('https://github.com/'+repo+'/releases/download/')
for file in [p,root/'tools/make_roms_feed.py',root/'.github/workflows/publish-roms-updates.yml',root/'docs/ATUALIZACAO_ROM_STORE.md']:
    content=file.read_text(encoding='utf-8')
    assert old not in content, 'Canal do outro projeto em '+str(file)
assert 'PUBLIC_REPO: '+repo in (root/'.github/workflows/publish-roms-updates.yml').read_text()
assert (root/'VERSION').read_text().strip()=='0.3.1-beta'
print('UPDATE ISOLADO: repositório público e feed próprios; sem referências ao outro HUB: OK')
