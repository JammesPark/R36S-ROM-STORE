"""Regressao: marcas oficiais nunca recortadas nem ampliadas fora da tela."""
import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
VARIANTS = {
    "logo_header.png": (140, 40),
    "logo_menu.png": (218, 74),
    "logo_about.png": (132, 62),
    "logo_splash.png": (252, 170),
}

class BrandLogoTests(unittest.TestCase):
    def test_full_width_official_logo_and_no_clipping(self):
        spec = importlib.util.spec_from_file_location(
            "brand_generator", ROOT/"tools"/"make_brand_logos.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root/"tools"/"brand").mkdir(parents=True)
            (root/"r36sportsbrstore").mkdir()
            shutil.copy2(ROOT/"tools"/"brand"/"logo_oficial_cloud.webp",
                         root/"tools"/"brand"/"logo_oficial_cloud.webp")
            images = mod.build(root)
            self.assertEqual(set(images), set(VARIANTS))
            for filename, size in VARIANTS.items():
                image = images[filename]
                self.assertEqual(image.size, size)
                self.assertEqual(image.mode, "RGBA")
                bbox = image.getchannel("A").getbbox()
                self.assertIsNotNone(bbox, filename)
                if filename=="logo_header.png":
                    self.assertGreaterEqual(bbox[2]-bbox[0], 115,
                        "Marca horizontal oficial precisa estar inteira, nao recortada")
                    self.assertGreaterEqual(bbox[3]-bbox[1], 32,
                        "Logo oficial pequena demais no cabecalho")
                    self.assertGreater((bbox[2]-bbox[0])/(bbox[3]-bbox[1]),3.1,
                        "Proporcao 3,36:1 da arte aprovada nao foi preservada")
                # O antigo header tinha bbox y=0..32, com halo visivelmente cortado.
                self.assertGreaterEqual(bbox[0], 2, filename)
                self.assertGreaterEqual(bbox[1], 2, filename)
                self.assertLessEqual(bbox[2], image.width-2, filename)
                self.assertLessEqual(bbox[3], image.height-2, filename)
                data = (root/"src"/"assets"/"logo"/filename).read_bytes()
                for theme in ("default","neongrid","wiiblue","pastel","forcejedi"):
                    self.assertEqual(data,
                        (root/"src"/"themes"/theme/filename).read_bytes())
                for theme in ("forcejedi","forcesith"):
                    self.assertEqual(data,
                        (root/"theme_packages"/theme/filename).read_bytes())
            launcher = Image.open(root/"r36sportsbrstore"/"logo.png")
            self.assertEqual(launcher.size, (128,128))
            bbox=launcher.getchannel("A").getbbox()
            self.assertTrue(4 <= bbox[0] < bbox[2] <= 124)
            self.assertTrue(4 <= bbox[1] < bbox[3] <= 124)
            self.assertFalse((root/"src"/"assets"/"logo"/"dev_logo.png").exists())

    def test_lua_prevents_theme_scaling_cuts(self):
        lua = (ROOT/"src"/"ui"/"gfx.lua").read_text(encoding="utf-8")
        self.assertIn('if variant == "header" then', lua)
        # A logo global tem que ser tentada ANTES da imagem do tema instalado.
        global_img=lua.index('"assets/logo/logo_" .. variant .. ".png"')
        theme_img=lua.index('dir .. "/logo_" .. variant .. ".png"')
        self.assertLess(global_img,theme_img)
        self.assertIn('pill and 4 or 1, "header"',lua)
        self.assertIn('local tx = math.max(190, (pill and 20 or 12) + lw + 30)',lua)
        self.assertIn('G.rect(tx - 12, 10, 1, 20',lua)
        self.assertGreaterEqual(190-(12+140*0.9),25)
        for path,marker in (
            ("src/ui/channels.lua","local name_x = math.max(190, 14 + lw + 30)"),
            ("src/ui/neon_dash.lua","local title_x = math.max(190, 12 + lw + 30)"),
            ("src/ui/xdash.lua","local title_x = math.max(190, 14 + lw + 30)"),
        ):
            self.assertIn(marker,(ROOT/path).read_text(encoding="utf-8"))
        force=(ROOT/"src/ui/force_dash.lua").read_text(encoding="utf-8")
        self.assertIn('G.logo(14,2,"header",1)',force)
        self.assertIn('local tx=math.max(196,14+(lw or 0)+32)',force)
        self.assertGreaterEqual(196-(14+140),22)
        self.assertNotIn('if not templ then\n    G.rect(0,0,640,46,P.header)',force)
        self.assertIn('(bottom - y - 2) / img:getHeight()', lua)
        self.assertIn('elseif variant == "menu" then', lua)
        self.assertIn('elseif variant == "about" then', lua)
        about=(ROOT/"src/ui/screens/about.lua").read_text(encoding="utf-8")
        self.assertIn('G.logo(26, 66, "about", 1.04)',about)
        self.assertLess(26+132*1.04,168)
        self.assertLess(66+62*1.04,146)
        flag=Image.open(ROOT/"tools/brand/logo_oficial_cloud.webp").convert("RGBA")
        alternative=Image.open(ROOT/"tools/brand/logo_alternativa_sem_bandeira.webp").convert("RGBA")
        self.assertGreater(flag.width,400)
        self.assertEqual(flag.getchannel("A").getextrema(),(0,255))
        self.assertNotEqual(flag.tobytes(),alternative.tobytes())
        self.assertIn('(84 - y) / img:getHeight()', lua)
        self.assertIn('elseif variant == "splash" then', lua)
        self.assertIn('(142 - y) / img:getHeight()', lua)
        # A logo completa 140x40 cabe na faixa generica de 40px.
        y, image_h = 1, 40
        scale = min(1.3, (39-y-2)/image_h)
        self.assertLess(y + image_h*scale, 40)
        # Menu: logo termina antes da versao que comeca em y=86.
        scale = min(1.5,(84-6)/74)
        self.assertLessEqual(6+74*scale,84)

    def test_force_preview_reuses_brand_header_asset(self):
        script=(ROOT/"tools"/"render_force_v4.py").read_text(encoding="utf-8")
        self.assertIn('ROOT/"src/assets/logo/logo_header.png"',script)
        self.assertIn('await logo.decode()',script)
        for side in ("jedi","sith"):
            html=(ROOT/"docs/design/force-v4"/(side+"-v4.html")).read_text(encoding="utf-8")
            self.assertIn('.brandlogo{width:140px;height:38px;',html)
            self.assertNotIn('filter:hue-rotate(239deg)',html)
            self.assertIn('.brand{margin-left:26px;',html)
            self.assertIn('EDITION · v1.0.12',html)

if __name__=="__main__":
    unittest.main()
