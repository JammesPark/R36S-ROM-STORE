from pathlib import Path
from PIL import Image
from tempfile import TemporaryDirectory
from subprocess import run
import os,sys

root=Path.cwd()
assert (root/'port/r36sromstore').is_dir()
assert not (root/'port/r36sromsstore').exists()
launcher=(root/'port/R36S ROM STORE.sh').read_text()
assert 'GAMEDIR="$PORTSD/r36sromstore"' in launcher
assert 'LEGACY="$PORTSD/r36sromsstore"' in launcher
assert 't.identity = "r36sromsstore"' in (root/'src/conf.lua').read_text()
assert 'M.APP = "r36sromstore"' in (root/'src/core/updater/rules.lua').read_text()
with TemporaryDirectory() as t:
    ports=Path(t); old=ports/'r36sromsstore'; new=ports/'r36sromstore'
    (old/'conf').mkdir(parents=True);new.mkdir()
    (old/'conf/theme.txt').write_text('default')
    (old/'conf/favorites.json').write_text('["favorite"]')
    (old/'conf/download_history.json').write_text('["history"]')
    (old/'backups').mkdir()
    (old/'backups/old.zip').write_text('old backup')
    (old/'catalog_url.txt').write_text('https://example.invalid/catalog')
    (old/'catalogo_proprio.zlib').write_text('old catalog')
    (new/'catalogo_proprio.zlib').write_text('new catalog')
    (new/'game.love').touch()
    (new/'bin').mkdir()
    import shutil
    shutil.copyfile(root/'port/r36sromstore/bin/migrate_userdata.py',new/'bin/migrate_userdata.py')
    (new/'.legacy_migrated').touch()
    (new/'conf').mkdir()
    (new/'conf/existing').write_text('keep')
    (old/'conf/existing').write_text('older')
    (old/'catalog.json').write_text('{"custom":true}')
    shutil.copyfile(root/'port/r36sromstore/catalog.json',new/'catalog.json')
    part=launcher.split('GAMEDIR="$PORTSD/r36sromstore"',1)[1].split('mkdir -p "$CONFDIR" "$GAMEDIR/tmp"',1)[0]
    run(['bash','-c','GAMEDIR="$PORTSD/r36sromstore"'+part],env=dict(os.environ,PORTSD=str(ports)),check=True)
    assert (new/'conf/theme.txt').read_text()=='default'
    assert (old/'conf/theme.txt').exists()
    assert (new/'catalogo_proprio.zlib').read_text()=='new catalog'
    assert (new/'.legacy_migrated_v2').exists()
    assert (new/'conf/existing').read_text()=='keep'
    assert (new/'catalog.json').read_text()=='{"custom":true}'
    assert (new/'conf/favorites.json').read_text()=='["favorite"]'
    assert (new/'conf/download_history.json').read_text()=='["history"]'
    assert (new/'catalog_url.txt').read_text()=='https://example.invalid/catalog'
    assert (old/'backups/old.zip').read_text()=='old backup'
    assert not (new/'backups/old.zip').exists()
    (new/'conf/theme.txt').write_text('neongrid')
    run(['bash','-c','GAMEDIR="$PORTSD/r36sromstore"'+part],env=dict(os.environ,PORTSD=str(ports)),check=True)
    assert (new/'conf/theme.txt').read_text()=='neongrid'
    run([sys.executable,'tools/render_romstore_art.py','--logo','src/assets/logo/logo_splash.png','--out',str(ports/'art')],check=True)
    for file in ('cover.png','fanart.png'):
        with Image.open(ports/'art'/file) as im: assert im.size==(1280,960)
print('PASS new folder, legacy migration, artwork and protected old data')
