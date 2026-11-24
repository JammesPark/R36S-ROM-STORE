"""Garante fidelidade de estrutura dos temas Force Nexus ao HTML V4 aprovado."""
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
class ForceV4Tests(unittest.TestCase):
    def test_source_html_kept_for_both(self):
        for side in ("jedi","sith"):
            src=(ROOT/"docs"/"design"/"force-v4"/(side+"-v4.html")).read_text(encoding="utf-8")
            for part in ('class="vertical-carousel"','class="recent-panel"',
                         'class="tile-grid"','TOP 5 DOWNLOADS',
                         'NOVOS','EM BREVE','class="release-switch"'):
                self.assertIn(part,src)
            self.assertEqual(src.count('class="tile'),7)  # 1 grid + 6 buttons
            self.assertNotIn('<h2 class="page-title">INÍCIO</h2>',src)
            self.assertNotIn('class="section-counter"',src)
            self.assertIn('top:58px;left:208px;width:418px;height:174px;',src)
            self.assertIn('top:242px;left:208px;width:418px;height:188px;',src)
            self.assertIn('grid-template-rows:repeat(2,84px);gap:6px',src)
            self.assertIn('#stage .recent-card{height:134px}',src)
            self.assertNotIn('id="carouselCount"',src)
            self.assertNotIn('id="prev"',src)
            self.assertNotIn('id="next"',src)
            self.assertIn('R36S PORTS BR STORE HUB',src)
            self.assertIn('EDITION · v1.0.12',src)
            self.assertIn('m12 2.4 3 6.1 6.8 1',src)
            self.assertIn('#stage .left .short-label{margin-top:0;margin-bottom:6px}',src)
            self.assertIn('#stage .left .quicklinks{gap:4px}',src)

    def test_force_dash_has_no_highlight_hero(self):
        lua=(ROOT/"src/ui/force_dash.lua").read_text(encoding="utf-8")
        self.assertNotIn("draw_hero",lua)
        self.assertNotIn('"EM DESTAQUE"',lua)
        self.assertNotIn('txt(L("INÍCIO")',lua)
        self.assertNotIn('txt("LAYOUT 640×480"',lua)
        self.assertIn('panel(208,242,418,188',lua)
        self.assertIn('local x,y,w,h=219+(i-1)*80,274,78,134',lua)
        self.assertIn('{"novos","NOVOS"}',lua)
        self.assertNotIn('local label=soon and "EM BREVE" or "NOVO"',lua)
        self.assertNotIn('txt(string.format("%02d / %02d"',lua)
        self.assertIn('G.rect(x,312,bar_w,4',lua)
        self.assertIn('local x,y=208+col*141,58+row*90',lua)
        self.assertIn('135,84,405,168',lua)
        self.assertNotIn('fn_zone="hero"',lua)
        self.assertIn('self.fn_zone=self.fn_zone or "tiles"',lua)
        self.assertIn("background_v4.png",lua)
        self.assertIn("selected_tiles_v4.png",lua)
        self.assertIn("Stats.get_top",lua)
        self.assertIn("Covers.get",lua)
        self.assertIn('local ForceFeed=require("core.force_feed")',lua)
        self.assertIn('self.fn_tab=="breve"',lua)
        self.assertIn('feed_tabs(self,P)',lua)
        self.assertNotIn("PORT RECENTE ·",lua)
        self.assertIn('local x,y,w,h=26,346+(i-1)*27,160,23',lua)
        self.assertIn('local function force_star',lua)
        self.assertIn('R36S PORTS BR STORE HUB',lua)
        self.assertNotIn('{"←","→"}',lua)
        ranking=(ROOT/"src/ui/force_ranking.lua").read_text()
        self.assertIn('Covers.get(p)',ranking)
        self.assertIn('item.catalog==catalog',ranking)
        self.assertIn('G.cover',ranking)
        standard=(ROOT/"src/ui/screens/ranking.lua").read_text()
        self.assertIn('T.style.layout == "force"',standard)
        self.assertIn('ui.force_ranking',standard)
        # Regressao: a tela Force precisa retornar ANTES de G.header legado.
        # Caso contrario os dois nomes ficam sobrepostos.
        force_branch=standard.index('if T.style.layout == "force" and #list > 0 then')
        classic_header=standard.index('G.header(L("Top Downloads")')
        self.assertLess(force_branch,classic_header)
        self.assertEqual(standard.count('require("ui.force_ranking").draw('),1)
        self.assertEqual(standard.count('G.header(L("Top Downloads")'),1)
        custom_header=ranking.index('G.header(L("Central de Conteúdo")')
        custom_title=ranking.index('G.text_fit(T.f.h3,L("TOP 5 DOWNLOADS")')
        self.assertLess(custom_header,custom_title)

    def test_sith_and_jedi_independent_112(self):
        j=json.loads((ROOT/"src/themes/forcejedi/theme.json").read_text())
        for side in ("jedi","sith"):
            d=json.loads((ROOT/"theme_packages"/("force"+side)/"theme.json").read_text())
            self.assertEqual(d["id"],"force"+side)
            self.assertEqual(d["version"],"1.0.12")
            self.assertEqual(d["style"]["layout"],"force")
        self.assertEqual(j["version"],"1.0.12")
        themes=(ROOT/"src/core/themes.lua").read_text()
        self.assertIn('M.FIRST = "forcejedi"',themes)
        for preserved in ("default","wiiblue","neongrid","pastel"):
            old=ROOT/"src/themes"/preserved/"theme.json"
            optional=ROOT/"theme_packages"/preserved/"theme.json"
            self.assertTrue(old.exists() or optional.exists())
            if (ROOT/"src/themes/forcesith/theme.json").exists():
                self.assertFalse(old.exists(),preserved)
                self.assertTrue(optional.exists(),preserved)

    def test_official_logo_source_and_generator(self):
        source=ROOT/"tools"/"brand"/"logo_oficial_cloud.webp"
        gen=(ROOT/"tools"/"make_brand_logos.py").read_text(encoding="utf-8")
        self.assertTrue(source.is_file(), "Fonte de marca oficial ausente")
        self.assertGreater(source.stat().st_size,5000)
        self.assertIn('logo_oficial_cloud.webp',gen)
        self.assertIn('"logo_header.png": fit(logo, 140, 40',gen)
        self.assertIn('"logo_splash.png": fit(logo, 252, 170',gen)
        self.assertIn('"default", "neongrid", "wiiblue", "pastel", "forcejedi"',gen)
        self.assertIn('"forcejedi", "forcesith"',gen)
        render=(ROOT/"tools"/"render_force_v4.py").read_text(encoding="utf-8")
        self.assertIn("from make_brand_logos import main as build_brand",render)
        for side in ("jedi","sith"):
            html=(ROOT/"docs"/"design"/"force-v4"/(side+"-v4.html")).read_text(encoding="utf-8")
            self.assertIn("const LOGO_DATA = 'data:image/png;base64,",html)
            self.assertIn("EDITION · v1.0.12",html)

    def test_zip_whitelist_background_and_selected_tiles(self):
        for file in ("src/threads/theme_store_thread.lua","src/core/theme_store.lua"):
            text=(ROOT/file).read_text()
            self.assertIn("background_v4.png",text)
            self.assertIn("selected_tiles_v4.png",text)

if __name__=="__main__":unittest.main()
