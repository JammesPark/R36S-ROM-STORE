#!/usr/bin/env python3
"""Regressoes: vitrine/Top 5 sem texto em capas e licencas somente leitura."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]

class RequestedUICleanupTests(unittest.TestCase):
    def test_force_slide_is_cover_only(self):
        src = (ROOT / "game/ui/force_dash.lua").read_text(encoding="utf-8")
        slide = src.split("local function recent_slide(self,P)", 1)[1].split(
            "local function force_star", 1)[0]
        self.assertIn("Covers.get(p)", slide)
        self.assertNotIn("ADICIONADO AO CATÁLOGO", slide)
        self.assertNotIn("LANÇAMENTO FUTURO", slide)
        self.assertNotIn("p.name", slide)
        self.assertNotIn("fmt_date(item.date)", slide)

    def test_top5_keeps_rank_and_count_without_title(self):
        src = (ROOT / "game/ui/force_dash.lua").read_text(encoding="utf-8")
        section = src.split("local function top(self,P,templ)", 1)[1].split(
            "local function tiles", 1)[0]
        self.assertIn("cover(p", section)
        self.assertIn("item.downloads", section)
        self.assertNotIn("p.name", section)
        self.assertNotIn("wrap_text(p.name", section)

    def test_licenses_read_only_and_back(self):
        defs = (ROOT / "game/ui/settings_extra.lua").read_text(encoding="utf-8")
        lic = defs.split('label = L("Licenças")', 1)[1].split(
            'label = L("Aviso importante")', 1)[0]
        self.assertIn('App.push("licenses")', lic)
        self.assertNotIn('App.push("files"', lic)
        main = (ROOT / "game/main.lua").read_text(encoding="utf-8")
        self.assertIn('"licenses"', main)
        page = (ROOT / "game/ui/screens/licenses.lua").read_text(encoding="utf-8")
        self.assertIn('local Base = require("ui.screens.infolist")', page)
        self.assertIn('action = Base.action', page)
        self.assertNotIn('App.push("files"', page)
        for name in ("GPL-3.0", "7-Zip", "LÖVE", "LuaQRCode", "Inter",
                     "Chakra Petch", "Press Start 2P", "NOTICE.md"):
            self.assertIn(name, page)
        infolist = (ROOT / "game/ui/screens/infolist.lua").read_text(encoding="utf-8")
        self.assertIn('if act == "b" then App.pop(); return end', infolist)

    def test_force_template_has_no_fake_labels(self):
        from pathlib import Path
        for theme in ("jedi", "sith"):
            source = (ROOT / "design/force-v4" / (theme + "-v4.html")).read_text(encoding="utf-8")
            self.assertNotIn('<div class="feature-info">', source)
            self.assertNotIn('<span class="port-label">${p.title}</span>', source)
        renderer = (ROOT / "tools/render_force_v4.py").read_text(encoding="utf-8")
        self.assertIn(".feature-info,.release-badge,.recent-card .port-label{display:none!important}", renderer)

    def test_boot_must_match_installed_version(self):
        source = (ROOT / "game/core/updater/manager.lua").read_text(encoding="utf-8")
        self.assertIn('require("core.updater.rules").compare(tostring(j.to), C.VERSION_NUM) ~= 0', source)
        self.assertNotIn('tostring(j.to) ~= C.VERSION_NUM', source)
        self.assertIn('Backup.journal_clear(C.APP_DIR)', source)

if __name__ == "__main__":
    unittest.main()
