from pathlib import Path
root = Path(__file__).resolve().parent.parent
allowed_extensions = {'.lua','.py','.sh','.md','.yml','.txt'}
source_files = [p for p in root.rglob('*') if p.is_file() and p.suffix in allowed_extensions and 'build' not in p.parts]
for p in source_files:
    text = p.read_text(encoding='utf-8')
    old_name = 'k'+'pm'
    assert old_name not in p.relative_to(root).as_posix().lower(), p.name
    assert old_name not in text.lower(), f'Old brand at {p}'
assert (root/'port/r36s-roms-store/bin/gamestore_source.py').is_file()
assert not (root/'port/r36s-roms-store/bin/worker.sh').exists()
assert not (root/'port/r36s-roms-store/bin/archive_safe.py').exists()
assert 'R36S ROMS STORE' in (root/'src/conf.lua').read_text()
assert 'r36s-roms-store' in (root/'port/R36S ROMS STORE.sh').read_text()
print('Brand clean and ROMs-only architecture: OK')
