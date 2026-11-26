#!/usr/bin/env python3
"""Generate 4:3 artwork from the approved ROM STORE logo."""
from pathlib import Path
import argparse, math, random
from PIL import Image, ImageDraw, ImageOps

def render(source, out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    logo=Image.open(source).convert('RGBA')
    box=logo.getchannel('A').point(lambda v: 255 if v>=25 else 0).getbbox()
    if not box: raise ValueError('Logo vazia')
    logo=logo.crop(box)
    method=Image.Resampling.NEAREST if logo.width<500 else Image.Resampling.LANCZOS
    def fitted(w,h): return ImageOps.contain(logo,(w,h),method)
    fitted(1200,850).save(out/'logo.png',optimize=True)
    W,H=1280,960
    def background(fan):
        small=Image.new('RGB',(320,240));pix=small.load()
        cx,cy=(245,114) if fan else (160,111)
        for y in range(240):
            for x in range(320):
                g=max(0,1-math.hypot((x-cx)/180,(y-cy)/148))**2
                pix[x,y]=(int(5+8*g),int(12+32*g),int(15+18*g))
        img=small.resize((W,H),Image.Resampling.BICUBIC).convert('RGBA')
        layer=Image.new('RGBA',(W,H));d=ImageDraw.Draw(layer)
        for x in range(0,W,48):d.line((x,0,x,H),fill=(52,166,104,15),width=1)
        for y in range(0,H,48):d.line((0,y,W,y),fill=(52,166,104,15),width=1)
        rng=random.Random(36)
        for i in range(27):
            x=rng.randrange(1,26)*48;y=rng.randrange(1,19)*48
            if fan and x<600:continue
            dx=rng.choice([-1,1])*rng.choice([48,96,144]);dy=rng.choice([-1,1])*48
            color=(63,193,116,36 if fan else 28)
            d.line([(x,y),(x+dx,y),(x+dx,y+dy)],fill=color,width=2)
            d.ellipse((x-3,y-3,x+3,y+3),outline=color,width=2)
        if not fan:
            d.rounded_rectangle((44,44,W-44,H-44),radius=28,outline=(80,204,133,65),width=2)
            for x,y,sx,sy in ((44,44,1,1),(W-44,44,-1,1),(44,H-44,1,-1),(W-44,H-44,-1,-1)):
                d.line((x+sx*28,y,x+sx*106,y),fill=(100,235,156,180),width=4)
                d.line((x,y+sy*28,x,y+sy*106),fill=(100,235,156,180),width=4)
        return Image.alpha_composite(img,layer)
    cover=background(False);mark=fitted(1060,770);cover.alpha_composite(mark,((W-mark.width)//2,(H-mark.height)//2));cover.convert('RGB').save(out/'cover.png',optimize=True)
    fan=background(True);mark=fitted(610,495);mark.putalpha(mark.getchannel('A').point(lambda v:int(v*.60)));fan.alpha_composite(mark,(W-mark.width-65,(H-mark.height)//2));fan.convert('RGB').save(out/'fanart.png',optimize=True)
    for name in ('logo.png','cover.png','fanart.png'):
        with Image.open(out/name) as im: print(name,im.size)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--logo',required=True,type=Path);p.add_argument('--out',required=True,type=Path);a=p.parse_args();render(a.logo,a.out)
