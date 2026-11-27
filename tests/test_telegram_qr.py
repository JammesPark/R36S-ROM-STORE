#!/usr/bin/env python3
"""Exercise the actual About screen and decode its generated QR offline."""
from pathlib import Path
import subprocess
import tempfile

script = r'''
package.path="./src/?.lua;"..package.path
local L=function(s)return s end
package.loaded["lib.i18n"]={L=L}
package.loaded["ui.theme"]={W=640,H=480,c={},f={}}
package.loaded["ui.gfx"]={}
package.loaded["config"]={APP_NAME="R36S ROM STORE"}
package.loaded["core.catalog"]={}
love={graphics={newImage=function(path)
    assert(path=="assets/qr/livepix_jammespark.png",path)
    return {setFilter=function() end}
end}}
local S=require("ui.screens.about")
S.layout=function() end
S:enter()
assert(S.pix_qr_image and not S.qr_image and not S.qr)
S:action("a")
assert(S.show_qr and not S.qr_big and type(S.qr)=="table")
local q=S.qr
local n=#q
assert(n>=21)
-- Same orientation and four-module quiet zone as draw_qr_matrix.
local scale=8
local size=(n+8)*scale
local out=assert(io.open(arg[1],"w"))
out:write("P1\n",size," ",size,"\n")
for y=0,size-1 do
    for x=0,size-1 do
        local cx,cy=math.floor(x/scale)-3,math.floor(y/scale)-3
        local dark=q[cx] and q[cx][cy] and q[cx][cy]>0
        out:write(dark and "1 " or "0 ")
    end
    out:write("\n")
end
out:close()
S:action("a"); assert(S.qr_big)
S:action("b"); assert(S.show_qr and not S.qr_big)
S:action("b"); assert(not S.show_qr)
S:action("a"); assert(S.qr==q)
S:on_start(); assert(S.show_pix and not S.show_qr and S.pix_qr_image)
print("PASS About: open, enlarge, close, cache, independent LivePix")
'''
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp)
    lua=root/"qr.lua"
    lua.write_text(script)
    pbm=root/"qr.pbm"
    subprocess.run(["luajit",str(lua),str(pbm)],check=True,timeout=30)
    decoded=subprocess.check_output(["zbarimg","--quiet","--raw",str(pbm)],text=True).strip()
    assert decoded=="https://t.me/r36sportsromstorebr", decoded
    assert not Path("src/assets/qr/telegram_r36sportsbr.png").exists()
    print("PASS Telegram QR decoded:",decoded)
