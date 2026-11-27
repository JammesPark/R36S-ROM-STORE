#!/usr/bin/env python3
"""Exercise the shipped old clients, first launch, and the new feed on local TLS."""
import functools
import hashlib
import http.server
import io
import json
import os
from pathlib import Path
import shutil
import ssl
import subprocess
import sys
import tempfile
import threading
from urllib.request import urlopen
from zipfile import ZipFile

BASELINES = {
    "0.6.7-beta": "650722a94b1aa37ab2bdd623b85a84e7f1bae84732b8213e119285c3d007a0ca",
    "0.6.8-beta": "d7dc079da6c3befab92b62755e54aca9746da77e79cd7e6f72b225424266a907",
    "0.7.0-beta": "5c0146f154542c660e901da6d9446102bcec2122848dc254f1894c7245316d13",
}
HARNESS = r'''
function love.load()
  local ok,reason=xpcall(function()
    local env=os.getenv
    local root=assert(env("MODULES"))
    package.path=root.."/?.lua;"..package.path
    local op=env("OP")
    local C=require("config")
    if op=="feed" then
      assert(not C.EXPERIMENTAL_NO_OTA)
      assert(C.UPDATE_URL:match("/ota/rom%-store/update%.json$"))
      C.UPDATE_URL=env("URL")
      local updater=require("core.update")
      local fetcher=require("core.fetcher")
      local done=false
      updater.check(function() done=true end)
      local limit=love.timer.getTime()+25
      while not done and love.timer.getTime()<limit do fetcher.update();love.timer.sleep(0.01) end
      fetcher.stop()
      assert(done and updater.state==env("RESULT"),(updater.state or "").." "..tostring(updater.error))
      if updater.info then assert(updater.info.sha256==env("HASH")) end
    elseif op=="boot" then
      require("core.updater.manager").on_boot()
    else
      local job={op=op, app_dir=C.APP_DIR, ports_dir=C.PORTS_DIR, tmp_dir=C.TMP_DIR,
        current_version=C.VERSION_NUM, current_label=C.VERSION_NUM, origin="rede",
        package="candidate.zip", out_channel="test-out",in_channel="test-in",
        tools={zip={kind="unzip",bin="/usr/bin/unzip",name="unzip"}},
        archive=env("PACKAGE"),dest=env("DEST"),url=env("URL"),
        sha256=env("HASH"),size=tonumber(env("SIZE")),fetch_sh=C.FETCH_SH,strict_tls=true}
      assert(loadfile(root.."/threads/updater_thread.lua"))(job)
      local out=love.thread.getChannel("test-out")
      local last
      while true do local x=out:pop();if not x then break end; last=x end
      assert(last and last.t==env("RESULT"),last and (last.code or last.t) or "no result")
      if env("CODE")~="" then assert(last.code==env("CODE"),tostring(last.code)) end
    end
  end,debug.traceback)
  if not ok then io.stderr:write(tostring(reason).."\n"); os.exit(1) end
  love.event.quit(0)
end
'''

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def legacy_zip(version, directory):
    name = f"R36S_ROMS_STORE_{version}.zip"
    local = os.getenv("STORE_BASELINE_DIR")
    if local:
        file = Path(local) / name
    else:
        file = directory / name
        url = f"https://github.com/JammesPark/R36S-ROM-STORE-UPDATES/releases/download/store-v{version}/{name}"
        with urlopen(url, timeout=60) as remote, file.open("wb") as dst:
            shutil.copyfileobj(remote, dst)
    assert digest(file) == BASELINES[version], version
    return file

def modules(game, folder):
    with ZipFile(io.BytesIO(game.read_bytes())) as z:
        for name in z.namelist():
            if name.endswith(".lua"):
                z.extract(name, folder)
    return folder

def run(harness, code_root, app, op, result="", code="", **settings):
    env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy", ALSOFT_DRIVERS="null",
               R36SBR_DIR=str(app), R36SBR_PORTS_DIR=str(app.parent), MODULES=str(code_root),
               OP=op, RESULT=result, CODE=code, XDG_DATA_HOME=str(harness.parent/"xdg"),
               NO_PROXY="127.0.0.1,localhost",no_proxy="127.0.0.1,localhost",**settings)
    subprocess.run(["love",str(harness)],env=env,timeout=55,check=True)

class QuietHTTP(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

def check(installer):
    out = installer.parent
    feed = json.loads((out/"ota/rom-store/update.json").read_text())
    ota = out / feed["url"].split("/")[-1]
    assert digest(ota) == feed["sha256"] and ota.stat().st_size == feed["size"]
    assert feed["version"] == "0.7.2-beta" and feed["min_version"] == "0.7.1-beta"
    with tempfile.TemporaryDirectory() as tmp:
        root=Path(tmp)
        harness=root/"harness"
        harness.mkdir()
        (harness/"conf.lua").write_text("function love.conf(t) t.window=false;t.modules.graphics=false;t.modules.audio=false;t.modules.window=false end")
        (harness/"main.lua").write_text(HARNESS)
        for version in BASELINES:
            ports=root/version/"ports";ports.mkdir(parents=True)
            old=ports/"r36sromsstore"; new=ports/"r36sromstore"
            with ZipFile(legacy_zip(version,root)) as previous:
                previous.extractall(ports)
            old_game=old/"game.love"; before=digest(old_game)
            old_modules=modules(old_game,root/("source-"+version))
            (old/"tmp").mkdir(exist_ok=True)
            run(harness,old_modules,old,"install","error","invalid",PACKAGE=str(ota))
            assert digest(old_game)==before and not new.exists()
            old_conf=old/"conf/love/r36sromsstore";old_conf.mkdir(parents=True)
            for name in ("favorites.json","config.json","download_history.json","installed.json"):
                (old_conf/name).write_text(version)
            (old/"backups").mkdir(exist_ok=True);(old/"backups/history").write_text(version)
            (old/"catalogo_proprio.zlib").write_bytes(b"local catalog")
            with ZipFile(installer) as full:
                full.extractall(ports)
            # Run the real launcher. Replace just the handheld process with a no-op at first boot.
            fake=root/"fake";fake.mkdir(exist_ok=True)
            (fake/"love").write_text("#!/bin/sh\nexit 0\n");(fake/"love").chmod(0o755)
            subprocess.run(["bash",str(ports/"R36S ROM STORE.sh")],check=True,timeout=30,
                           stdout=subprocess.DEVNULL,env=dict(os.environ,PATH=str(fake)+":"+os.environ["PATH"],XDG_DATA_HOME=str(root/"empty")))
            for f in old_conf.iterdir():
                assert (new/f.relative_to(old)).read_bytes()==f.read_bytes()
            assert (new/"catalogo_proprio.zlib").read_bytes()==b"local catalog"
            assert (old/"backups/history").read_text()==version and (ports/"R36S ROMS STORE.sh").is_file()
            assert digest(old_game)==before and not (new/"backups/.journal").exists()
            print("PASS official installer migration and legacy OTA rejection:",version,flush=True)
        app=new
        fresh=modules(app/"game.love",root/"new-modules")
        (harness/"threads").mkdir()
        shutil.copyfile(fresh/"threads/fetch_thread.lua",harness/"threads/fetch_thread.lua")
        cert=root/"cert.pem";key=root/"key.pem"
        subprocess.run(["openssl","req","-x509","-newkey","rsa:2048","-nodes","-days","1",
                        "-subj","/CN=localhost","-addext","subjectAltName=IP:127.0.0.1",
                        "-keyout",str(key),"-out",str(cert)],check=True,stderr=subprocess.DEVNULL)
        serve=root/"www";serve.mkdir()
        server=http.server.ThreadingHTTPServer(("127.0.0.1",0),functools.partial(QuietHTTP,directory=serve))
        context=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER);context.load_cert_chain(cert,key)
        server.socket=context.wrap_socket(server.socket,server_side=True)
        thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
        try:
            base=f"https://127.0.0.1:{server.server_port}/"
            shutil.copyfile(ota,serve/ota.name)
            args=dict(URL=base+ota.name,HASH=feed["sha256"],SIZE=str(feed["size"]),
                      DEST=str(root/"downloaded.zip"),CURL_CA_BUNDLE=str(cert))
            local_feed=dict(feed,url=args["URL"])
            def feed_test(variant,expected):
                (serve/"feed.json").write_text(json.dumps(variant))
                run(harness,fresh,app,"feed",expected,URL=base+"feed.json",HASH=feed["sha256"],CURL_CA_BUNDLE=str(cert))
            # Use the exact previously published official package to exercise a real upgrade.
            oldzip=root/"official-071.zip"
            with urlopen("https://github.com/JammesPark/R36S-ROM-STORE-UPDATES/releases/download/store-v0.7.1-beta/R36S_ROM_STORE_0.7.1-beta.zip",timeout=60) as r, oldzip.open("wb") as f:
                shutil.copyfileobj(r,f)
            assert digest(oldzip)=="32bfe860dca339fae9cab29f207f262d8e9873888e38bb34d0eb0786b73e1918"
            oldports=root/"actual-071"/"ports";oldports.mkdir(parents=True)
            with ZipFile(oldzip) as z:z.extractall(oldports)
            oldapp=oldports/"r36sromstore"
            oldcode=modules(oldapp/"game.love",root/"actual-071-modules")
            (oldapp/"tmp").mkdir(exist_ok=True)
            marker=oldapp/"conf/love/r36sromsstore/favorites.json"
            marker.parent.mkdir(parents=True,exist_ok=True);marker.write_text('{"test":"preserve"}')
            (serve/"feed.json").write_text(json.dumps(local_feed))
            run(harness,oldcode,oldapp,"feed","available",URL=base+"feed.json",HASH=feed["sha256"],CURL_CA_BUNDLE=str(cert))
            upgrade=dict(args,DEST=str(root/"upgrade-071.zip"))
            run(harness,oldcode,oldapp,"download","done",**upgrade)
            run(harness,oldcode,oldapp,"install","done",PACKAGE=upgrade["DEST"])
            with ZipFile(installer) as z:assert (oldapp/"game.love").read_bytes()==z.read("r36sromstore/game.love")
            assert marker.read_text()=='{"test":"preserve"}'
            journal=oldapp/"backups/.journal"
            journal.write_text(journal.read_text().replace("state=pending","state=booting"))
            run(harness,fresh,oldapp,"boot")
            assert not journal.exists()
            print("PASS actual 0.7.1-beta -> 0.7.2-beta OTA and preserved favorites",flush=True)
            feed_test(local_feed,"uptodate")
            feed_test(dict(local_feed,version="0.7.3-beta"),"available")
            feed_test(dict(local_feed,sha256=""),"error")
            run(harness,fresh,app,"download","error","download_hash",**dict(args,HASH="0"*64))
            run(harness,fresh,app,"download","error","download_size",**dict(args,SIZE=str(feed["size"]+1)))
            run(harness,fresh,app,"download","error","download",**dict(args,CURL_CA_BUNDLE=str(root/"untrusted")))
            assert not Path(args["DEST"]).exists()
            run(harness,fresh,app,"download","done",**args)
            assert digest(Path(args["DEST"]))==feed["sha256"]
            run(harness,fresh,app,"install","done",PACKAGE=args["DEST"])
            journal=app/"backups/.journal"
            assert "state=pending" in journal.read_text()
            journal.write_text(journal.read_text().replace("state=pending","state=booting"))
            run(harness,fresh,app,"boot")
            assert not journal.exists()
            print("PASS HTTPS feed, discovery, size, hash, TLS, installation and first-boot confirmation")
        finally:
            server.shutdown();server.server_close();thread.join()

if __name__ == "__main__":
    check(Path(sys.argv[1]).resolve())
