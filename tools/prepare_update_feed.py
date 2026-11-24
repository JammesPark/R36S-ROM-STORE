#!/usr/bin/env python3
"""Valida os dois ZIPs e gera update.json para um GitHub Release público.

NÃO publica nem instala nada. Script offline; saída em arquivo escolhido.
Código-fonte e pacote de console devem corresponder à MESMA versão.
"""
import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path

DEFAULT_REPO = "JammesPark/R36SPORTSBR-STORE-UPDATES"
VERSION = re.compile(r"^\d+\.\d+\.\d+(?:-beta)?$")
PACKAGE_PREFIX = "R36SPORTSBR_STORE_"


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    sha = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def create_feed(package: Path, source: Path, version: str,
                repo: str = DEFAULT_REPO, notes: str = "", update: Path = None,
                base_version: str = None, full_update: Path = None):
    if not VERSION.fullmatch(version):
        raise ValueError(f"Versão inválida: {version}")
    if repo != DEFAULT_REPO:
        raise ValueError("Canal diferente do repositório oficial: " + repo)
    wanted_package = f"{PACKAGE_PREFIX}{version}.zip"
    wanted_source = f"{PACKAGE_PREFIX}{version}_CODIGO_FONTE.zip"
    if package.name != wanted_package or source.name != wanted_source:
        raise ValueError("Nomes dos ZIPs não correspondem à versão informada")
    if not package.is_file() or not source.is_file():
        raise ValueError("Os dois ZIPs de distribuição precisam existir")
    try:
        with zipfile.ZipFile(package) as z:
            bad = z.testzip()
            if bad:
                raise ValueError(f"ZIP de console corrompido: {bad}")
            names = set(z.namelist())
            if "update_manifest.json" not in names:
                raise ValueError("Manifesto de instalação ausente")
            manifest = json.loads(z.read("update_manifest.json"))
            if manifest.get("name") != "R36SPORTSBR STORE" or manifest.get("type") != "full":
                raise ValueError("Identidade ou tipo de manifesto inválido")
            if manifest.get("version") != version:
                raise ValueError("Versão do manifesto não corresponde à publicação")
            entries = manifest.get("files")
            if not isinstance(entries, list) or not entries:
                raise ValueError("Manifesto sem arquivos")
            paths = [e.get("path") for e in entries]
            if len(paths) != len(set(paths)):
                raise ValueError("Arquivo repetido no manifesto")
            for needed in ["r36sportsbrstore/game.love", "R36SPORTSBR STORE.sh"]:
                if needed not in paths:
                    raise ValueError(f"Pacote incompleto: {needed}")
            for entry in entries:
                path = entry.get("path")
                if not isinstance(path, str) or path not in names:
                    raise ValueError(f"Arquivo do manifesto ausente: {path}")
                data = z.read(path)
                if len(data) != entry.get("size") or sha256_bytes(data) != entry.get("sha256"):
                    raise ValueError(f"SHA-256 ou tamanho incorreto: {path}")
        with zipfile.ZipFile(source) as z:
            bad = z.testzip()
            if bad:
                raise ValueError(f"ZIP de fonte corrompido: {bad}")
            contents = set(z.namelist())
            source_dir = "src" if "src/config.lua" in contents else "game"
            launcher = "port/R36S ROMS STORE.sh" if source_dir == "src" else "R36SPORTSBR STORE.sh"
            required = {
                f"{source_dir}/main.lua", f"{source_dir}/config.lua", "tools/mkart.py",
                "tools/make_update.py", "LICENSE", "NOTICE.md",
                launcher, ".github/workflows/build.yml",
            }
            if not required.issubset(contents):
                raise ValueError(f"Código-fonte incompleto: {sorted(required-contents)}")
            cfg = z.read(f"{source_dir}/config.lua").decode("utf-8")
            if f'C.VERSION_NUM = "{version}"' not in cfg:
                raise ValueError("Versão do código-fonte diverge do aplicativo")
    except (zipfile.BadZipFile, json.JSONDecodeError, KeyError) as error:
        raise ValueError(f"Pacote inválido: {error}") from error

    update_is_incremental = False
    if update is not None:
        wanted_update = f"{PACKAGE_PREFIX}{version}_UPDATE.zip"
        if update.name != wanted_update or not update.is_file():
            raise ValueError("UPDATE ausente ou nome de versão incorreto")
        try:
            with zipfile.ZipFile(update) as z:
                bad = z.testzip()
                if bad:
                    raise ValueError(f"UPDATE danificado: {bad}")
                update_names = set(z.namelist())
                updated_manifest = json.loads(z.read("update_manifest.json"))
                if updated_manifest.get("name") != "R36SPORTSBR STORE":
                    raise ValueError("UPDATE de identidade incorreta")
                if updated_manifest.get("type") not in ("full", "incremental"):
                    raise ValueError("Tipo de UPDATE desconhecido")
                update_is_incremental = updated_manifest.get("type") == "incremental"
                if update_is_incremental:
                    if not base_version or not VERSION.fullmatch(base_version):
                        raise ValueError("UPDATE incremental exige versão-base explícita")
                    base_num = base_version.split("-")[0]
                    if updated_manifest.get("min_version") != base_num or updated_manifest.get("max_version") != base_num:
                        raise ValueError("Limites de versão-base do UPDATE incorretos")
                if updated_manifest.get("version_label") != version:
                    raise ValueError("Versão exibida no UPDATE incorreta")
                if updated_manifest.get("version") != version.split("-")[0]:
                    raise ValueError("Versão numérica no UPDATE inválida para o Lua legado")
                updated_paths = [entry["path"] for entry in updated_manifest["files"]]
                if len(updated_paths) != len(set(updated_paths)):
                    raise ValueError("UPDATE com arquivos duplicados")
                if update_names != set(updated_paths) | {"update_manifest.json"}:
                    raise ValueError("UPDATE com arquivos ausentes ou extras")
                # UPDATE completo inclui todos os arquivos instaláveis.
                # UPDATE incremental aceita apenas um SUBCONJUNTO idêntico aos
                # arquivos do instalador da mesma versão. O SHA evita divergência.
                if updated_manifest.get("type") == "full":
                    if sorted(updated_paths) != sorted(paths):
                        raise ValueError("UPDATE completo diverge do instalador")
                elif not updated_paths or not set(updated_paths).issubset(paths):
                    raise ValueError("UPDATE incremental vazio ou fora do instalador")
                full_files = {entry["path"]: entry for entry in entries}
                for entry in updated_manifest["files"]:
                    full = full_files[entry["path"]]
                    if entry["sha256"] != full["sha256"] or entry["size"] != full["size"]:
                        raise ValueError("UPDATE não corresponde à versão completa: " + entry["path"])
                for entry in updated_manifest["files"]:
                    data = z.read(entry["path"])
                    if len(data) != entry["size"] or sha256_bytes(data) != entry["sha256"]:
                        raise ValueError("SHA-256 inválido no UPDATE: " + entry["path"])
        except (zipfile.BadZipFile, json.JSONDecodeError, KeyError) as error:
            raise ValueError(f"UPDATE inválido: {error}") from error

    # Fallback cumulativo real: manifesto numerico aceito inclusive pelos hubs
    # instalados anteriormente, sem documentos avulsos na raiz do ZIP.
    if full_update is not None:
        expected = f"{PACKAGE_PREFIX}{version}_UPDATE_FULL.zip"
        if full_update.name != expected or not full_update.is_file():
            raise ValueError("UPDATE_FULL ausente ou nome incorreto")
        with zipfile.ZipFile(full_update) as z:
            bad = z.testzip()
            if bad:
                raise ValueError("UPDATE_FULL corrompido: " + bad)
            manifest_full = json.loads(z.read("update_manifest.json"))
            if (manifest_full.get("type") != "full" or
                manifest_full.get("name") != "R36SPORTSBR STORE" or
                manifest_full.get("version") != version.split("-")[0] or
                manifest_full.get("version_label") != version or
                "min_version" in manifest_full or "max_version" in manifest_full):
                raise ValueError("Manifesto do UPDATE_FULL incompatível com versões antigas")
            full_entries = manifest_full.get("files") or []
            if ({e["path"]: (e["size"], e["sha256"]) for e in full_entries} !=
                {e["path"]: (e["size"], e["sha256"]) for e in entries}):
                raise ValueError("UPDATE_FULL difere dos arquivos instaláveis do ZIP completo")
            if set(z.namelist()) != {e["path"] for e in full_entries} | {"update_manifest.json"}:
                raise ValueError("UPDATE_FULL contém arquivos extras ou faltantes")
            for e in full_entries:
                blob = z.read(e["path"])
                if len(blob) != e["size"] or sha256_bytes(blob) != e["sha256"]:
                    raise ValueError("Falha de SHA-256 no UPDATE_FULL: " + e["path"])

    release_path = f"https://github.com/{repo}/releases/download/v{version}"
    feed = {
        "channel": "beta",
        "status": "published",
        "version": version,
        "url": f"{release_path}/{wanted_package}",
        "sha256": sha256_file(package),
        "size": package.stat().st_size,
        "notes": notes.strip() or f"R36SPORTSBR STORE {version}",
        "source_url": f"{release_path}/{wanted_source}",
        "source_sha256": sha256_file(source),
    }
    if update is not None:
        # url/sha256/size SEMPRE apontam ao ZIP COMPLETO: consoles antigos
        # (incluindo 0.0.10-beta) nao conhecem campos novos de fallback.
        # Isso torna a atualizacao cumulativa segura sem exigir versoes-pontes.
        fallback = full_update if full_update is not None else package
        feed["full_url"] = f"{release_path}/{fallback.name}"
        feed["full_sha256"] = sha256_file(fallback)
        feed["full_size"] = fallback.stat().st_size
        if update_is_incremental:
            # Consoles novos podem selecionar o menor pacote pela versao-base.
            # NUNCA aplicar limites do incremental ao pacote completo.
            feed["incremental_url"] = f"{release_path}/{wanted_update}"
            feed["incremental_sha256"] = sha256_file(update)
            feed["incremental_size"] = update.stat().st_size
            base_num = base_version.split("-")[0]
            feed["incremental_min_version"] = base_num
            feed["incremental_max_version"] = base_num
    return feed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--update", type=Path, help="ZIP de atualização para o console")
    parser.add_argument("--base-version", help="Versão-base exigida pelo UPDATE incremental")
    parser.add_argument("--full-update", type=Path, help="ZIP completo de atualização, sem arquivos de distribuição extras")
    parser.add_argument("--version", required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--notes", default="")
    args = parser.parse_args()
    try:
        feed = create_feed(args.package, args.source, args.version, notes=args.notes,
                           update=args.update, base_version=args.base_version,
                           full_update=args.full_update)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(feed, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8")
    except (ValueError, OSError) as error:
        parser.exit(1, f"Falha ao gerar update.json: {error}\n")
    print("Feed validado para", feed["version"], "SHA-256:", feed["sha256"])
    print("Código-fonte:", feed["source_url"])


if __name__ == "__main__":
    main()
