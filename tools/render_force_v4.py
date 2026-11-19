#!/usr/bin/env python3
"""Reproduz EXACTAMENTE o HTML V4 em PNG: fundo real sem dados ficticios
e preview ilustrativo. Executado no GitHub Actions antes de montar game.love.
Fontes HTML originais: design/force-v4/*.html.
"""
from pathlib import Path
import shutil
import struct
import sys

ROOT=Path(__file__).resolve().parents[1]
STYLE="""
html,body{width:640px!important;height:480px!important;min-height:0!important;
padding:0!important;margin:0!important;overflow:hidden!important;display:block!important}
.heading{display:none!important}
.viewport{width:640px!important;height:480px!important;position:absolute!important;
inset:0!important;box-shadow:none!important;border-radius:0!important}
#stage{top:0!important;left:0!important;transform:none!important}
/* Nunca gravar metadados dos jogos ou nomes do Top 5 na arte de fundo. */
.feature-info,.release-badge,.recent-card .port-label{display:none!important}
"""

def check_png(path):
    data=path.read_bytes()
    if data[:8]!=b"\x89PNG\r\n\x1a\n":raise RuntimeError("PNG invalido: "+str(path))
    w,h=struct.unpack(">II",data[16:24])
    expected=(405,168) if path.name=="selected_tiles_v4.png" else (640,480)
    if (w,h)!=expected:raise RuntimeError(f"PNG com {w}x{h}, deveria ter {expected}")
    print(f"PNG {path.relative_to(ROOT)}: {w}x{h}, {len(data)} bytes")

def render(page,filename,theme,preview):
    page.set_content(filename.read_text(encoding="utf-8"),wait_until="load")
    page.add_style_tag(content=STYLE)
    # Preview HTML sempre usa o mesmo icone oficial atualizado pelo gerador.
    # Sem isso, a logo renderizada no preview diverge do PNG exibido no Hub.
    from base64 import b64encode
    image64=b64encode((ROOT/"game/assets/logo/logo_header.png").read_bytes()).decode("ascii")
    page.evaluate("""async (data) => {
      const logo=document.querySelector('#brandLogo');
      if (logo) {
        logo.src='data:image/png;base64,'+data;
        await logo.decode();
      }
    }""", image64)
    page.evaluate("""(arg) => {
      document.querySelector('.brand span').textContent = arg.name + ' EDITION · v1.0.12';
      const footer=document.querySelector('.footer-right');
      footer.textContent = arg.name + (arg.preview ? ' · PRÉVIA VISUAL' : ' · R36SPORTSBR STORE');
      if (!arg.preview) {
        document.querySelector('.header-right').style.visibility='hidden';
        document.querySelector('#verticalTrack').style.visibility='hidden';
        const counter = document.querySelector('.carousel-count');
        if (counter) counter.style.visibility='hidden';
        document.querySelector('#rail').style.visibility='hidden';
        document.querySelector('#recentRow').style.visibility='hidden';
        document.querySelector('.tile.selected')?.classList.remove('selected');
        // Tab labels sao desenhados exclusivamente em Lua; sem texto fantasma no PNG.
        document.querySelector('.release-switch')?.style.setProperty('visibility','hidden');
      }
    }""",{"name":theme,"preview":preview})
    page.locator("#stage").screenshot(path=str(
       ROOT/"theme_packages"/("force"+theme.lower())/
       ("preview.png" if preview else "background_v4.png")))

def render_selected_sprites(page,source,theme):
    """Captura o estado selecionado de cada cartao diretamente do HTML V4."""
    from PIL import Image
    page.set_content(source.read_text(encoding="utf-8"),wait_until="load")
    page.add_style_tag(content=STYLE)
    result=Image.new("RGBA",(135*3,84*2))
    for i in range(6):
        page.evaluate("""(index) => {
          document.querySelectorAll('.tile').forEach((e,j)=>
            e.classList.toggle('selected',j===index))
        }""",i)
        node=page.locator(".tile").nth(i)
        import io
        pic=Image.open(io.BytesIO(node.screenshot())).convert("RGBA")
        if pic.size!=(135,84):
            # CSS grid usa 418px com gap 6: colunas fracionarias ~135.33px;
            # screenshot pode medir 135/136 conforme arredondamento do browser.
            if pic.size[0] not in (135,136) or pic.size[1]!=84:
                raise RuntimeError(f"Tile com medida inesperada: {pic.size}")
            pic=pic.resize((135,84),Image.Resampling.LANCZOS)
        result.paste(pic,((i%3)*135,(i//3)*84))
    path=ROOT/"theme_packages"/("force"+theme.lower())/"selected_tiles_v4.png"
    result.save(path,optimize=True)

def main():
    # Branding universal (base, temas inclusos e Jedi/Sith) antes das capturas.
    from make_brand_logos import main as build_brand
    build_brand()
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise SystemExit("Instale playwright: python3 -m pip install playwright==1.56.0") from exc
    chrome=next((p for p in ("google-chrome","google-chrome-stable","chromium","chromium-browser")
                 if shutil.which(p)),None)
    if not chrome:
        print("Chrome nao encontrado; playwright vai usar browser proprio se instalado.")
    with sync_playwright() as p:
        kwargs={"headless":True,"args":["--no-sandbox","--disable-dev-shm-usage"]}
        if chrome:kwargs["executable_path"]=shutil.which(chrome)
        browser=p.chromium.launch(**kwargs)
        try:
            for theme in ("JEDI","SITH"):
                src=ROOT/"design"/"force-v4"/(theme.lower()+"-v4.html")
                if not src.exists():raise RuntimeError("HTML V4 de referencia ausente: "+str(src))
                page=browser.new_page(viewport={"width":640,"height":480},
                                      device_scale_factor=1,reduced_motion="reduce")
                try:
                    render(page,src,theme,False)
                    render(page,src,theme,True)
                    render_selected_sprites(page,src,theme)
                finally:
                    page.close()
                package=ROOT/"theme_packages"/("force"+theme.lower())
                for n in ("background_v4.png","preview.png","selected_tiles_v4.png"):check_png(package/n)
                if theme=="JEDI":
                    dest=ROOT/"game/themes/forcejedi"
                    for n in ("background_v4.png","preview.png","selected_tiles_v4.png"):
                        shutil.copy2(package/n,dest/n)
                        check_png(dest/n)
        finally:
            browser.close()
    print("Force V4: backgrounds limpos e previews originais gerados.")
if __name__=="__main__":main()
