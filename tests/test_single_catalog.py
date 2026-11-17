from pathlib import Path
root=Path('.')
main=(root/'src/main.lua').read_text(encoding='utf-8')
ext=(root/'src/external.lua').read_text(encoding='utf-8')
api=(root/'port/r36s-store-kpm/bin/gamestore_source.py').read_text(encoding='utf-8')
assert not (root/'src/catalog.json').exists()
assert not (root/'port/r36s-store-kpm/config/catalog_url.txt').exists()
assert "require('external')" in main
assert "require('theme')" in main
assert "require('i18n')" in main
assert 'GAMESTORE BR' in main
assert "mainPages={'home','catalog','downloads','installed','favorites','settings','about'}" in main
assert "external.enter()" in main
assert 'M.categoryChange' in ext
assert 'def load_api(' in api
assert 'CATALOGO KPM' not in main
assert 'setCatalog(' not in main
assert 'catalog.pending.json' not in main
assert 'X: KPM' not in ext
assert (root/'src/theme.lua').exists()
assert (root/'src/ui.lua').exists()
assert (root/'src/i18n.lua').exists()
print('Layout R36S ROMS STORE, catalogo unico GameStoreBR, SD1/SD2 e temas: OK')
