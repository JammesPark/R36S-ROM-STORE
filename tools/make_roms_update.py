#!/usr/bin/env python3
"""Gera pacote UPDATE apenas com arquivos da loja e hashes por arquivo."""
import argparse
import hashlib
import io
import json
import re
import stat
import zipfile
from pathlib import Path

APP="r36s-roms-store"
FILES=(
 "R36S ROMS STORE.sh",
 APP+"/game.love",
 APP+"/bin/gamestore_source.py",
 APP+"/bin/store_updater.py",
 APP+"/bin/bios_manager.py",
 APP+"/LICENSE",
 APP+"/THIRD_PARTY_NOTICES.txt",
 APP+"/VERSION",
)
def sha(content): return hashlib.sha256(content).hexdigest()

def make(installer, output, version):
 with zipfile.ZipFile(installer) as z:
  names=set(z.namelist())
  for f in FILES:
   if f not in names: raise ValueError("Arquivo ausente no instalador: "+f)
  if z.read(APP+"/VERSION").decode("utf-8").strip()!=version: raise ValueError("VERSION divergente")
  with zipfile.ZipFile(io.BytesIO(z.read(APP+"/game.love"))) as inner:
   if inner.read("VERSION").decode("utf-8").strip()!=version:
    raise ValueError("VERSION do LÖVE divergente")
  manifest={"app":APP,"version":version,"type":"full","files":[]}
  with zipfile.ZipFile(output,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as dest:
   for file in FILES:
    data=z.read(file)
    manifest["files"].append({"path":file,"size":len(data),"sha256":sha(data)})
    zi=zipfile.ZipInfo(file)
    zi.external_attr=((0o100755 if file.endswith(".sh") else 0o100644)<<16)
    dest.writestr(zi,data,compress_type=zipfile.ZIP_DEFLATED)
   dest.writestr("update_manifest.json",json.dumps(manifest,sort_keys=True,ensure_ascii=False))
 with zipfile.ZipFile(output) as z:
  if z.testzip(): raise ValueError("UPDATE inválido")
 return manifest

if __name__=="__main__":
 ap=argparse.ArgumentParser()
 ap.add_argument("--installer",type=Path,required=True)
 ap.add_argument("--out",type=Path,required=True)
 ap.add_argument("--version",required=True)
 a=ap.parse_args()
 if not re.fullmatch(r"\d+\.\d+\.\d+(?:-beta)?",a.version):
  raise SystemExit("VERSION inválido")
 manifest=make(a.installer,a.out,a.version)
 print("UPDATE gerado:",a.out,len(manifest["files"]),"arquivos")
