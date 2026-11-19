#!/usr/bin/env python3
# Adaptado para a R36SPORTSBR STORE a partir de R36S PORT HUB (Lag do Lira).
# GPL-3.0; original em docs/preservacao/original/tools/mkart.py.
"""Cria artes modernas de PREVIA com a logo propria da R36SPORTSBR STORE.

Nao sobrescreve logos, temas, capa ou fanart utilizados pelo aplicativo.
Saida padrao: build/generated-assets/art/cover.png e fanart.png.
Requer Pillow. Nao usa fontes, logos nem cores do projeto original.
"""
import argparse
import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont, ImageOps
except ImportError as exc:
    raise SystemExit("Instale Pillow: python3 -m pip install Pillow") from exc

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOGO = ROOT / "r36sportsbrstore/logo.png"
FONT = ROOT / "game/assets/fonts/ChakraPetch-SemiBold.ttf"

# Azul profundo e cinza: identidade moderna, sem estetica retro, sol ou grade.
DARK = (10, 17, 33)
BLUE = (40, 115, 225)
PALE = (224, 234, 250)
MUTED = (151, 169, 195)


def validate_output(destination):
    p = destination.resolve()
    if p == ROOT:
        raise ValueError("Nao e permitido gerar arte na raiz do repositorio")
    if p.is_relative_to(ROOT) and not p.is_relative_to((ROOT / "build").resolve()):
        raise ValueError("Destino dentro do projeto protegido; use build/ ou pasta externa")


def font(size):
    if FONT.is_file():
        return ImageFont.truetype(str(FONT), size=size)
    return ImageFont.load_default()


def fit_text(draw, text, size, max_width):
    while size >= 12:
        f = font(size)
        if draw.textbbox((0, 0), text, font=f)[2] <= max_width:
            return f
        size -= 1
    return font(12)


def backdrop(width, height):
    canvas = Image.new("RGB", (width, height))
    pixels = canvas.load()
    for y in range(height):
        for x in range(width):
            t = x / max(1, width - 1)
            fy = y / max(1, height - 1)
            glow = max(0.0, 1.0 - math.hypot(x - width * 0.72, y - height * 0.33) / (height * 1.25))
            pixels[x, y] = (
                int(DARK[0] + 7 * t + 10 * glow),
                int(DARK[1] + 13 * fy + 30 * glow),
                int(DARK[2] + 30 * t + 58 * glow),
            )
    d = ImageDraw.Draw(canvas)
    m = max(12, int(width * 0.04))
    d.rounded_rectangle((m, m, width - m, height - m), radius=max(16, int(width * .035)),
                        outline=(48, 77, 118), width=max(1, width // 640))
    # Marca discreta com um único traço, sem grades neon.
    d.rounded_rectangle((m, height - m - max(7, height // 75), width - m, height - m),
                        radius=4, fill=BLUE)
    return canvas


def render(width, height, logo, out, subtitle):
    img = backdrop(width, height)
    draw = ImageDraw.Draw(img)
    target_w = int(width * (0.57 if width <= 640 else 0.40))
    target_h = int(height * (0.44 if width <= 640 else 0.40))
    graphic = ImageOps.contain(logo, (target_w, target_h), Image.Resampling.LANCZOS)
    cx = width // 2
    top = int(height * (0.15 if width <= 640 else 0.20))
    img.paste(graphic, (cx - graphic.width // 2, top), graphic)
    title = "R36SPORTSBR STORE"
    ft = fit_text(draw, title, max(20, int(width / 20)), int(width * 0.83))
    bb = draw.textbbox((0, 0), title, font=ft)
    ty = min(int(height * 0.68), top + graphic.height + int(height * 0.035))
    draw.text((cx - (bb[2] - bb[0]) / 2, ty), title, font=ft, fill=PALE)
    subf = fit_text(draw, subtitle, max(15, int(width / 32)), int(width * .83))
    bb = draw.textbbox((0, 0), subtitle, font=subf)
    sy = ty + max(36, int(width / 14))
    if sy + (bb[3] - bb[1]) <= height - int(height * .09):
        draw.text((cx - (bb[2] - bb[0]) / 2, sy), subtitle, font=subf, fill=MUTED)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)
    print(f"Arte gerada: {out} ({width}x{height})")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--logo', type=Path, default=DEFAULT_LOGO)
    ap.add_argument('--out', type=Path, default=ROOT / 'build/generated-assets/art')
    args = ap.parse_args()
    try:
        validate_output(args.out)
        if not args.logo.is_file():
            raise ValueError(f"Logo propria nao encontrada: {args.logo}")
        with Image.open(args.logo) as src:
            graphic = src.convert("RGBA")
            if not graphic.getbbox():
                raise ValueError("A logo nao tem pixels visiveis")
            render(640, 480, graphic, args.out / 'cover.png', 'PORTS  •  JOGOS  •  FERRAMENTAS')
            render(1280, 720, graphic, args.out / 'fanart.png', 'CENTRAL DE CONTEUDO PARA O SEU CONSOLE')
    except (OSError, ValueError) as exc:
        ap.error(str(exc))


if __name__ == '__main__':
    main()
