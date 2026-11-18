#!/usr/bin/env python3
"""Regressões do updater: canal isolado, hashes, instalação, rollback e dados."""
import importlib.util
import io
import json
import shutil
import tempfile
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def load_module(name,path):
 spec=importlib.util.spec_from_file_location(name,path)
 mod=importlib.util.module_from_spec(spec)
 spec.loader.exec_module(mod)
 return mod
U=load_module("store_updater",ROOT/"port/r36s-roms-store/bin/store_updater.py")
B=load_module("make_roms_update",ROOT/"tools/make_roms_update.py")

def make_love(version):
 b=io.BytesIO()
 with zipfile.ZipFile(b,"w") as z:
  z.writestr("VERSION",version+"\n")
  z.writestr("main.lua","-- teste "+version)
 return b.getvalue()

with tempfile.TemporaryDirectory() as td:
 root=Path(td)/"roms"/"ports"
 app=root/U.APP_ID
 app.mkdir(parents=True)
 old="0.2.16-beta"
 new="0.3.0-beta"
 launcher=root/"R36S ROMS STORE.sh"
 launcher.write_text("launcher antigo")
 (app/"VERSION").write_text(old+"\n")
 (app/"game.love").write_bytes(make_love(old))
 (app/"bin").mkdir()
 (app/"bin/gamestore_source.py").write_text("base antiga")
 (app/"LICENSE").write_text("licença")
 (app/"THIRD_PARTY_NOTICES.txt").write_text("avisos")
 user_data=app/"state/roms_favorites.json"
 user_data.parent.mkdir()
 user_data.write_text('[{"name":"Favorito"}]',encoding="utf-8")
 source=root/"install.zip"
 with zipfile.ZipFile(source,"w") as z:
  for rel in sorted(U.ALLOWED):
   data=make_love(new) if rel.endswith("game.love") else ((new+"\n").encode() if rel.endswith("VERSION") else ("nova versão "+rel).encode())
   z.writestr(rel,data)
 update=root/"update.zip"
 B.make(source,update,new)
 assert U.safe_zip(update,new)
 with zipfile.ZipFile(update) as z:
  m=json.loads(z.read("update_manifest.json"))
  assert m["app"]=="r36s-roms-store"
  assert len(m["files"])==len(U.ALLOWED)
 updater=U.Updater(app)
 updater.work.mkdir(parents=True)
 final=updater.work/("R36S_ROMS_STORE_v"+new+"_UPDATE.zip")
 shutil.copy2(update,final)
 sha=U.filehash(final)
 updater.publish("ready",version=new,sha256=sha,size=final.stat().st_size,filename=final.name)
 updater.request_apply()
 assert updater.apply()
 assert (app/"VERSION").read_text().strip()==new
 assert updater.pending.is_file()
 assert user_data.read_text(encoding="utf-8")=='[{"name":"Favorito"}]'
 assert updater.rollback()
 assert (app/"VERSION").read_text().strip()==old
 assert launcher.read_text()=="launcher antigo"
 assert user_data.read_text(encoding="utf-8")=='[{"name":"Favorito"}]'
 # Confirmar impede rollback quando a nova versão abre normalmente.
 updater.publish("ready",version=new,sha256=sha,size=final.stat().st_size,filename=final.name)
 updater.request_apply()
 assert updater.apply()
 assert updater.confirm()
 assert not updater.pending.exists()
 assert (app/"VERSION").read_text().strip()==new
 assert user_data.read_text(encoding="utf-8")=='[{"name":"Favorito"}]'
 # Repositório antigo não pode servir updates para a nova loja.
 try:
  U.validate_feed({"status":"published","channel":"beta","app":"r36sportsbrstore",
   "version":"0.4.0-beta","url":U.expected_url("0.4.0-beta"),"sha256":sha,"size":500},new)
  raise AssertionError("Identidade errada aceita")
 except ValueError:
  pass
 info={"status":"published","channel":"beta","app":U.APP_ID,"version":"0.3.1-beta",
   "url":U.expected_url("0.3.1-beta"),"sha256":sha,"size":400,"notes":"Novidades"}
 assert U.validate_feed(info,new)["version"]=="0.3.1-beta"
 info["url"]="https://exemplo.invalid/rom.zip"
 try:
  U.validate_feed(info,new)
  raise AssertionError("URL não autorizada")
 except ValueError:
  pass
 # ZIP alterado não pode ser instalado.
 broken=root/"broken.zip"
 with zipfile.ZipFile(broken,"w") as z:
  z.writestr("update_manifest.json",'{"app":"r36s-roms-store","version":"0.3.0-beta","files":[]}')
  z.writestr("../dados_do_usuario","nao")
 try:
  U.safe_zip(broken,new)
  raise AssertionError("Arquivo fora da whitelist aceito")
 except ValueError:
  pass
print("STORE UPDATER: versão, pacote, SHA, isolamento, backup, rollback e persistência: OK")
