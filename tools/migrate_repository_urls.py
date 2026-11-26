#!/usr/bin/env python3
"""Update active repository links only, preserving original-author attribution."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
old = "R36S-ROMS-" + "HUB-STORE"
new = "R36S-ROM-STORE"
count = 0
for folder in ("src", "port", "tools", "tests", "docs"):
    for path in (root / folder).rglob("*"):
        if not path.is_file() or path.suffix not in {".lua", ".py", ".json", ".sh", ".md", ".txt", ".yml", ".html"}:
            continue
        if "preservacao" in path.parts or path.name in {"prepare_rom_store_identity.py", "migrate_repository_urls.py", "test_repository_urls.lua"}:
            continue
        if path.name.startswith("LICENSE"): continue
        try: text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError: continue
        updated = text.replace(old, new)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            count += 1
            print("URL migrated:", path.relative_to(root))
print(f"Updated {count} active files; original source attribution preserved")
