#!/usr/bin/env python3
"""Testes offline dos geradores da R36SPORTSBR STORE, sem tocar na loja ativa."""
import json
import hashlib
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"


def dtb_fixture():
    names = ["model", "compatible", "panel-init-sequence", "hactive", "vactive"]
    strings = b""
    offsets = {}
    for key in names:
        offsets[key] = len(strings)
        strings += key.encode() + b"\x00"

    def pad(raw):
        return raw + b"\x00" * ((-len(raw)) % 4)

    def begin(name):
        return struct.pack(">I", 1) + pad(name.encode() + b"\x00")

    def prop(name, data):
        return struct.pack(">III", 3, len(data), offsets[name]) + pad(data)

    end = struct.pack(">I", 2)
    st = (begin("") + prop("model", b"R36S-VTEST\x00")
          + prop("compatible", b"test,board\x00")
          + begin("panel@0")
          + prop("compatible", b"simple-panel-dsi\x00")
          + prop("panel-init-sequence", b"\x01\x02\x03\x04")
          + end
          + begin("display-timings") + begin("timing0")
          + prop("hactive", struct.pack(">I", 640))
          + prop("vactive", struct.pack(">I", 480))
          + end + end + end + struct.pack(">I", 9))
    reserve = b"\x00" * 16
    struct_off = 40 + len(reserve)
    strings_off = struct_off + len(st)
    header = struct.pack(">10I", 0xD00DFEED, strings_off + len(strings),
                         struct_off, strings_off, 40, 17, 16, 0,
                         len(strings), len(st))
    return header + reserve + st + strings


class GeneratorTests(unittest.TestCase):
    def run_script(self, script, *args, expect_ok=True):
        cmd = [sys.executable, str(TOOLS / script), *map(str, args)]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=45)
        if expect_ok and result.returncode:
            self.fail(f"{cmd}\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}")
        if not expect_ok:
            self.assertNotEqual(0, result.returncode, result.stderr)
        return result

    def test_dtbs_and_console_signatures(self):
        with tempfile.TemporaryDirectory() as folder:
            tmp = Path(folder)
            dk_dir = tmp / "dk"
            a4_dir = tmp / "a4"
            dk_path = dk_dir / "clone" / "R36S-VTEST" / "rk3326-r36s-linux.dtb"
            a4_path = a4_dir / "consoles" / "variant-test" / "rk3326-r36s-linux.dtb"
            dk_path.parent.mkdir(parents=True)
            a4_path.parent.mkdir(parents=True)
            dk_path.write_bytes(dtb_fixture())
            a4_path.write_bytes(dtb_fixture())

            dk_json, a4_json = tmp / "dk.json", tmp / "a4.json"
            self.run_script("fdt2.py", dk_dir, dk_json)
            self.run_script("fdt3.py", a4_dir / "consoles", a4_json)
            from_dk = json.loads(dk_json.read_text(encoding="utf-8"))
            from_a4 = json.loads(a4_json.read_text(encoding="utf-8"))
            self.assertEqual(from_dk[0]["res"], "640x480")
            self.assertEqual(from_a4[0]["res"], "640x480")
            self.assertEqual(from_dk[0]["init_sha1"],
                             hashlib.sha1(b"\x01\x02\x03\x04").hexdigest())

            ini = tmp / "r36_devices.ini"
            ini.write_text("[R36S-VTEST]\nvariant=clone\nresolution=640x480\n",
                           encoding="utf-8")
            output = tmp / "console_signatures.json"
            self.run_script("mkconsoledb.py", "--dk", dk_json,
                            "--a4", a4_json, "--ae", dk_json,
                            "--ini", ini, "--dk-commit", "testdk",
                            "--a4-commit", "testa4", "--ae-commit", "testae",
                            "--out", output)
            data = json.loads(output.read_text(encoding="utf-8"))
            self.assertGreaterEqual(len(data["boards"]), 2)
            self.assertEqual(data["reference"]["soc"], "rk3326")
            self.assertGreaterEqual(len(data["panels"]), 1)

            self.run_script("mkconsoledb.py", "--dk", dk_json,
                            "--a4", a4_json, "--ae", dk_json,
                            "--ini", ini, "--dk-commit", "testdk",
                            "--a4-commit", "testa4", "--ae-commit", "testae",
                            "--out", ROOT / "src/data/console_signatures.json",
                            expect_ok=False)

    def test_invalid_dtb_rejected(self):
        sys.path.insert(0, str(TOOLS))
        from fdtparse import parse
        with self.assertRaises(ValueError):
            parse(b"not a DTB")
        with self.assertRaises(ValueError):
            parse(dtb_fixture()[:12])

    def test_bios_database_is_generated_in_build(self):
        with tempfile.TemporaryDirectory() as folder:
            dst = Path(folder) / "bios_db.lua"
            self.run_script("mkbiosdb.py", "--source", ROOT / "tools/ref/System.dat",
                            "--out", dst, "--commit", "teste")
            source = dst.read_text(encoding="utf-8")
            self.assertIn("M.SYSTEMS", source)
            self.assertIn("M.LIST", source)
            self.assertGreater(source.count("{ n = "), 50)
            self.run_script("mkbiosdb.py", "--out", ROOT / "src/core/bios_db.lua",
                            expect_ok=False)

    def test_arts_are_generated_without_touching_existing_images(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as folder:
            self.run_script("mkart.py", "--out", folder)
            for file, resolution in [("cover.png", (640, 480)), ("fanart.png", (1280, 720))]:
                with Image.open(Path(folder) / file) as picture:
                    self.assertEqual(picture.size, resolution)
            self.run_script("mkart.py", "--out", ROOT / "r36sportsbrstore",
                            expect_ok=False)


if __name__ == "__main__":
    unittest.main()
