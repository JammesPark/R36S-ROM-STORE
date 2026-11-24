#!/usr/bin/env python3
"""Testes offline do update incremental, ZIP completo e verificações SHA-256."""
import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
from make_release_update import create_update
from prepare_update_feed import create_feed

FILES = {
    "R36SPORTSBR STORE.sh": b"#!/bin/bash\n",
    "r36sportsbrstore/game.love": b"game original",
    "r36sportsbrstore/README.md": b"versao original",
    "r36sportsbrstore/cover.png": b"imagem invariavel",
}


def make_full(path, version, content):
    m = {
        "name": "R36SPORTSBR STORE",
        "version": version,
        "type": "full",
        "files": [{"path": name, "size": len(data),
                   "sha256": hashlib.sha256(data).hexdigest()}
                  for name, data in content.items()],
    }
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("update_manifest.json", json.dumps(m))
        for name, data in content.items():
            z.writestr(name, data)


def make_source(path, version):
    required = ["src/main.lua", "src/config.lua", "tools/mkart.py",
                "tools/make_update.py", "LICENSE", "NOTICE.md",
                "R36SPORTSBR STORE.sh", ".github/workflows/build.yml"]
    with zipfile.ZipFile(path, "w") as z:
        for name in required:
            data = ('C.VERSION_NUM = "' + version + '"\n') if name == "src/config.lua" else "teste"
            z.writestr(name, data)


class IncrementalTests(unittest.TestCase):
    def setUp(self):
        self.context = tempfile.TemporaryDirectory()
        self.dir = Path(self.context.name)
        self.old = self.dir / "R36SPORTSBR_STORE_0.0.7-beta.zip"
        self.new = self.dir / "R36SPORTSBR_STORE_0.0.8-beta.zip"
        self.update = self.dir / "R36SPORTSBR_STORE_0.0.8-beta_UPDATE.zip"
        self.source = self.dir / "R36SPORTSBR_STORE_0.0.8-beta_CODIGO_FONTE.zip"
        make_full(self.old, "0.0.7-beta", FILES)
        changed = dict(FILES)
        changed["r36sportsbrstore/game.love"] = b"game 0.0.8 novo"
        changed["r36sportsbrstore/README.md"] = b"README nova versao"
        make_full(self.new, "0.0.8-beta", changed)
        make_source(self.source, "0.0.8-beta")
        self.sha = hashlib.sha256(self.old.read_bytes()).hexdigest()

    def tearDown(self):
        self.context.cleanup()

    def generate(self, **kw):
        return create_update(
            self.new, self.update, "0.0.8-beta",
            baseline=self.old, base_version="0.0.7-beta",
            base_sha256=self.sha, **kw)

    def test_only_changed_game_love_and_manifest(self):
        m = self.generate()
        self.assertEqual(m["type"], "incremental")
        self.assertEqual(m["version"], "0.0.8")
        self.assertEqual(m["min_version"], "0.0.7")
        self.assertEqual(m["max_version"], "0.0.7")
        self.assertEqual([f["path"] for f in m["files"]], ["r36sportsbrstore/game.love"])
        with zipfile.ZipFile(self.update) as z:
            self.assertEqual(set(z.namelist()),
                             {"update_manifest.json", "r36sportsbrstore/game.love"})
            self.assertEqual(z.read("r36sportsbrstore/game.love"), b"game 0.0.8 novo")

    def test_feed_offers_cumulative_full_and_optional_incremental(self):
        self.generate()
        feed = create_feed(self.new, self.source, "0.0.8-beta",
                           update=self.update, base_version="0.0.7-beta")
        # Campos legados sao consumidos por clientes 0.0.10 e anteriores.
        self.assertTrue(feed["url"].endswith("0.0.8-beta.zip"))
        self.assertEqual(feed["sha256"], hashlib.sha256(self.new.read_bytes()).hexdigest())
        self.assertEqual(feed["size"], self.new.stat().st_size)
        self.assertNotIn("min_version", feed)
        self.assertNotIn("max_version", feed)
        # Clientes novos economizam bytes quando a versao-base for compativel.
        self.assertTrue(feed["incremental_url"].endswith("_UPDATE.zip"))
        self.assertEqual(feed["incremental_sha256"],
                         hashlib.sha256(self.update.read_bytes()).hexdigest())
        self.assertEqual(feed["incremental_min_version"], "0.0.7")
        self.assertEqual(feed["incremental_max_version"], "0.0.7")
        self.assertTrue(feed["full_url"].endswith("0.0.8-beta.zip"))
        self.assertTrue(feed["source_url"].endswith("_CODIGO_FONTE.zip"))
        with self.assertRaisesRegex(ValueError, "exige versão-base"):
            create_feed(self.new, self.source, "0.0.8-beta", update=self.update)

    def test_full_update_fallback_can_skip_any_version(self):
        bridge = self.dir / "R36SPORTSBR_STORE_0.0.8-beta_UPDATE_FULL.zip"
        full = create_update(self.new, bridge, "0.0.8-beta")
        self.assertEqual(full["type"], "full")
        self.assertEqual(full["version"], "0.0.8")
        self.assertEqual(full["version_label"], "0.0.8-beta")
        self.assertNotIn("min_version", full)
        self.assertNotIn("max_version", full)
        with zipfile.ZipFile(bridge) as archive:
            self.assertEqual(
                set(archive.namelist()),
                set(FILES) | {"update_manifest.json"})
            self.assertEqual(
                {entry["path"] for entry in full["files"]}, set(FILES))
            self.assertFalse(any(x in archive.namelist()
                                 for x in ("LICENSE", "NOTICE.md", "CHANGELOG.md")))
        # Uma base 0.0.7 recebe o incremental, mas clientes 0.0.4,
        # 0.0.5, 0.0.6 nao devem tentar encadear as versoes intermediarias.
        self.generate()
        feed = create_feed(self.new, self.source, "0.0.8-beta",
                           update=self.update, base_version="0.0.7-beta",
                           full_update=bridge)
        self.assertTrue(feed["url"].endswith("0.0.8-beta.zip"))
        self.assertTrue(feed["full_url"].endswith("_UPDATE_FULL.zip"))
        self.assertEqual(feed["full_sha256"], hashlib.sha256(bridge.read_bytes()).hexdigest())
        self.assertEqual(feed["full_size"], bridge.stat().st_size)
        self.assertEqual(feed["incremental_min_version"], "0.0.7")
        self.assertEqual(feed["incremental_max_version"], "0.0.7")

    def test_full_fallback_rejects_tampered_bundle(self):
        bridge = self.dir / "R36SPORTSBR_STORE_0.0.8-beta_UPDATE_FULL.zip"
        create_update(self.new, bridge, "0.0.8-beta")
        with zipfile.ZipFile(bridge, "a") as z:
            z.writestr("README.md", "arquivo inesperado")
        self.generate()
        with self.assertRaisesRegex(ValueError, "arquivos extras"):
            create_feed(self.new, self.source, "0.0.8-beta",
                        update=self.update, base_version="0.0.7-beta",
                        full_update=bridge)

    def test_full_feed_works_without_incremental(self):
        feed = create_feed(self.new, self.source, "0.0.8-beta")
        self.assertTrue(feed["url"].endswith("0.0.8-beta.zip"))
        self.assertNotIn("incremental_url", feed)
        self.assertNotIn("min_version", feed)

    def test_bad_base_sha256_is_rejected_without_writing_output(self):
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            create_update(self.new, self.update, "0.0.8-beta", baseline=self.old,
                          base_version="0.0.7-beta", base_sha256="0"*64)
        self.assertFalse(self.update.exists())

    def test_unchanged_game_love_does_not_publish_documentation_only(self):
        unchanged = dict(FILES)
        unchanged["r36sportsbrstore/README.md"] = b"README 0.0.8"
        make_full(self.new, "0.0.8-beta", unchanged)
        with self.assertRaisesRegex(ValueError, "Nenhum arquivo instalável alterado"):
            self.generate()

    def test_missing_old_file_requires_full_installer(self):
        changed = dict(FILES)
        changed.pop("r36sportsbrstore/cover.png")
        changed["r36sportsbrstore/game.love"] = b"novo"
        make_full(self.new, "0.0.8-beta", changed)
        with self.assertRaisesRegex(ValueError, "instalador completo"):
            self.generate()

    def test_missing_sha_base_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            create_update(self.new, self.update, "0.0.8-beta",
                          baseline=self.old, base_version="0.0.7-beta")

if __name__ == "__main__":
    unittest.main()
