#!/usr/bin/env python3
"""Exercise actual updater thread with temporary files, real LÖVE SHA-256, no network."""
import hashlib, json, os, pathlib, subprocess, tempfile, zipfile
ROOT=pathlib.Path.cwd()
with tempfile.TemporaryDirectory() as td:
    p=pathlib.Path(td)
    ports=p/"ports"; app=ports/"r36sromstore"; app.mkdir(parents=True)
    tmp=app/"tmp";tmp.mkdir()
    (app/"conf").mkdir();(app/"conf/favorites.json").write_text("keep")
    (app/"game.love").write_bytes(b"original")
    (ports/"R36S ROM STORE.sh").write_bytes(b"old launcher")
    data={"R36S ROM STORE.sh":b"new launcher","r36sromstore/game.love":b"updated","r36sromstore/new.txt":b"new"}
    def make(name, files, corrupt=False):
        f=p/name
        m={"format":1,"version":"0.7.1-beta","type":"incremental","min_version":"0.7.0-beta","files":[{"path":k,"size":len(v),"sha256":("0"*64 if corrupt else hashlib.sha256(v).hexdigest())} for k,v in files.items()]}
        with zipfile.ZipFile(f,"w") as z:
            z.writestr("update_manifest.json",json.dumps(m))
            for k,v in files.items():
                info=zipfile.ZipInfo(k); info.create_system=3;info.external_attr=0o100644<<16
                z.writestr(info,v)
        return f
    valid=make("valid.zip",data)
    bad=make("bad.zip",data,True)
    legacy=make("legacy.zip",{"r36sromsstore/game.love":b"wrong"})
    protected=make("protected.zip",{"r36sromstore/conf/favorites.json":b"wrong"})
    harness=p/"harness";harness.mkdir()
    (harness/"conf.lua").write_text('function love.conf(t) t.window=false;t.modules.graphics=false;t.modules.audio=false;t.modules.window=false end')
    (harness/"main.lua").write_text(r'''
function love.load()
  local ok,err=xpcall(function()
    local root=os.getenv("TEST_SRC")
    package.path=root.."/?.lua;"..root.."/?/init.lua;"..package.path
    local Rules=require("core.updater.rules")
    assert(not Rules.check_path("r36sromsstore/game.love"))
    assert(not Rules.check_path("r36sromstore/conf/favorites.json"))
    local OUT=love.thread.getChannel("out")
    local IN=love.thread.getChannel("in")
    local op=os.getenv("TEST_OP")
    local job={op=op,app_dir=os.getenv("TEST_APP"),ports_dir=os.getenv("TEST_PORTS"),tmp_dir=os.getenv("TEST_TMP"),archive=os.getenv("TEST_ZIP"),
        current_version="0.7.0-beta",current_label="0.7.0-beta",out_channel="out",in_channel="in",package="test.zip",origin="test",
        tools={zip={kind="unzip",bin="/usr/bin/unzip",name="unzip"}}}
    if os.getenv("TEST_FAIL")=="1" then IN:push("__simulate_fail__") end
    assert(loadfile(root.."/threads/updater_thread.lua"))(job)
    local last
    while true do local m=OUT:pop();if not m then break end;last=m end
    assert(last,"no result")
    print("updater: "..tostring(last.t).." "..tostring(last.code or ""))
    assert(last.t==os.getenv("TEST_EXPECT"),last.detail or last.code or last.t)
    local code=os.getenv("TEST_CODE")
    if code and code~="" then assert(last.code==code,tostring(last.code)) end
  end,debug.traceback)
  if not ok then io.stderr:write(tostring(err).."\n");os.exit(1) end
  love.event.quit(0)
end
''')
    def run(f,expect,code="",fail=False):
        e=dict(os.environ,TEST_SRC=str(ROOT/"src"),TEST_PORTS=str(ports),TEST_APP=str(app),TEST_TMP=str(tmp),TEST_ZIP=str(f),TEST_OP="install",TEST_EXPECT=expect,TEST_CODE=code,TEST_FAIL="1" if fail else "0",SDL_AUDIODRIVER="dummy",ALSOFT_DRIVERS="null",XDG_DATA_HOME=str(p/"xdg"))
        subprocess.run(["love",str(harness)],env=e,check=True,timeout=45)
    def unchanged():
        assert (app/"game.love").read_bytes()==b"original"
        assert (ports/"R36S ROM STORE.sh").read_bytes()==b"old launcher"
        assert not (app/"new.txt").exists()
        assert (app/"conf/favorites.json").read_text()=="keep"
    run(legacy,"error","invalid");unchanged()
    run(protected,"error","invalid");unchanged()
    run(bad,"error","hash");unchanged()
    run(valid,"error","install_restored",True);unchanged()
    run(valid,"done")
    assert (app/"game.love").read_bytes()==b"updated"
    assert (app/"conf/favorites.json").read_text()=="keep"
    assert (app/"backups/.journal").read_text().startswith("state=pending")
    assert any((app/"backups").glob("*/files/r36sromstore/game.love"))
    print("PASS update path, protected data, hash rejection, rollback and local install")
