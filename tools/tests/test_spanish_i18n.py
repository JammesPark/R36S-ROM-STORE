#!/usr/bin/env python3
"""Valida dicionario e integracao do espanhol na R36SPORTSBR STORE."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAT = re.compile(r'^  \[("(?:\\.|[^"\\])*")\] = ("(?:\\.|[^"\\])*"),?$', re.M)
PRINTF = re.compile(r'%(?:[-+#0 ]*\d*(?:\.\d+)?)?[aAcdeEfgGiopsuxXq]')


def entries(path):
    content = (ROOT / path).read_text(encoding="utf-8")
    return [(json.loads(k), json.loads(v)) for k, v in PAT.findall(content)]


class SpanishTests(unittest.TestCase):
    def test_four_languages_and_flag(self):
        core = (ROOT / "game/lib/i18n.lua").read_text(encoding="utf-8")
        screen = (ROOT / "game/ui/screens/language.lua").read_text(encoding="utf-8")
        assert 'id = "es", name = "Español"' in core
        assert 'es = true' in core
        assert 'elseif id == "es"' in screen
        assert 'flag = "es"' in core
        assert 'for i, l in ipairs(I18N.LANGS)' in screen

    def test_spanish_dictionary_is_valid_and_translates_main_flows(self):
        rows = entries("game/i18n/es.lua")
        translations = dict(rows)
        self.assertEqual(len(rows), len(translations), "Chaves duplicadas")
        self.assertGreaterEqual(len(rows), 1200, "Traducoes principais ausentes")
        for key in ("Configurações", "Sobre o projeto", "AVISO IMPORTANTE",
                    "Idioma", "Downloads", "Meus Ports", "Licenças", "Baixando",
                    "Port já instalado", "Aparência e personalização", "Voltar"):
            self.assertIn(key, translations)
            self.assertNotEqual(translations[key], "", key)
        for k, v in rows:
            self.assertEqual(PRINTF.findall(k), PRINTF.findall(v),
                             f"Formatacao divergente: {k!r}")
            self.assertEqual(k.count("\\n"), v.count("\\n"),
                             f"Novas linhas divergentes: {k!r}")

    def test_legacy_languages_and_catalog_still_supported(self):
        core = (ROOT / "game/lib/i18n.lua").read_text(encoding="utf-8")
        catalog = (ROOT / "game/core/catalog.lua").read_text(encoding="utf-8")
        self.assertIn('["pt-BR"] = true, en = true, es = true, ru = true', core)
        self.assertIn('for _, lang in ipairs({ "en", "es", "ru" })', catalog)
        self.assertTrue((ROOT / "game/i18n/en.lua").is_file())
        self.assertTrue((ROOT / "game/i18n/ru.lua").is_file())
        self.assertIn('Idioma de todo o aplicativo: Português (Brasil), English, Español e Русский',
                      (ROOT / "game/ui/settings_extra.lua").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
