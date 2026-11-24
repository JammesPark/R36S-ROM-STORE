#!/usr/bin/env python3
"""Empacota temas extras da STORE para sincronizar na atualizacao geral.

Todos os temas internos vivem em src/themes dentro do game.love. Temas
opcionais em theme_packages só são instalados/atualizados se o usuario ja
os tiver instalado; core/themes.lua verifica user_themes/<id>/theme.json.
O pacote inclui somente arquivos de dados, jamais codigo fornecido por temas.
"""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {"theme.json","preview.png","background_v4.png",
           "selected_tiles_v4.png","logo_header.png","logo_menu.png",
           "logo_about.png","logo_splash.png"}
REQUIRED = {"theme.json", "preview.png", "logo_header.png"}

def bundle(root=ROOT):
    supplied = root/"theme_packages"
    included = root/"src"/"themes"
    target = root/"src"/"theme_updates"
    if target.exists():
        shutil.rmtree(target)  # apenas arquivos gerados; nunca user_themes/
    target.mkdir(parents=True)
    count=0
    for theme in sorted(supplied.iterdir()):
        if not theme.is_dir() or not (theme/"theme.json").is_file():
            continue
        meta=json.loads((theme/"theme.json").read_text(encoding="utf-8"))
        name=theme.name
        assert name==meta.get("id") and name.replace("_","").replace("-","").isalnum(),name
        # Temas Force internos nunca entram no pacote de opcionais.
        if (included/name/"theme.json").exists():
            continue
        files={p.name for p in theme.iterdir() if p.is_file()}
        required = REQUIRED | ({"background_v4.png", "selected_tiles_v4.png"}
                               if meta.get("style", {}).get("layout") == "force" else set())
        assert required <= files,(name,required-files)
        assert files <= ALLOWED,(name,files-ALLOWED)
        dst=target/name
        dst.mkdir()
        for filename in sorted(files):
            shutil.copy2(theme/filename,dst/filename)
        assert json.loads((dst/"theme.json").read_text(encoding="utf-8"))["version"]==meta["version"]
        count+=1
        print("Tema opcional elegivel para upgrade se ja instalado:",
              name,meta["version"],len(files),"arquivos")
    if count==0:
        print("Nenhum tema opcional encontrado; temas internos continuam no pacote.")
    return count

if __name__=="__main__":
    bundle()
