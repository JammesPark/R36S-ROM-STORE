#!/usr/bin/env python3
"""Gera feed do R36S ROMS STORE só após validar UPDATE, instalador e fonte."""
import argparse
import hashlib
import importlib.util
import json
import re
import zipfile
from pathlib import Path

PUBLIC="JammesPark/R36S-ROMS-STORE-UPDATES"
def sha(path):
 h=hashlib.sha256()
 with path.open("rb") as f:
  for chunk in iter(lambda:f.read(65536),b""):
   h.update(chunk)
 return h.hexdigest()

def make(version,update,installer,source,notes):
 if not re.fullmatch(r"\d+\.\d+\.\d+(?:-beta)?",version):
  raise ValueError("Versão inválida")
 spec=importlib.util.spec_from_file_location("store_updater",Path(__file__).resolve().parents[1]/"port/r36s-roms-store/bin/store_updater.py")
 module=importlib.util.module_from_spec(spec)
 spec.loader.exec_module(module)
 module.safe_zip(update,version)
 for f in (installer,source):
  with zipfile.ZipFile(f) as z:
   if z.testzip(): raise ValueError("ZIP corrompido")
 with zipfile.ZipFile(installer) as z:
  if z.read("r36s-roms-store/VERSION").decode().strip()!=version:
   raise ValueError("Versão do instalador divergente")
 with zipfile.ZipFile(source) as z:
  if z.read("VERSION").decode().strip()!=version:
   raise ValueError("Versão da fonte divergente")
 base="https://github.com/"+PUBLIC+"/releases/download/roms-v"+version+"/"
 info={
  "app":"r36s-roms-store","channel":"beta","status":"published","version":version,
  "url":base+update.name,"sha256":sha(update),"size":update.stat().st_size,
  "notes":notes,"installer_url":base+installer.name,"installer_sha256":sha(installer),
  "source_url":base+source.name,"source_sha256":sha(source),
 }
 if info["url"]!=module.expected_url(version):
  raise ValueError("Nome/URL do pacote UPDATE não corresponde à versão")
 return info

if __name__=="__main__":
 ap=argparse.ArgumentParser()
 ap.add_argument("--version",required=True)
 ap.add_argument("--update",type=Path,required=True)
 ap.add_argument("--installer",type=Path,required=True)
 ap.add_argument("--source",type=Path,required=True)
 ap.add_argument("--out",type=Path,required=True)
 ap.add_argument("--notes-file",type=Path,required=True)
 a=ap.parse_args()
 data=make(a.version,a.update,a.installer,a.source,a.notes_file.read_text(encoding="utf-8")[:3200])
 a.out.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
 print("Feed válido:",a.out, "SHA:",data["sha256"])
