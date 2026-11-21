#!/usr/bin/env python3
"""Assegura que a edicao Experimental nao consulte a API de jogos anterior."""
from pathlib import Path

root = Path("game")
for path in root.rglob("*.lua"):
    data = path.read_text(encoding="utf-8")
    assert "getgames.php" not in data, f"Endpoint antigo no runtime: {path}"

catalog = (root / "core/catalog.lua").read_text(encoding="utf-8")
assert 'function Catalog.provider() return "r36s_own" end' in catalog
assert "Prefs.set(PROVIDER_KEY" not in catalog
assert "catalogo_proprio.zlib" in (root / "core/own_source.lua").read_text(encoding="utf-8")
assert "core.rom_source" not in (root / "main.lua").read_text(encoding="utf-8")
assert "core.rom_source" not in (root / "ui/screens/store.lua").read_text(encoding="utf-8")
assert "core.rom_source" not in (root / "ui/screens/search.lua").read_text(encoding="utf-8")
assert 'C.UPDATE_URL = ""' in (root / "config.lua").read_text(encoding="utf-8")
print("CATALOGO OFFLINE: OK - API antiga inacessivel, fonte local unica e OTA desligada")
