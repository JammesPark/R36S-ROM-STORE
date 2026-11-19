#!/usr/bin/env python3
"""Gera previews 320x240 para os temas Force Nexus, sem fontes/servicos externos."""
from __future__ import annotations
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
W, H = 320, 240
FONT = {
" ": [0,0,0,0,0,0,0],
"0": [14,17,19,21,25,17,14], "1": [4,12,4,4,4,4,14],
"2": [14,17,1,2,4,8,31], "3": [30,1,1,14,1,1,30],
"4": [2,6,10,18,31,2,2], "5": [31,16,16,30,1,1,30],
"A": [14,17,17,31,17,17,17], "B": [30,17,17,30,17,17,30],
"C": [15,16,16,16,16,16,15], "D": [30,17,17,17,17,17,30],
"E": [31,16,16,30,16,16,31], "F": [31,16,16,30,16,16,16],
"G": [15,16,16,19,17,17,15], "H": [17,17,17,31,17,17,17],
"I": [14,4,4,4,4,4,14], "J": [7,2,2,2,18,18,12],
"K": [17,18,20,24,20,18,17], "L": [16,16,16,16,16,16,31],
"M": [17,27,21,21,17,17,17], "N": [17,25,21,19,17,17,17],
"O": [14,17,17,17,17,17,14], "P": [30,17,17,30,16,16,16],
"Q": [14,17,17,17,21,18,13], "R": [30,17,17,30,20,18,17],
"S": [15,16,16,14,1,1,30], "T": [31,4,4,4,4,4,4],
"U": [17,17,17,17,17,17,14], "V": [17,17,17,17,17,10,4],
"W": [17,17,17,21,21,21,10], "X": [17,17,10,4,10,17,17],
"Y": [17,17,10,4,4,4,4], "Z": [31,1,2,4,8,16,31],
"-": [0,0,0,31,0,0,0], ":": [0,4,4,0,4,4,0],
}
def rgb(s: str):
    return tuple(int(s[i:i+2],16) for i in (1,3,5))
def render(theme: dict) -> bytes:
    color=theme["colors"]
    bg, panel, edge, accent, secondary, txt = map(rgb, (
      color["bg0"],color["bg1"],color["line"],color["accent"],
      color["accent2"],color["text"]))
    pixels=bytearray(bg * (W*H))
    def rect(x,y,w,h,c):
        x0,y0=max(0,x),max(0,y); x1,y1=min(W,x+w),min(H,y+h)
        if x1<=x0 or y1<=y0: return
        row=bytes(c)*(x1-x0)
        for yy in range(y0,y1):
            off=(yy*W+x0)*3
            pixels[off:off+len(row)]=row
    def outline(x,y,w,h,c):
        rect(x,y,w,1,c);rect(x,y+h-1,w,1,c)
        rect(x,y,1,h,c);rect(x+w-1,y,1,h,c)
    def label(x,y,s,c,scale=1):
        x0=x
        for char in s.upper():
            mask=FONT.get(char,FONT[" "])
            for ry,row in enumerate(mask):
                for rx in range(5):
                    if row&(1<<(4-rx)): rect(x+rx*scale,y+ry*scale,scale,scale,c)
            x+=6*scale
        return x-x0
    # barra principal, carrossel vertical, destaque e Top 5 em 640x480 reduzido.
    rect(4,3,312,23,panel);outline(4,3,312,23,edge)
    label(11,11,"R36SPORTSBR",txt,1)
    label(120,11,theme["id"].replace("force",""),accent,1)
    rect(6,32,92,188,panel);outline(6,32,92,188,edge)
    label(13,40,"RECENTES",accent,1)
    rect(26,58,51,73,edge);rect(29,61,45,67,secondary)
    rect(32,65,39,48,panel)
    rect(36,70,31,37,accent)
    label(27,140,theme["id"].replace("force",""),txt,1)
    label(13,170,"ATALHOS",secondary,1)
    for i in range(3): rect(14,181+i*12,76,10,edge)
    rect(103,32,211,93,panel);outline(103,32,211,93,edge)
    label(113,39,"EM DESTAQUE",accent,1)
    rect(112,54,46,61,secondary)
    label(165,63,theme["id"].replace("force",""),txt,2)
    label(165,89,"VER DETALHES",accent,1)
    rect(103,130,211,55,panel);outline(103,130,211,55,edge)
    label(113,138,"TOP 5 DOWNLOADS",accent,1)
    for i in range(5):
        xx=113+i*40
        rect(xx,151,31,26,edge);rect(xx+2,153,27,22,accent if i<2 else secondary)
        label(xx,179,str(i+1),txt,1)
    for k in range(6):
        col,row=k%3,k//3;xx=103+col*72;yy=190+row*17
        rect(xx,yy,67,14,panel);outline(xx,yy,67,14,edge)
        rect(xx+4,yy+4,6,6,accent)
        label(xx+14,yy+4,("JEDI" if theme["id"]=="forcejedi" else "SITH"),txt,1)
    # PNG RGB sem dependencias externas.
    raw=b"".join(b"\x00"+bytes(pixels[y*W*3:(y+1)*W*3]) for y in range(H))
    def chunk(tag,data):
        return struct.pack("!I",len(data))+tag+data+struct.pack("!I",zlib.crc32(tag+data)&0xffffffff)
    return (b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack("!2I5B",W,H,8,2,0,0,0))
            +chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b""))
def main():
    for d in ("forcejedi","forcesith"):
        path=ROOT/"theme_packages"/d/"theme.json"
        data=json.loads(path.read_text(encoding="utf-8"))
        png=render(data)
        (path.parent/"preview.png").write_bytes(png)
        if d=="forcejedi":
            (ROOT/"game/themes/forcejedi/preview.png").write_bytes(png)
        print(f"{d}: preview.png {len(png)} bytes, 320x240")
if __name__=="__main__":
    main()
