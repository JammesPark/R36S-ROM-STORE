#!/usr/bin/env python3
"""Validate the complete package (not an OTA publication)."""
import hashlib, io, json, os, re, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read("update_manifest.json"))
    names=set(z.namelist())
    assert len(names) == len(z.infolist())
    assert len({f["path"] for f in manifest["files"]}) == len(manifest["files"])
    from pathlib import Path
    expected=re.search(r'C\.VERSION_NUM\s*=\s*"([^"]+)"',Path("src/config.lua").read_text()).group(1)
    assert manifest["version"]==expected
    assert manifest["type"]=="full"
    for f in manifest["files"]:
        name=f["path"]
        assert name in names
        data=z.read(name)
        assert len(data)==f["size"]
        assert hashlib.sha256(data).hexdigest()==f["sha256"]
    assert "R36S ROM STORE.sh" in names
    assert not any(n.startswith("r36sromsstore/") for n in names)
    for n in names:
        assert not n.startswith(("r36sromstore/conf/","r36sromstore/logs/","r36sromstore/backups/"))
        assert not n.endswith("/senhas.txt")
    with zipfile.ZipFile(io.BytesIO(z.read("r36sromstore/game.love"))) as game:
        config=game.read("config.lua").decode()
        assert re.search(r'C\.VERSION_NUM\s*=\s*"([^"]+)"',config).group(1)==expected
        flag = "false" if os.getenv("STORE_CHANNEL") == "official" else "true"
        edition = "Official" if flag == "false" else "Experimental"
        assert f'C.EDITION = "{edition}"' in config
        assert re.search(r'^C\.EXPERIMENTAL_NO_OTA\s*=\s*'+flag+r'\s*$',config,re.M)
        assert "/main/ota/rom-store/update.json" in config
        assert len([n for n in game.namelist() if n.startswith("assets/themegallery/") and n.endswith(".jpg")]) == 149
        for name in ("catalog/es_gallery_snapshot.json","catalog/es_theme_preview_index.json"):
            assert json.loads(game.read(name))
        assert not any(n.startswith("dev/") for n in game.namelist())
    print("PASS full candidate: manifest hashes, embedded version, channel, gallery and protected data")
