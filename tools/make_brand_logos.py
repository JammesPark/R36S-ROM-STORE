#!/usr/bin/env python3
"""Gera as variantes da logo aprovada em todos os temas sem distorção.

A fonte WebP RGBA compacta, incluída neste repositório, deriva da arte
aprovada pelo projeto R36SPORTSBR STORE. Não altera logos de desenvolvedor.
Executado pelo build e pela publicação de temas Force Nexus.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
# Padrão escolhido: BR prateado + bandeira brasileira no banner.
# A outra opção permanece arquivada no repositório, sem ser carregada no app.
SOURCE = ROOT / "tools" / "brand" / "logo_oficial_cloud.webp"
ALTERNATIVE = ROOT / "tools" / "brand" / "logo_alternativa_sem_bandeira.webp"

def fit(src, width, height, padding=4):
    """Enquadra a arte com margem real, sem cortar brilho ou proporção.

    Ao ampliar o ícone no cabeçalho, a imagem antiga encostava exatamente
    na primeira/última linha do PNG. O brilho ficava visivelmente cortado.
    """
    if width <= 2 * padding or height <= 2 * padding:
        raise ValueError("Margem maior que a área disponível")
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    image = src.copy()
    bbox = image.getchannel("A").point(lambda a: 255 if a > 3 else 0).getbbox()
    if not bbox:
        raise ValueError("Logo sem conteúdo visível")
    image = image.crop(bbox)
    image.thumbnail((width - 2 * padding, height - 2 * padding),
                    Image.Resampling.LANCZOS)
    x = (width - image.width) // 2
    y = (height - image.height) // 2
    canvas.alpha_composite(image, (x, y))
    return canvas

def build(root=ROOT):
    p = root / "tools" / "brand" / "logo_oficial_cloud.webp"
    if not p.is_file():
        raise FileNotFoundError("Falta o arquivo-fonte da logo aprovada: " + str(p))
    logo = Image.open(p).convert("RGBA")
    if logo.width < 400 or logo.height < 100:
        raise ValueError("Imagem-fonte muito pequena")
    # A marca oficial no cabeçalho e INTEIRA (nunca recortar o console).
    # O original 1000x298 tem proporção 3,36:1; 140x40 preserva a
    # proporção por letterbox e inclui BR prata + bandeira brasileira.
    # Apenas o ícone do launcher (128x128) usa o console isolado.
    # O console ocupa ~29% da largura, somente para o launcher.
    icon = logo.crop((0, 0, int(logo.width * 0.29), logo.height))
    variants = {
        "logo_header.png": fit(logo, 140, 40, padding=2),
        "logo_menu.png": fit(logo, 218, 74, padding=6),
        "logo_about.png": fit(logo, 132, 62, padding=4),
        "logo_splash.png": fit(logo, 252, 170, padding=7),
    }
    theme_folders = [root / "game" / "themes" / n for n in
                     ("default", "neongrid", "wiiblue", "pastel", "forcejedi")]
    theme_folders += [root / "theme_packages" / n for n in ("forcejedi", "forcesith")]
    theme_folders += [root / "game" / "assets" / "logo"]
    for folder in theme_folders:
        folder.mkdir(parents=True, exist_ok=True)
        for name, image in variants.items():
            image.save(folder / name, "PNG", optimize=True)
    icon_large = fit(icon, 128, 128, padding=6)
    icon_large.save(root / "r36sportsbrstore" / "logo.png", "PNG", optimize=True)
    print("Logo oficial COM bandeira brasileira: variantes PNG RGBA geradas em",
          len(theme_folders), "diretorios, sem substituir a logo do desenvolvedor")
    return variants

def main():
    build()

if __name__ == "__main__":
    main()

