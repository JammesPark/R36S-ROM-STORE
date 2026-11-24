#!/usr/bin/env python3
"""Regressoes de temas, gatilhos e selos de regiao para a Experimental."""
from pathlib import Path

root = Path("game")
theme_ids = {p.name for p in (root / "themes").iterdir() if p.is_dir()}
assert theme_ids == {"default", "neongrid"}, f"Temas em game.love: {sorted(theme_ids)}"
for obsolete in ("forcejedi", "forcesith", "pastel", "wiiblue"):
    assert not (root / "themes" / obsolete).exists(), f"Tema antigo presente: {obsolete}"
    assert not (Path("theme_packages") / obsolete).exists(), f"Pacote antigo: {obsolete}"
core = (root / "core/themes.lua").read_text(encoding="utf-8")
assert 'M.ALLOWED = { default = true, neongrid = true }' in core
assert 'M.ORDER = { "default", "neongrid" }' in core
store = (root / "ui/screens/store.lua").read_text(encoding="utf-8")
assert 'Prefs.get(view_key())' in store
assert '"rom_view_matrix"' in store and '"rom_view_default"' in store
assert 'change_view(act == "l2" and -1 or 1)' in store
assert 'Themes.current=="neongrid"' in store
assert 'active_view(self.section) == "showcase"' in store
assert 'active_view(self.section) == "grid"' in store
assert 'self.section == "games" and Themes.current == "default"' not in store
settings = (root / "ui/settings_extra.lua").read_text(encoding="utf-8")
assert '"rom_view_default"' in settings and '"rom_view_matrix"' in settings
inputsrc = (root / "core/input.lua").read_text(encoding="utf-8")
assert 'lefttrigger = "l2", righttrigger = "r2"' in inputsrc
mainsrc = (root / "main.lua").read_text(encoding="utf-8")
assert 'and (act == "l2" or act == "r2") then return end' not in mainsrc
region = (root / "ui/region.lua").read_text(encoding="utf-8")
for code, color in {"JP": "#FF738A", "CN": "#FFC065", "TW": "#58E0A6", "HK": "#B9A1FF"}.items():
    assert f'{code} = T.hex("{color}")' in region, (code, color)
for name in ("store.lua", "details.lua"):
    assert 'require("ui.region")' in (root / "ui/screens" / name).read_text(encoding="utf-8")
print("EXPERIMENTAL LAYOUTS: OK (2 temas, 3 vistas, L2/R2, selos regionais)")

# Cabecalhos aprovados e geometria 640x480 das marcas.
menu = (root / "ui/screens/menu.lua").read_text(encoding="utf-8")
xdash = (root / "ui/xdash.lua").read_text(encoding="utf-8")
about = (root / "ui/screens/about.lua").read_text(encoding="utf-8")
assert 'G.logo(61, 6, "menu", 1)' in menu
assert 61 + 218 / 2 == 20 + 300 / 2
assert 'function S:draw_battery(y, right, left)' in menu
assert 'left and (left + 28)' in menu
assert 'G.logo_box(logo_x, 4, 120, 78, "splash")' in xdash
assert 'S.draw_battery(self, 20, nil, left)' in xdash
assert 4 + 78 < 88
assert 640 - 128 + 120 <= 640
assert 'G.logo_box(28, 57, 140, 82, "splash")' in about
assert 28 + 252 * min(140 / 252, 82 / 170) < 168
assert 57 + 82 < 146
assert 'G.text_fit(T.f.h3, L("Siga nosso canal no Telegram")' in about
assert 'G.fit_lines(T.base_font(T.f.h2),title,w-94,42,true)' in about
assert 15 + 42 < 66  # fim do titulo antes do QR
print("HEADERS: OK - Matrix, Pulse, Sobre e titulo Telegram")
