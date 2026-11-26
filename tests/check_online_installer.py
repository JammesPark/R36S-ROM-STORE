#!/usr/bin/env python3
"""Test the online installer with an isolated destination and exact candidate package.
Run only in GitHub Actions, with an empty /roms/ports created by the workflow."""
import hashlib, json, os, pathlib, subprocess, sys, tempfile
from zipfile import ZipFile

assert os.environ.get("GITHUB_ACTIONS") == "true"
ports=pathlib.Path("/roms/ports")
assert ports.is_dir() and not ports.is_symlink() and not any(ports.iterdir())
full=pathlib.Path(sys.argv[1]).resolve()
feed=json.loads((full.parent/"ota/rom-store/update.json").read_text())
version=feed["version"]
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
with tempfile.TemporaryDirectory() as tmp:
    root=pathlib.Path(tmp)
    (root/"feed.json").write_text(json.dumps(feed))
    url="https://github.com/JammesPark/R36S-ROM-STORE-UPDATES/releases/download/store-v"+version+"/"+full.name
    (root/"release.json").write_text(json.dumps(dict(tag_name="store-v"+version,draft=False,prerelease=False,assets=[dict(name=full.name,browser_download_url=url,digest="sha256:"+digest(full),size=full.stat().st_size)])))
    fake=root/"curl"
    fake.write_text("""#!/usr/bin/env python3
import os,pathlib,shutil,sys
a=sys.argv[1:];root=pathlib.Path(os.environ['MOCK_ROOT']);dest=pathlib.Path(a[a.index('-o')+1]);url=next(x for x in a if x.startswith('https://'))
if url.endswith('/ota/rom-store/update.json'):
    if os.environ.get('MOCK_FAIL')=='1': print('503',end='');sys.exit(0)
    shutil.copyfile(root/'feed.json',dest); print('200',end='')
elif '/releases/tags/store-v' in url: shutil.copyfile(root/'release.json',dest)
elif url.endswith('/'+pathlib.Path(os.environ['MOCK_FULL']).name): shutil.copyfile(os.environ['MOCK_FULL'],dest)
else: sys.exit('Unexpected URL '+url)
""")
    fake.chmod(0o755)
    env=dict(os.environ,PATH=str(root)+":"+os.environ["PATH"],MOCK_ROOT=str(root),MOCK_FULL=str(full),R36SBR_INSTALLER_TEST="1")
    script=full.parent/"INSTALAR_R36S_ROM_STORE.sh"
    subprocess.run(["sh","-n",str(script)],check=True)
    def run_installer():
        try:
            subprocess.run(["sh",str(script),"sd1","--lang=pt"],env=env,check=True,timeout=60)
        except subprocess.CalledProcessError:
            for p in (ports/"instalador_ultimo.log",pathlib.Path("/tmp/R36S_ROMS_STORE_instalador_inicio.log")):
                if p.is_file(): print(p.read_text(errors="replace"),flush=True)
            raise
    run_installer()
    app=ports/"r36sromstore"
    assert (ports/"R36S ROM STORE.sh").is_file() and not (ports/"r36sromsstore").exists()
    with ZipFile(full) as z: assert (app/"game.love").read_bytes()==z.read("r36sromstore/game.love")
    before=digest(app/"game.love")
    (app/"conf").mkdir(exist_ok=True)
    marker=app/"conf/online-installer-test";marker.write_text("preserve")
    run_installer()
    assert marker.read_text()=="preserve"
    bad=subprocess.run(["sh",str(script),"sd1","--lang=pt"],env=dict(env,MOCK_FAIL="1"),timeout=60)
    assert bad.returncode!=0 and digest(app/"game.love")==before and marker.read_text()=="preserve"
    with ZipFile(full.parent/f"R36S_ROM_STORE_{version}_UPDATE.zip") as z:
        assert "r36sromstore/game.love" in z.namelist() and all(n.startswith("r36sromstore/") for n in z.namelist())
    print("PASS online installer: new feed, exact candidate bytes, preserve configuration, fail closed, manual ZIP")
