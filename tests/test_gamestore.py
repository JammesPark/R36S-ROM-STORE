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
    def test_remote_search_all_pages(self):
        # A pesquisa usa a API remota, nao a primeira pagina local de ROMs.
        with tempfile.TemporaryDirectory() as td:
            with patch.object(source, "STATE", td), patch.object(source, "status"):
                with patch.object(source, "load_api", return_value={
                    "success": True, "total": 11, "total_pages": 2,
                    "games": [{"name":"Sonic da pagina 7", "category":"megadrive",
                               "game_path":"roms/sonic.zip"}]}) as api:
                    source.search_games("sonic", 2)
                    api.assert_called_once_with("search", search="sonic", page=2, limit=10)
                    data = __import__("json").loads((pathlib.Path(td)/"gamestore_search.json").read_text())
                    self.assertEqual(data["query"], "sonic")
                    self.assertEqual(data["page"], 2)
                    self.assertEqual(data["total_pages"], 2)
                    self.assertEqual(data["games"][0]["name"], "Sonic da pagina 7")
                with self.assertRaises(ValueError):
                    source.search_games("x", 1)
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
