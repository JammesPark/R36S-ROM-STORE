#!/usr/bin/env python3
"""QA visual 640x480: logos de todos os temas + geometria real dos HTMLs Force."""
import base64
import json
import shutil
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from render_force_v4 import STYLE

EXPECTED = {
    "default": ("retro", 12, 1, 190),
    "neongrid": ("xdash", 14, 1, 190),
    "wiiblue": ("channels", 14, 1, 190),
    "pastel": ("pill", 20, 4, 190),
    "forcejedi": ("force", 14, 2, 196),
    "forcesith": ("force", 14, 2, 196),
}

def check_logo_and_geometry():
    main = Image.open(ROOT/"src/assets/logo/logo_header.png").convert("RGBA")
    assert main.size == (140, 40), main.size
    bbox = main.getchannel("A").getbbox()
    assert bbox and bbox[0] >= 2 and bbox[1] >= 2
    assert bbox[2] <= 138 and bbox[3] <= 38
    assert 3.1 < (bbox[2]-bbox[0])/(bbox[3]-bbox[1]) < 3.6
    raw = (ROOT/"src/assets/logo/logo_header.png").read_bytes()
    for name, (layout, x, y, tx) in EXPECTED.items():
        subdir = ROOT/("src/themes" if name in ("forcejedi","forcesith") else "theme_packages")/name
        meta = json.loads((subdir/"theme.json").read_text())
        assert meta["id"] == name and meta["version"]
        assert (subdir/"logo_header.png").read_bytes() == raw, name
        if layout == "force":
            bottom = 45
            scale = min(1, (bottom-y-2)/main.height)
        elif layout == "pill":
            bottom = 40
            scale = min(1.3, (bottom-y-2)/main.height)
        else:
            bottom = 39
            scale = min(1.3, (bottom-y-2)/main.height)
        right = x + main.width*scale
        assert right <= tx-12, (name, right, tx)
        assert y+main.height*scale <= bottom-1, (name, scale)
        print(f"QA {name}: logo x={x}..{right:.1f}; texto x>={tx}; margem={tx-right:.1f}px")
    for path, snippets in {
        "src/ui/force_dash.lua": ['local tx=math.max(196,14+(lw or 0)+32)'],
        "src/ui/gfx.lua": ['local tx = math.max(190, (pill and 20 or 12) + lw + 30)'],
        "src/ui/neon_dash.lua": ['local title_x = math.max(190, 12 + lw + 30)'],
        "src/ui/xdash.lua": ['local title_x = math.max(190, 14 + lw + 30)'],
        "src/ui/channels.lua": ['local name_x = math.max(190, 14 + lw + 30)'],
    }.items():
        text=(ROOT/path).read_text(encoding="utf-8")
        for snippet in snippets:
            assert snippet in text, (path,snippet)
    about=(ROOT/"src/ui/screens/about.lua").read_text(encoding="utf-8")
    assert 'G.logo(26, 66, "about", 1.04)' in about
    about_width=132*min(1.04,(165-26)/132,(140-66)/62)
    assert 26+about_width < 168  # Cartao Telegram
    splash=(ROOT/"src/ui/screens/splash.lua").read_text(encoding="utf-8")
    assert 'G.logo(lx, 70, "splash")' in splash
    assert (640-252)//2 + 252 <= 640

def check_force_screens():
    # Importar apenas quando executar QA visual; unittest discovery nao possui Chromium.
    from playwright.sync_api import sync_playwright
    out=ROOT/"dist"/"qa_all_themes"
    out.mkdir(parents=True,exist_ok=True)
    png=base64.b64encode((ROOT/"src/assets/logo/logo_header.png").read_bytes()).decode()
    chrome=next((shutil.which(name) for name in
      ("google-chrome","google-chrome-stable","chromium","chromium-browser") if shutil.which(name)),None)
    with sync_playwright() as p:
        kw={"headless":True,"args":["--no-sandbox","--disable-dev-shm-usage"]}
        if chrome: kw["executable_path"]=chrome
        browser=p.chromium.launch(**kw)
        for name in ("jedi","sith"):
            source=ROOT/"docs/design/force-v4"/(name+"-v4.html")
            page=browser.new_page(viewport={"width":640,"height":480},device_scale_factor=1)
            errors=[]
            page.on("pageerror",lambda error:errors.append(str(error)))
            page.set_content(source.read_text(encoding="utf-8"),wait_until="load")
            page.add_style_tag(content=STYLE)
            page.evaluate("""async (data) => {
                const logo=document.querySelector('#brandLogo');
                logo.src='data:image/png;base64,'+data;
                await logo.decode();
            }""",png)
            icon=page.locator("#brandLogo").bounding_box()
            title=page.locator(".brand").bounding_box()
            header=page.locator(".header").bounding_box()
            assert header and icon and title and not errors,(name,errors)
            assert abs(header["width"]-640)<1, (name,header)
            gap=title["x"]-(icon["x"]+icon["width"])
            assert gap >= 20, (name,gap)
            assert icon["y"] >= header["y"]-1
            assert icon["y"]+icon["height"]<=header["y"]+header["height"]+1
            assert title["x"]+title["width"]<=519,(name,title)
            stage=page.locator("#stage")
            assert stage.count()==1
            stage.screenshot(path=str(out/("force"+name+".png")))
            print(f"HTML Force {name}: logo-texto separados por {gap:.1f}px; captura 640x480")
            page.close()
        browser.close()
    return out

if __name__=="__main__":
    check_logo_and_geometry()
    path=check_force_screens()
    print("QA visual concluido:",path)
