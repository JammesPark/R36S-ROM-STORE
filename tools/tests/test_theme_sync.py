"""QA: toda atualizacao geral da STORE inclui todos os temas internos e opcionais instalados."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ASSETS=("theme.json","preview.png","background_v4.png","selected_tiles_v4.png","logo_header.png")

class ThemeSyncTests(unittest.TestCase):
    def test_runtime_sync_only_installed_and_never_downgrades(self):
        lua=(ROOT/"src/core/themes.lua").read_text(encoding="utf-8")
        self.assertIn("local function sync_bundled_installed_themes()",lua)
        self.assertIn('if love.filesystem.getInfo(dst .. "/theme.json", "file") then',lua)
        self.assertIn('and newer_version(newest.version, current.version)',lua)
        self.assertIn('love.filesystem.write(dst .. "/theme.json", newdata)',lua)
        self.assertIn('sync_bundled_installed_themes()\n  M.list',lua)
        self.assertNotIn('love.filesystem.remove(dst)',lua)
        self.assertNotIn('love.filesystem.remove(M.USER_DIR)',lua)
        self.assertLess(lua.index('for _, name in ipairs(THEME_FILES)'),
                        lua.index('love.filesystem.write(dst .. "/theme.json", newdata)'))

    def test_general_update_includes_all_official_themes(self):
        workflow=(ROOT/".github/workflows/build.yml").read_text(encoding="utf-8")
        self.assertIn("python3 tools/bundle_theme_updates.py",workflow)
        self.assertIn("luajit tools/tests/test_theme_sync_runtime.lua",workflow)
        self.assertIn("python3 tools/tests/test_all_theme_layouts.py",workflow)
        self.assertIn("dist/qa_all_themes/*.png",workflow)
        self.assertIn("theme_updates/{th}/{name}",workflow)
        expected={"forcejedi":"1.0.12", "forcesith":"1.0.12"}
        for name,version in expected.items():
            manifest=ROOT/"src/themes"/name/"theme.json"
            if not manifest.exists(): manifest=ROOT/"theme_packages"/name/"theme.json"
            self.assertTrue(manifest.is_file(),name)
            meta=json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual(meta["id"],name)
            self.assertEqual(meta["version"],version)
            for asset in ("logo_header.png","logo_menu.png","logo_about.png","logo_splash.png"):
                self.assertTrue((manifest.parent/asset).exists(),(name,asset))
        for name in ("default","neongrid","wiiblue","pastel"):
            packaged=ROOT/"theme_packages"/name/"theme.json"
            original=ROOT/"src/themes"/name/"theme.json"
            manifest=packaged if packaged.exists() else original
            self.assertTrue(manifest.is_file(),name)
            meta=json.loads(manifest.read_text(encoding="utf-8"))
            self.assertIn("Lag do Lira",meta["author"],name)
            if (ROOT/"src/themes/forcesith/theme.json").exists():
                self.assertFalse(original.exists(),name)
                self.assertTrue(packaged.exists(),name)
                self.assertTrue((ROOT/"src/theme_updates"/name/"theme.json").exists(),name)
        for name in ("forcejedi","forcesith"):
            meta=json.loads((ROOT/"theme_packages"/name/"theme.json").read_text(encoding="utf-8"))
            self.assertEqual(meta["version"],"1.0.12")

    def test_bundle_supports_all_new_optional_themes_without_installing_them(self):
        spec=importlib.util.spec_from_file_location(
            "theme_bundle", ROOT/"tools"/"bundle_theme_updates.py")
        module=importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/"src/themes/forcejedi").mkdir(parents=True)
            (root/"src/themes/forcejedi/theme.json").write_text('{"id":"forcejedi"}')
            for name in ("forcejedi","forcesith","extraoptional"):
                folder=root/"theme_packages"/name
                folder.mkdir(parents=True)
                for filename in ASSETS:
                    if filename=="theme.json":
                        (folder/filename).write_text(json.dumps({"id":name,"version":"2.0.0"}))
                    else:
                        (folder/filename).write_bytes(("data-"+filename).encode())
            count=module.bundle(root)
            self.assertEqual(count,2)
            self.assertFalse((root/"src/theme_updates/forcejedi").exists())
            for name in ("forcesith","extraoptional"):
                for filename in ASSETS:
                    self.assertTrue((root/"src/theme_updates"/name/filename).is_file())
            self.assertFalse((root/"src/user_themes").exists())
            # Novo empacotamento nunca depende de uma versao antiga em cache.
            count=module.bundle(root)
            self.assertEqual(count,2)

if __name__=="__main__":
    unittest.main()
