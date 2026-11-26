#!/usr/bin/env python3
"""Assegura que a edicao Experimental nao consulte a API de jogos anterior."""
from pathlib import Path

root = Path("src")
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
config = (root / "config.lua").read_text(encoding="utf-8")
if 'C.EDITION = "Official"' in config:
    assert 'C.UPDATE_URL = "https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE-UPDATES/main/ota/rom-store/update.json"' in config
else:
    assert 'C.UPDATE_URL = ""' in config or (
        'C.EXPERIMENTAL_NO_OTA = true' in config
        and 'if C.EXPERIMENTAL_NO_OTA then return nil end' in (root / "core/update.lua").read_text(encoding="utf-8")
    )
print("CATALOGO: OK - API antiga inacessivel, fonte propria e OTA conforme canal")
