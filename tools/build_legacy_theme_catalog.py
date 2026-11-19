#!/usr/bin/env python3
"""Gera ZIPs opcionais dos temas do Lira + indice remoto com SHA256 real.

Sao usados SOMENTE os arquivos dos temas preexistentes, preservando autor,
ID, nome, versao e GPL-3.0. Executar apos prepare_theme_distribution.py.
"""
from __future__ import annotations
import hashlib
import json
import zipfile
from pathlib import Path
from prepare_theme_distribution import LEGACY, ROOT

TAG = "themes-lira-v0.6.3"
REPO = "JammesPark/R36SPORTSBR-STORE-UPDATES"
ALLOWED = {"theme.json", "preview.png", "logo_header.png", "logo_menu.png",
           "logo_about.png", "logo_splash.png", "background_v4.png",
           "selected_tiles_v4.png"}


def generate(root: Path = ROOT, tag: str = TAG):
    output = root / "dist" / "legacy_themes"
    output.mkdir(parents=True, exist_ok=True)
    previews = output / "previews"
    previews.mkdir(parents=True, exist_ok=True)
    items = []
    for name in LEGACY:
        source = root / "theme_packages" / name
        meta = json.loads((source / "theme.json").read_text(encoding="utf-8"))
        assert meta["id"] == name and "Lag do Lira" in meta["author"], name
        files = sorted(p for p in source.iterdir() if p.is_file())
        names = {p.name for p in files}
        assert {"theme.json", "preview.png", "logo_header.png"} <= names, name
        assert names <= ALLOWED, (name, names - ALLOWED)
        version = meta["version"]
        filename = f"{name}-{version}.zip"
        archive = output / filename
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for file in files:
                z.write(file, file.name)
        with zipfile.ZipFile(archive) as z:
            assert z.testzip() is None
            assert set(z.namelist()) == names
            assert json.loads(z.read("theme.json"))["id"] == name
        (previews / f"{name}.png").write_bytes((source / "preview.png").read_bytes())
        binary = archive.read_bytes()
        size = len(binary)
        assert 100 <= size <= 12 * 1024 * 1024, (name, size)
        items.append({
            "id": name, "name": meta["name"], "version": version,
            "author": meta["author"], "description": meta.get("description", "")[:250],
            "url": f"https://github.com/{REPO}/releases/download/{tag}/{filename}",
            "preview_url": (
                f"https://raw.githubusercontent.com/{REPO}/main/themes/previews/{name}.png"
            ),
            "size": size, "sha256": hashlib.sha256(binary).hexdigest(),
        })
        print(f"Opcional {name}: {size} bytes, SHA256 {items[-1]['sha256']}")
    (output / "themes.json").write_text(
        json.dumps({"catalog_version": 2, "themes": items}, ensure_ascii=False, indent=2)
        + "\n", encoding="utf-8"
    )
    return output


if __name__ == "__main__":
    generate()
