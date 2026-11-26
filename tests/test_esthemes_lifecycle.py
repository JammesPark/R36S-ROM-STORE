#!/usr/bin/env python3
import tempfile, subprocess, zipfile, pathlib, os
ROOT=pathlib.Path.cwd()
with tempfile.TemporaryDirectory() as work:
    p=pathlib.Path(work)
    dest=p/"themes";dest.mkdir()
    tmp=p/"tmp";tmp.mkdir()
    fixture=p/"valid.zip"
    with zipfile.ZipFile(fixture,"w") as z:
        z.writestr("demo/theme.xml","<theme><formatVersion>4</formatVersion></theme>")
        z.writestr("demo/_inc/background/bg_1.png","default")
    fetch=p/"fetch.sh"
    fetch.write_text('#!/bin/sh\ncp "$2" "$3"; echo $? > "$5"\n')
    harness=p/"harness.lua"
    harness.write_text('''
package.path="./src/?.lua;"..package.path
package.loaded["lib.i18n"]={set=function()end,L=function(s)return s end}
local messages={}
local out={push=function(_,v) messages[#messages+1]=v end}
local inn={pop=function()return nil end}
love={thread={getChannel=function(n)return n=="out" and out or inn end},
timer={sleep=function()os.execute("sleep 0.05")end}}
package.loaded["love.timer"]=true;package.loaded["love.filesystem"]=true
local job={url=arg[1],dest=arg[2],tmp_dir=arg[3],fetch_sh=arg[4],folder=arg[5],size=0,sha256="",id="test-theme",margin=0,out="out",inn="in"}
assert(loadfile("src/threads/estheme_thread.lua"))(job)
local result=messages[#messages]
print(result.t,result.msg or "")
assert(result.t==arg[6])
''')
    def install(z,name,result):
        subprocess.run(["luajit",str(harness),str(z),str(dest),str(tmp),str(fetch),name,result],check=True,timeout=30)
    install(fixture,"demo","done")
    assert (dest/"demo/theme.xml").is_file()
    assert (dest/"demo/.r36sbr_theme").read_text().strip()=="test-theme"
    (dest/"demo/_inc/background/bg_2.png").write_text("custom")
    install(fixture,"demo","done")
    assert (dest/"demo/_inc/background/bg_2.png").read_text()=="custom"
    assert list((tmp/"estheme_backups").glob("demo-*"))
    install(fixture,"..","error")
    (dest/"link").symlink_to(p)
    install(fixture,"link","error")
    bad=p/"bad.zip"
    with zipfile.ZipFile(bad,"w") as z:z.writestr("demo/../../escape","bad")
    install(bad,"bad","error")
    assert not (dest/"bad").exists()
    print("PASS install, replacement backup, traversal and symlink rejection")
    # Exercise real removal and activation-request functions with temp roots.
    harness2=p/"manage.lua"
    harness2.write_text('''
package.path="./src/?.lua;"..package.path
local app, dest=arg[1],arg[2]
package.loaded["utf8"]={char=function(cp)
  if cp<128 then return string.char(cp) end
  if cp<2048 then return string.char(192+math.floor(cp/64),128+cp%64) end
  return string.char(224+math.floor(cp/4096),128+math.floor(cp/64)%64,128+cp%64)
end}
love={filesystem={write=function()return true end,read=function()return nil end}}
package.loaded["config"]={APP_DIR=app}
package.loaded["lib.i18n"]={L=function(s)return s end}
package.loaded["core.fetcher"]={}
package.loaded["core.osdetect"]={}
package.loaded["core.esgallery"]={}
local M=require("core.esthemes")
local th={id="test-theme",project_url="https://github.com/owner/theme",download_url="https://github.com/owner/theme/archive/refs/heads/main.zip"}
local req,base=M.revision_request(th)
assert(req=="https://api.github.com/repos/owner/theme/commits?sha=main&per_page=1")
local sha=string.rep("a",40)
local rev=M.decode_revision('[{"sha":"'..sha..'","commit":{"committer":{"date":"2026-11-26T12:00:00Z"}}}]',base)
assert(rev and rev.sha==sha and rev.url==base..sha..".zip")
assert(not M.decode_revision('{"message":"rate limit"}',base))
rev.source=th.download_url
M.remote_revisions["owner/theme"]=rev
local installed={origin="hub",readable=true,hub_id="test-theme"}
M.installed["test-theme"]={version="2026-11-25"}
assert(not M.update_available(th,installed)) -- old records do not prove exact version
M.installed["test-theme"].commit=string.rep("b",40)
assert(M.update_available(th,installed))
M.installed["test-theme"].commit=sha
assert(not M.update_available(th,installed))
local pinned=M.download_snapshot(th,rev)
assert(pinned.download_url==rev.url and pinned.installed_commit==sha and th.download_url~=pinned.download_url)
print("PASS revision lookup, unknown legacy version, SHA comparison and immutable archive")
local loc={folder="demo",path=dest.."/demo",root_real=dest,readable=true,xml_ok=true,origin="hub",hub_id="test-theme"}
M.installed={["test-theme"]={folder="demo"}}
assert(M.request_activate(loc))
local f=assert(io.open(app.."/conf/.es_theme"));assert(f:read("*l")=="demo");f:close()
M.active="demo";assert(not M.can_remove(loc));assert(not M.remove(loc))
M.active=nil;loc.origin="firmware";assert(not M.remove(loc))
loc.origin="hub";assert(M.remove(loc));assert(not M.installed["test-theme"])
print("PASS activation request, active/firmware protection and removal")
''')
    subprocess.run(["luajit",str(harness2),str(p/"app"),str(dest)],check=True,timeout=30)
    assert not (dest/"demo").exists()

    # External folders with spaces and internal shared-asset links are valid.
    # The external target remains intact; root symlinks stay protected.
    external=dest/"My External Theme"
    external.mkdir()
    (external/"theme.xml").write_text("<theme/>")
    shared=p/"shared";shared.mkdir()
    (shared/"keep.txt").write_text("must survive")
    (external/"shared-assets").symlink_to(shared,target_is_directory=True)
    manage=harness2.read_text()
    manage=manage[:manage.index("local th={id=")] + '''
local loc={folder="My External Theme",path=dest.."/My External Theme",root_real=dest,root=dest,readable=true,xml_ok=true,origin="user"}
assert(M.can_remove(loc))
assert(M.remove(loc))
'''
    harness2.write_text(manage)
    subprocess.run(["luajit",str(harness2),str(p/"app"),str(dest)],check=True,timeout=30)
    assert not external.exists()
    assert (shared/"keep.txt").read_text()=="must survive"

    # Simulate systemd only, but execute the actual activation script against a temporary cfg.
    bindir=p/"bin";bindir.mkdir()
    for cmd in ("systemctl","sleep","sync"):
        f=bindir/cmd;f.write_text("#!/bin/sh\nexit 0\n");f.chmod(0o755)
    cfg=p/"es_settings.cfg"
    cfg.write_text('<string name="ThemeSet" value="old" />\n<string name="Other" value="keep" />\n')
    env=dict(os.environ,PATH=str(bindir)+":"+os.environ["PATH"])
    backup=p/"settings-backup"
    subprocess.run(["bash","port/r36sromstore/bin/es_theme_apply.sh","demo",str(cfg),str(backup)],env=env,check=True,timeout=10)
    assert 'name="ThemeSet" value="demo"' in cfg.read_text()
    assert 'name="Other" value="keep"' in cfg.read_text()
    assert 'name="ThemeSet" value="old"' in (backup/"es_settings.cfg.bak").read_text()
    print("PASS ThemeSet update and backup with simulated systemd")
