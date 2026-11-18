#!/usr/bin/env python3
"""Regressão real: updater publicado na v0.3.1-beta instala a ponte v0.4.1."""
import importlib.util
import io
import shutil
import tempfile
import zipfile
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path)
 mod=importlib.util.module_from_spec(spec)
 spec.loader.exec_module(mod)
 return mod
legacy=load('legacy_updater_031',R/'tests/fixtures/store_updater_v031.py')
new=load('store_updater_new',R/'port/r36s-roms-store/bin/store_updater.py')
builder=load('make_update',R/'tools/make_roms_update.py')
assert builder.LEGACY_BRIDGE_VERSION=='0.4.1-beta'
assert legacy.ALLOWED==new.LEGACY_ALLOWED
assert new.ALLOWED==new.LEGACY_ALLOWED | {'r36s-roms-store/bin/bios_manager.py'}
def love(version):
 b=io.BytesIO()
 with zipfile.ZipFile(b,'w') as z:
  z.writestr('VERSION',version+'\n')
  z.writestr('bundled/bios_manager.py',(R/'port/r36s-roms-store/bin/bios_manager.py').read_bytes())
 return b.getvalue()
with tempfile.TemporaryDirectory() as td:
 td=Path(td)
 ports=td/'roms'/'ports'
 app=ports/'r36s-roms-store'
 (app/'bin').mkdir(parents=True)
 (app/'state').mkdir()
 (app/'state/roms_favorites.json').write_text('favoritos')
 (app/'VERSION').write_text('0.3.1-beta\n')
 (app/'game.love').write_bytes(love('0.3.1-beta'))
 (ports/'R36S ROMS STORE.sh').write_text('launcher original')
 (app/'LICENSE').write_text('licença antiga')
 (app/'THIRD_PARTY_NOTICES.txt').write_text('terceiros')
 (app/'bin/gamestore_source.py').write_text('backend antigo')
 (app/'bin/store_updater.py').write_bytes((R/'tests/fixtures/store_updater_v031.py').read_bytes())
 installer=td/'instalador.zip'
 with zipfile.ZipFile(installer,'w') as z:
  for rel in builder.FILES:
   if rel.endswith('game.love'): blob=love('0.4.1-beta')
   elif rel.endswith('VERSION'): blob=b'0.4.1-beta\n'
   elif rel.endswith('bios_manager.py'): blob=(R/'port/r36s-roms-store/bin/bios_manager.py').read_bytes()
   elif rel.endswith('store_updater.py'): blob=(R/'port/r36s-roms-store/bin/store_updater.py').read_bytes()
   else: blob=('novo '+rel).encode()
   z.writestr(rel,blob)
 package=td/'update.zip'
 builder.make(installer,package,'0.4.1-beta')
 paths=set(zipfile.ZipFile(package).namelist())
 assert paths==legacy.ALLOWED | {'update_manifest.json'}
 assert legacy.safe_zip(package,'0.4.1-beta')
 assert new.safe_zip(package,'0.4.1-beta')==new.LEGACY_ALLOWED
 up=legacy.Updater(app)
 up.work.mkdir(parents=True)
 dest=up.work/'R36S_ROMS_STORE_v0.4.1-beta_UPDATE.zip'
 shutil.copy2(package,dest)
 sha=legacy.filehash(dest)
 up.publish('ready',version='0.4.1-beta',sha256=sha,size=dest.stat().st_size,filename=dest.name)
 up.request_apply()
 assert up.apply()
 assert (app/'VERSION').read_text().strip()=='0.4.1-beta'
 assert not (app/'bin/bios_manager.py').exists()
 with zipfile.ZipFile(app/'game.love') as z:
  assert z.read('bundled/bios_manager.py').startswith(b'#!/usr/bin/env python3')
 assert (app/'state/roms_favorites.json').read_text()=='favoritos'
 assert up.pending.exists()
 assert up.confirm()
 assert not up.pending.exists()
 assert (app/'state/roms_favorites.json').read_text()=='favoritos'
 builder.LEGACY_BRIDGE_VERSION='never'
 future=td/'future.zip'
 builder.make(installer,future,'0.4.1-beta')
 assert new.safe_zip(future,'0.4.1-beta')==new.ALLOWED
 try:
  legacy.safe_zip(future,'0.4.1-beta')
  raise AssertionError('Updater antigo aceitou oito arquivos')
 except ValueError: pass
print('OTA LEGADO: 0.3.1 instala 0.4.1, mantém backup/favoritos e habilita 7->8: OK')
