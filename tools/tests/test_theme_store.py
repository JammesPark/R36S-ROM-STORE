"""Testes estaticos: novo catalogo de temas e padrao Jedi sem perder temas legados."""
import json
import re
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
class TestThemeStore(unittest.TestCase):
    def test_force_themes_distinct(self):
        jedi=json.loads((ROOT/"theme_packages/forcejedi/theme.json").read_text())
        sith=json.loads((ROOT/"theme_packages/forcesith/theme.json").read_text())
        assert jedi["id"]=="forcejedi" and sith["id"]=="forcesith"
        assert jedi["style"]["layout"]==sith["style"]["layout"]=="force"
        for entry in (jedi,sith):
            self.assertEqual(len(entry["colors"]),16)
            self.assertTrue(all(re.fullmatch(r"#[0-9a-fA-F]{6,8}",v) for v in entry["colors"].values()))
    def test_preserves_default_and_neongrid(self):
        themes=(ROOT/"game/core/themes.lua").read_text()
        self.assertIn('M.FIRST = "forcejedi"', themes)
        self.assertIn('DEFAULT = "forcejedi"', themes)
        for n in ("neongrid","pastel","wiiblue","default"):
            bundled=ROOT/f"game/themes/{n}/theme.json"
            optional=ROOT/f"theme_packages/{n}/theme.json"
            # No Git os binarios de origem seguem sob game/themes;
            # durante o build sao movidos ao catalogo opcional.
            self.assertTrue(bundled.exists() or optional.exists(),n)
            location=optional if optional.exists() else bundled
            self.assertIn("Lag do Lira",json.loads(location.read_text())["author"])
            if (ROOT/"game/themes/forcesith/theme.json").exists():
                self.assertFalse(bundled.exists(),n)
    def test_no_remote_code_execution(self):
        t=(ROOT/"game/threads/theme_store_thread.lua").read_text()
        self.assertIn('sha256sum',t)
        self.assertIn('ZIP com nomes inseguros',t)
        self.assertIn('link simbólico',t)
        self.assertNotIn('dofile(',t)
if __name__=="__main__": unittest.main()
