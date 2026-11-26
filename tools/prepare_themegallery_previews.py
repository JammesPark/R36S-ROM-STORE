#!/usr/bin/env python3
"""Prepare licensed ThemeGallery preview images from a pinned upstream checkout.
No theme executable or ROM is copied; only numbered screenshots.
"""
import json
import re
import sys
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
upstream = Path(sys.argv[1]).resolve()
rows = json.loads((root / "src/catalog/themegallery_metadata.json").read_text(encoding="utf-8"))
count = 0
for row in rows:
    sources, targets = row["preview_sources"], row["previews"]
    assert 1 <= len(sources) == len(targets) <= 3
    for source, target in zip(sources, targets):
        assert re.fullmatch(r"assets/Images/[A-Za-z0-9_.-]+/[0-9]+\.(?:webp|png|jpg|jpeg)", source, re.I)
        assert re.fullmatch(r"assets/themegallery/[A-Za-z0-9_.-]+/[0-9]+\.jpg", target)
        src = upstream / source
        dst = root / "src" / target
        dst.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(src) as im:
            im.load()
            im = im.convert("RGB")
            im.thumbnail((640,480), Image.Resampling.LANCZOS)
            im.save(dst, "JPEG", quality=88, optimize=True, progressive=False)
        with Image.open(dst) as im:
            im.verify()
        count += 1
assert len(rows) == 53 and count == 149
print(f"PASS {len(rows)} themes, {count} validated JPEG previews")
