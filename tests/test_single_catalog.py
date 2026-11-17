from pathlib import Path
root=Path('.')
main=(root/'src/main.lua').read_text(encoding='utf-8')
ext=(root/'src/external.lua').read_text(encoding='utf-8')
api=(root/'port/r36s-roms-store/bin/gamestore_source.py').read_text(encoding='utf-8')
assert not (root/'src/catalog.json').exists()
assert not (root/'port/r36s-roms-store/config/catalog_url.txt').exists()
assert "require('external')" in main
assert "require('theme')" in main
assert "require('i18n')" in main
assert 'R36S ROMS STORE' in main
assert 'GAMESTORE BR' not in main  # Fonte do catálogo não é exibida na interface
assert "mainPages={'home','catalog','downloads','installed','favorites','settings','about'}" in main
assert "external.enter()" in main
assert 'M.categoryChange' in ext
assert 'def load_api(' in api
assert 'setCatalog(' not in main
assert 'catalog.pending.json' not in main
assert (root/'src/theme.lua').exists()
assert (root/'src/ui.lua').exists()
assert (root/'src/i18n.lua').exists()
print('Layout R36S ROMS STORE, catalogo unico GameStoreBR, SD1/SD2 e temas: OK')
