#!/usr/bin/env python3
"""Prepare the new-layout OTA and feed alongside a reviewed full installer."""
import hashlib
import io
import json
import re
import sys
import shutil
from pathlib import Path
from zipfile import ZipFile

def sha(data):
    return hashlib.sha256(data).hexdigest()

def stage(installer, out):
    out.mkdir(parents=True, exist_ok=True)
    with ZipFile(installer) as src:
        manifest = json.loads(src.read("update_manifest.json"))
        version = manifest["version"]
        if not re.fullmatch(r"\d+\.\d+\.\d+(?:-beta)?",version) or manifest["type"] != "full":
            raise ValueError("Manifesto de instalação inválido")
        archive_name = f"R36S_ROM_STORE_{version}_OTA.zip"
        with ZipFile(io.BytesIO(src.read("r36sromstore/game.love"))) as game:
            config = game.read("config.lua").decode()
        if not re.search(r"^C\.EXPERIMENTAL_NO_OTA\s*=\s*false\s*$", config, re.M) or "/main/ota/rom-store/update.json" not in config:
            raise ValueError("O pacote precisa usar o canal oficial da nova pasta")
        validated = set()
        with ZipFile(out/archive_name, "w") as target:
            for item in manifest["files"]:
                path = item["path"]
                parts = path.split("/")
                if path != "R36S ROM STORE.sh" and (len(parts) < 2 or parts[0] != "r36sromstore" or parts[1] in {"conf","logs","tmp","backups","gravacoes","bios","update","senhas.txt","catalog.json","catalog_url.txt","update_url.txt","bios_url.txt"}):
                    raise ValueError("Caminho fora do pacote oficial")
                if path in validated or any(p in {"",".",".."} for p in parts) or "\\" in path:
                    raise ValueError("Nome de arquivo inválido ou duplicado")
                validated.add(path)
                data = src.read(path)
                if len(data) != item["size"] or sha(data) != item["sha256"]:
                    raise ValueError("Arquivo diverge do manifesto")
            if not {"R36S ROM STORE.sh","r36sromstore/game.love"} <= validated:
                raise ValueError("Pacote incompleto")
            target.writestr(src.getinfo("update_manifest.json"),src.read("update_manifest.json"))
            for name in sorted(validated):
                target.writestr(src.getinfo(name),src.read(name))
    with ZipFile(out/archive_name) as output:
        if output.testzip() or set(output.namelist()) != validated | {"update_manifest.json"}:
            raise ValueError("Falha na verificação final do ZIP")
    ota = (out/archive_name).read_bytes()
    base = f"https://github.com/JammesPark/R36S-ROM-STORE-UPDATES/releases/download/store-v{version}"
    feed = {"version":version,"url":f"{base}/{archive_name}","sha256":sha(ota),"size":len(ota),
            "min_version":"0.7.1-beta","notes":"\n".join(manifest.get("changes", []))}
    feed_dir = out/"ota"/"rom-store"
    feed_dir.mkdir(parents=True,exist_ok=True)
    (feed_dir/"update.json").write_text(json.dumps(feed,indent=2,ensure_ascii=False)+"\n")
    # Manual package: only validated files under the app directory.
    protected = {"conf","logs","tmp","backups","gravacoes","bios","update","senhas.txt","catalog.json",
                 "catalogo_proprio.zlib","catalogo_proprio_ultimo_valido.zlib","catalogo_proprio.json",
                 "catalog_url.txt","update_url.txt","bios_url.txt","stats_url.txt","themes_url.txt",
                 "es_themes_url.txt","runtimes_url.txt","log.txt","configuracoes","saves","user_themes",
                 "favorites.json","downloads.json","settings.txt","theme.txt",".legacy_migrated",".legacy_migrated_v2"}
    manual = out/f"R36S_ROM_STORE_{version}_UPDATE.zip"
    with ZipFile(out/archive_name) as src, ZipFile(manual,"w") as target:
        for name in sorted(validated):
            if name == "R36S ROM STORE.sh":
                continue
            parts = name.split("/")
            if parts[1] in protected or parts[1].startswith("libs."):
                continue
            info = src.getinfo(name)
            if (info.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("Link simbólico no pacote manual")
            target.writestr(info,src.read(name))
    with ZipFile(manual) as result:
        if result.testzip() or "r36sromstore/game.love" not in result.namelist() or not all(p.startswith("r36sromstore/") for p in result.namelist()):
            raise ValueError("Pacote manual inválido")
    script = out/"INSTALAR_R36S_ROM_STORE.sh"
    shutil.copyfile(Path(__file__).resolve().parents[1]/script.name,script)
    script.chmod(0o755)
    names = [installer,out/archive_name,manual,script,feed_dir/"update.json"]
    (out/"SHA256SUMS.txt").write_text("".join(f"{sha(p.read_bytes())}  {p.relative_to(out)}\n" for p in names))

if __name__ == "__main__":
    pkg = Path(sys.argv[1]).resolve()
    stage(pkg,pkg.parent)
