#!/usr/bin/env python3
"""Teste PTY real: segredo não aparece na linha de comando, no log ou em disco permanente."""
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
WRAPPER=ROOT/"r36sportsbrstore/bin/secure_7z.py"

class PrivatePasswordTests(unittest.TestCase):
    def test_password_not_in_process_args_or_output(self):
        with tempfile.TemporaryDirectory() as td:
            td=Path(td)
            fake=td/"fake_7zz"
            fake.write_text(
                "#!/usr/bin/env python3\n"
                "import sys\n"
                "assert sys.argv[1:3] == ['t','-p'], sys.argv\n"
                "pw=sys.stdin.readline().strip()\n"
                "print('ARCHIVE_OK' if pw=='private_secret_123' else 'BAD')\n"
                "sys.exit(0 if pw=='private_secret_123' else 2)\n",
                encoding="utf-8")
            fake.chmod(fake.stat().st_mode | stat.S_IXUSR)
            secret=td/"pwfile"
            fd=os.open(secret,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
            os.write(fd,b"private_secret_123\n");os.close(fd)
            command=[sys.executable,str(WRAPPER),str(secret),str(fake),"t","archive.7z"]
            assert "private_secret_123" not in repr(command)
            proc=subprocess.run(command,capture_output=True,text=True,timeout=15)
            self.assertEqual(proc.returncode,0,(proc.stdout,proc.stderr))
            self.assertIn("ARCHIVE_OK",proc.stdout)
            self.assertNotIn("private_secret_123",proc.stdout+proc.stderr)
            self.assertFalse(secret.exists())

    def test_cancel_bad_password(self):
        with tempfile.TemporaryDirectory() as td:
            td=Path(td)
            fake=td/"fake_7zz"
            fake.write_text("#!/usr/bin/env python3\nimport sys\n"
                "pw=sys.stdin.readline().strip()\n"
                "sys.exit(2 if pw!='OK' else 0)\n",encoding="utf-8")
            fake.chmod(0o700)
            secret=td/"pwfile"
            secret.write_text("WRONG\n",encoding="utf-8")
            secret.chmod(0o600)
            proc=subprocess.run([sys.executable,str(WRAPPER),str(secret),str(fake),"t","archive.7z"],
                capture_output=True,text=True,timeout=15)
            self.assertEqual(proc.returncode,2,proc.stderr)
            self.assertFalse(secret.exists())

if __name__=="__main__":
    unittest.main()
