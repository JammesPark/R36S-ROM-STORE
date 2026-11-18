#!/usr/bin/env python3
"""Valida a versão única do projeto."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text(encoding="utf-8").strip()
assert re.fullmatch(r"\d+\.\d+\.\d+(?:-[a-z0-9]+(?:\.[a-z0-9]+)*)?", version), version
main = (root / "src/main.lua").read_text(encoding="utf-8")
build = (root / "tools/build.sh").read_text(encoding="utf-8")
workflow = (root / ".github/workflows/build.yml").read_text(encoding="utf-8")
readme = (root / "README.md").read_text(encoding="utf-8")
assert "love.filesystem.read,'VERSION'" in main
assert "txt('v'..appVersion()" in main
assert "cp VERSION src/VERSION" in build
assert "cp VERSION port/r36s-roms-store/VERSION" in build
assert "R36S_ROMS_STORE_v${VERSION}_TESTE.zip" in build
assert "R36S_ROMS_STORE_v${VERSION}_FONTE.zip" in build
assert "python3 tests/test_versioning.py" in workflow
assert "R36S_ROMS_STORE_v${VERSION}_TESTE.zip" in workflow
assert 'unzip -p "$tmp/game.love" VERSION' in workflow
assert "[VERSION](VERSION)" in readme
assert readme.splitlines()[0] == "# R36S ROMS STORE"
assert re.search(r"^## " + re.escape(version) + r"$", (root / "CHANGELOG.md").read_text(), re.M)
for content in (main, build, workflow):
    assert "v0.2.15" not in content, "Versão antiga fixa no código/build"
print("VERSION centralizado:", version)
