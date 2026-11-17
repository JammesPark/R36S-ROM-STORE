import importlib.util
import pathlib
import tempfile
import unittest
from unittest.mock import patch

p = pathlib.Path("port/r36s-roms-store/bin/gamestore_source.py")
spec = importlib.util.spec_from_file_location("gamestore_source", p)
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)

class CatalogTests(unittest.TestCase):
    def test_platforms(self):
        self.assertEqual(source.category_name("genesis"), "megadrive")
        with self.assertRaises(ValueError): source.category_name("../../etc")
    def test_urls(self):
        self.assertEqual(source.safe_url("https://archive.org/test.zip"), "https://archive.org/test.zip")
        with self.assertRaises(ValueError): source.safe_url("http://127.0.0.1/test", allow_http=True)
        with self.assertRaises(ValueError): source.safe_url("file:///etc/passwd", allow_http=True)
    def test_metadata_fetch(self):
        with tempfile.TemporaryDirectory() as td:
            with patch.object(source, "STATE", td), patch.object(source, "status"):
                with patch.object(source, "load_api", return_value={
                    "success": True, "games": [
                        {"name": "Demo", "category": "genesis", "game_path": "roms/demo.zip"},
                        {"name": "Inseguro", "category": "ports", "game_path": "file:///etc/passwd"},
                    ], "page": 1, "total": 2, "total_pages": 2}):
                    source.games("ALL", 1)
                    d = __import__("json").loads((pathlib.Path(td) / "gamestore_games.json").read_text())
                    self.assertEqual(len(d["games"]), 1)
                    self.assertEqual(d["games"][0]["category"], "megadrive")
                    self.assertEqual(d["games"][0]["game_path"], "http://r36swiki.com/roms/demo.zip")
    def test_category_fetch(self):
        with tempfile.TemporaryDirectory() as td:
            with patch.object(source, "STATE", td), patch.object(source, "status"):
                with patch.object(source, "load_api", return_value={
                    "success": True, "categories": [
                        {"category": "ports", "count": 10},
                        {"category": "../../etc", "count": 2}]}):
                    source.categories()
                    d = __import__("json").loads((pathlib.Path(td) / "gamestore_categories.json").read_text())
                    self.assertEqual(len(d["categories"]), 2)

if __name__ == "__main__":
    unittest.main()
