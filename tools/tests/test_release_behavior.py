#!/usr/bin/env python3
"""Regras da interface verificadas no game.love empacotado, nao apenas no Git."""
from pathlib import Path
import io
import sys
import zipfile

def check_game_love(data):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for path in ("ui/force_dash.lua", "ui/settings_extra.lua",
                     "ui/screens/licenses.lua", "ui/screens/infolist.lua",
                     "main.lua", "config.lua"):
            assert path in z.namelist(), f"game.love sem {path}"
        force = z.read("ui/force_dash.lua").decode("utf-8")
        slide = force.split("local function recent_slide(self,P)",1)[1].split("local function force_star",1)[0]
        top = force.split("local function top(self,P,templ)",1)[1].split("local function tiles",1)[0]
        for forbidden in ("p.name", "fmt_date(", "ADICIONADO AO CATÁLOGO", "LANÇAMENTO FUTURO"):
            assert forbidden not in slide, f"slide com metadados: {forbidden}"
        assert "Covers.get(p)" in slide and "lg.draw(img" in slide
        assert "p.name" not in top and "wrap_text(p.name" not in top, "Top 5 com nomes"
        assert "cover(p" in top and "item.downloads" in top, "Top 5 sem capas ou contagem"
        extra = z.read("ui/settings_extra.lua").decode("utf-8")
        section = extra.split('label = L("Licenças")',1)[1].split('label = L("Aviso importante")',1)[0]
        assert 'App.push("licenses")' in section
        assert 'App.push("files"' not in section
        license_screen = z.read("ui/screens/licenses.lua").decode("utf-8")
        assert 'action = Base.action' in license_screen
        assert 'if act == "b" then App.pop(); return end' in z.read("ui/screens/infolist.lua").decode("utf-8")
        assert '"licenses"' in z.read("main.lua").decode("utf-8")
        version = z.read("config.lua").decode("utf-8")
        source_version = (Path(__file__).resolve().parents[2] / "game/config.lua").read_text(encoding="utf-8")
        expected = next(line for line in source_version.splitlines() if line.startswith("C.VERSION_NUM = "))
        assert expected in version, f"game.love tem versao divergente: {expected}"
        for theme in ("forcejedi","forcesith"):
            assert f"themes/{theme}/background_v4.png" in z.namelist()

def main():
    for fname in sys.argv[1:]:
        data = Path(fname).read_bytes()
        # Aceita game.love direto, ou ZIP de distribuicao contendo game.love.
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            if "ui/force_dash.lua" in z.namelist():
                check_game_love(data)
            else:
                nested="r36sportsbrstore/game.love"
                assert nested in z.namelist(), f"Pacote sem {nested}: {fname}"
                check_game_love(z.read(nested))
        print(f"Regressoes verificadas no pacote real: {fname}")

if __name__ == "__main__":
    if len(sys.argv) < 2: raise SystemExit("Uso: test_release_behavior.py arquivo.love|pacote.zip")
    main()
