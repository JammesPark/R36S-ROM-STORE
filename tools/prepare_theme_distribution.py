#!/usr/bin/env python3
"""Prepara a distribuicao dos temas sem alterar os arquivos de origem no Git.

A execucao ocorre DEPOIS do gerador de logos e dos previews Force:
- Jedi/Sith entram em game/themes (instalados com a STORE);
- quatro temas legados migram de game/themes para theme_packages (opcionais);
- o bundler cria theme_updates/ com dados de compatibilidade offline para
  quem ja usa um dos legados (nao entram como temas instalados novos).
As fontes GPL e todos os creditos sao preservados integralmente.
"""
from __future__ import annotations
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FORCE = ("forcejedi", "forcesith")
LEGACY = ("default", "neongrid", "wiiblue", "pastel")
ALLOWED = {"theme.json", "preview.png", "logo_header.png",
           "logo_menu.png", "logo_about.png", "logo_splash.png",
           "background_v4.png", "selected_tiles_v4.png"}


def prepare(root: Path = ROOT):
    included = root / "game" / "themes"
    packages = root / "theme_packages"
    included.mkdir(parents=True, exist_ok=True)
    packages.mkdir(parents=True, exist_ok=True)

    for name in LEGACY:
        src = included / name
        dst = packages / name
        if src.exists():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.move(str(src), str(dst))
        if not (dst / "theme.json").is_file():
            raise RuntimeError(f"Fonte original do tema opcional ausente: {name}")
        meta = json.loads((dst / "theme.json").read_text(encoding="utf-8"))
        if meta.get("id") != name or "Lag do Lira" not in meta.get("author", ""):
            raise RuntimeError(f"Autoria ou ID do tema legado alterados: {name}")
        files = {p.name for p in dst.iterdir() if p.is_file()}
        if not {"theme.json", "preview.png", "logo_header.png"} <= files or not files <= ALLOWED:
            raise RuntimeError(f"Arquivos inesperados/incompletos em {name}: {files}")

    for name in FORCE:
        src = packages / name
        dst = included / name
        if not src.is_dir():
            raise RuntimeError(f"Fonte Force ausente: {src}")
        meta = json.loads((src / "theme.json").read_text(encoding="utf-8"))
        if meta.get("id") != name or meta.get("style", {}).get("layout") != "force":
            raise RuntimeError(f"Tema Force invalido: {name}")
        files = {p.name for p in src.iterdir() if p.is_file()}
        if not {"theme.json", "preview.png", "background_v4.png",
                "selected_tiles_v4.png", "logo_header.png"} <= files:
            raise RuntimeError(f"Tema Force incompleto: {name}")
        dst.mkdir(parents=True, exist_ok=True)
        for file in src.iterdir():
            if file.is_file() and file.name in ALLOWED:
                shutil.copy2(file, dst / file.name)

    remaining = {p.name for p in included.iterdir() if p.is_dir()}
    if remaining != set(FORCE):
        raise RuntimeError(f"Somente os Force podem vir instalados: {remaining}")
    print("Incluidos:", ", ".join(FORCE))
    print("Opcionais com autoria preservada:", ", ".join(LEGACY))
    return FORCE, LEGACY


if __name__ == "__main__":
    prepare()
