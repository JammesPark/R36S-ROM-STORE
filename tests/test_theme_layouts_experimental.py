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
