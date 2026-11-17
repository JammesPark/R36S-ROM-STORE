"""Testes isolados: exclusao controlada, detecao de duplicatas e sobrescrita."""
import hashlib
import importlib.util
import io
import json
import pathlib
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

module_path = pathlib.Path('port/r36s-roms-store/bin/gamestore_source.py')
spec = importlib.util.spec_from_file_location('gamestore_v029', module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

class Response(io.BytesIO):
    def __init__(self, content):
        super().__init__(content)
        self.headers = {'Content-Length':str(len(content))}

class RomFileTests(unittest.TestCase):
    url = 'https://example.org/roms/sonic.zip'

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        self.state = self.root / 'state'
        self.state.mkdir()
        self.capture=[]
        self.patches=[patch.object(mod,'STATE',str(self.state)),
                      patch.object(mod,'target_root',return_value=str(self.root)),
                      patch.object(mod,'status',side_effect=lambda *a,**kw: self.capture.append((a,kw)))]
        for patcher in self.patches:
            patcher.start();self.addCleanup(patcher.stop)

    def simulate_download(self,payload,overwrite='0'):
        with patch.object(mod,'OPENER',SimpleNamespace(open=lambda *args,**kw:Response(payload))):
            mod.download(self.url,'snes','sd1','Sonic','',overwrite)

    def test_inspect_and_delete_registered_rom(self):
        mod.inspect_rom(self.url,'snes','sd1')
        self.assertFalse(self.capture[-1][1]['exists'])
        self.simulate_download(b'VALID_ROM_ABC')
        target=self.root/'snes'/'sonic.zip'
        self.assertTrue(target.is_file())
        records=json.loads((self.state/'roms_downloads.json').read_text())
        self.assertEqual(records[0]['sha256'],hashlib.sha256(b'VALID_ROM_ABC').hexdigest())
        mod.inspect_rom(self.url,'snes','sd1')
        self.assertTrue(self.capture[-1][1]['exists'])
        self.assertTrue(self.capture[-1][1]['managed'])
        mod.remove_rom(self.url,'snes','sd1','sonic.zip')
        self.assertFalse(target.exists())
        self.assertEqual(json.loads((self.state/'roms_downloads.json').read_text()),[])

    def test_duplicate_must_be_explicitly_confirmed(self):
        self.simulate_download(b'ORIGINAL_ROM')
        dest=self.root/'snes'/'sonic.zip'
        with self.assertRaisesRegex(ValueError, 'já existe'):
            self.simulate_download(b'NEW_ROM','0')
        self.assertEqual(dest.read_bytes(),b'ORIGINAL_ROM')
        self.simulate_download(b'NEW_ROM','1')
        self.assertEqual(dest.read_bytes(),b'NEW_ROM')
        self.assertEqual(len(json.loads((self.state/'roms_downloads.json').read_text())),1)

    def test_never_delete_untracked_or_modified(self):
        dest=self.root/'snes'/'sonic.zip'
        dest.parent.mkdir()
        dest.write_bytes(b'UNTRACKED')
        with self.assertRaisesRegex(ValueError,'gerenciada'):
            mod.remove_rom(self.url,'snes','sd1','sonic.zip')
        self.assertTrue(dest.exists())
        dest.unlink()
        self.simulate_download(b'GOOD_ROM')
        dest.write_bytes(b'EVIL_ROM') # same size: hash identifies modification
        with self.assertRaisesRegex(ValueError,'alterado'):
            mod.remove_rom(self.url,'snes','sd1','sonic.zip')
        self.assertTrue(dest.exists())
        self.assertEqual(dest.read_bytes(),b'EVIL_ROM')

    def test_prevent_symlink_and_other_files(self):
        p=self.root/'snes'
        p.mkdir()
        outside=self.root/'other.zip'
        outside.write_bytes(b'DO_NOT_DELETE')
        link=p/'sonic.zip'
        link.symlink_to(outside)
        with self.assertRaisesRegex(ValueError,'incompatível'):
            mod.inspect_rom(self.url,'snes','sd1')
        with self.assertRaises(ValueError):
            self.simulate_download(b'DATA','1')
        self.assertEqual(outside.read_bytes(),b'DO_NOT_DELETE')
        with self.assertRaises(ValueError):
            mod.remove_rom(self.url,'snes','sd1','../other.zip')

if __name__=='__main__':unittest.main()
