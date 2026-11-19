#!/usr/bin/env python3
"""Gera ZIP de UPDATE instalável a partir do ZIP completo da R36SPORTSBR STORE.

O pacote UPDATE contém APENAS o manifesto e os arquivos instaláveis listados
nele (sem README/LICENSE na raiz, que não são caminhos de instalação).
Sem uma versão-base gera UPDATE completo. Com --baseline, gera UPDATE
INCREMENTAL entre duas versões, incluindo apenas arquivos instaláveis alterados.
O ZIP completo e o código-fonte ficam separados na mesma Release (GPL-3.0).

O formato 0.0.7-beta é convertido em versão de manifesto 0.0.7,
mantendo version_label = 0.0.7-beta: o gerenciador 0.0.7-beta legado
exige componentes estritamente numéricos em update_manifest.json.
O número completo permanece no jogo e no update.json.
"""
import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path

VERSION = re.compile(r"^\d+\.\d+\.\d+(?:-beta)?$")
PACKAGE_PREFIX = "R36SPORTSBR_STORE_"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def create_update(package: Path, out: Path, version: str, *,
                  baseline: Path = None, base_version: str = None,
                  base_sha256: str = None) -> dict:
    if not VERSION.fullmatch(version):
        raise ValueError(f"Versão inválida: {version}")
    if package.name != f"{PACKAGE_PREFIX}{version}.zip":
        raise ValueError("Pacote de console não pertence à versão solicitada")
    if out.name not in {f"{PACKAGE_PREFIX}{version}_UPDATE.zip", f"{PACKAGE_PREFIX}{version}_UPDATE_FULL.zip"}:
        raise ValueError("Nome do UPDATE não pertence à versão solicitada")
    if baseline is not None and out.name.endswith("_UPDATE_FULL.zip"):
        raise ValueError("UPDATE_FULL nunca pode ser incremental")
    if package.resolve() == out.resolve():
        raise ValueError("Não é permitido sobrescrever o pacote de console")
    with zipfile.ZipFile(package) as source:
        bad = source.testzip()
        if bad:
            raise ValueError(f"ZIP de console corrompido: {bad}")
        manifest = json.loads(source.read("update_manifest.json"))
        if manifest.get("name") != "R36SPORTSBR STORE":
            raise ValueError("Identidade de pacote inesperada")
        if manifest.get("version") != version or manifest.get("type") != "full":
            raise ValueError("Versão ou tipo incompatível")
        files = manifest.get("files", [])
        if not files:
            raise ValueError("Manifesto de console vazio")
        names = [f["path"] for f in files]
        if len(set(names)) != len(names):
            raise ValueError("Arquivos duplicados")
        if not {"R36SPORTSBR STORE.sh", "r36sportsbrstore/game.love"}.issubset(names):
            raise ValueError("Faltam launcher ou game.love")
        for name in names:
            if name != "R36SPORTSBR STORE.sh" and not name.startswith("r36sportsbrstore/"):
                raise ValueError(f"Caminho fora da STORE: {name}")
            if name.startswith("/") or "\\" in name or ".." in name.split("/"):
                raise ValueError(f"Caminho inseguro: {name}")
        # Se houver baseline, gerar pacote incremental apenas dos caminhos
        # que realmente mudaram. Hash do pacote BASE é fixado para não usar
        # silenciosamente uma Release diferente da testada no console.
        if baseline is not None:
            if not base_version or not VERSION.fullmatch(base_version):
                raise ValueError("Versão-base inválida ou ausente")
            if base_version == version:
                raise ValueError("Versão nova e versão-base não podem ser iguais")
            if not base_sha256 or not re.fullmatch(r"[a-f0-9]{64}", base_sha256.lower()):
                raise ValueError("SHA-256 do ZIP base obrigatório")
            if baseline.resolve() in {package.resolve(), out.resolve()}:
                raise ValueError("ZIP base não pode ser sobrescrito")
            if sha256_file(baseline) != base_sha256.lower():
                raise ValueError("ZIP base difere do SHA-256 da Release aprovada")
            with zipfile.ZipFile(baseline) as older:
                invalid = older.testzip()
                if invalid:
                    raise ValueError("ZIP base danificado: " + invalid)
                older_m = json.loads(older.read("update_manifest.json"))
                if older_m.get("type") != "full" or older_m.get("version") != base_version:
                    raise ValueError("Manifesto do ZIP base inválido")
                prev = {e["path"]: e["sha256"] for e in older_m["files"]}
                if len(prev) != len(older_m["files"]):
                    raise ValueError("Manifesto base contém nomes duplicados")
                if not set(prev).issubset(names):
                    missing = sorted(set(prev) - set(names))
                    raise ValueError("Remoção de arquivos exige instalador completo: " + ", ".join(missing))
                # README é documento de distribuição; não precisa substituir
                # a cópia local ao atualizar o jogo. Fonte acompanha o Release.
                files = [e for e in files if e["path"] != "r36sportsbrstore/README.md"
                         and e["sha256"] != prev.get(e["path"])]
                if not files:
                    raise ValueError("Nenhum arquivo instalável alterado")
                manifest["type"] = "incremental"
                manifest["min_version"] = base_version.split("-")[0]
                manifest["max_version"] = base_version.split("-")[0]
                manifest["files"] = files
        # O parser da versão instalada 0.0.7-beta usa valid_version numérico.
        # 0.0.7-beta -> 0.0.7 no manifesto, rótulo continua com -beta.
        manifest["version_label"] = version
        manifest["version"] = version.split("-")[0]
        manifest["description"] = (
            f"Atualização {'incremental' if baseline is not None else 'completa'} {version}. Instala somente arquivos da STORE; "
            "preserva catálogos e dados locais protegidos."
        )
        out.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(out, "w") as target:
            zi = zipfile.ZipInfo("update_manifest.json", date_time=(2026, 1, 1, 0, 0, 0))
            zi.create_system = 3
            zi.external_attr = (0o100644 & 0xFFFF) << 16
            zi.compress_type = zipfile.ZIP_DEFLATED
            target.writestr(zi, json.dumps(manifest, ensure_ascii=False, indent=1) + "\n")
            for f in files:
                path = f["path"]
                raw = source.read(path)
                if len(raw) != f["size"] or sha256_bytes(raw) != f["sha256"]:
                    raise ValueError(f"SHA-256 ou tamanho inválido: {path}")
                zi = zipfile.ZipInfo(path, date_time=(2026, 1, 1, 0, 0, 0))
                zi.create_system = 3
                zi.external_attr = (0o100755 if path.endswith(".sh") else 0o100644) << 16
                zi.compress_type = zipfile.ZIP_DEFLATED
                target.writestr(zi, raw)
    # Verificar a saída independentemente do pacote original.
    with zipfile.ZipFile(out) as check:
        assert check.testzip() is None, "UPDATE corrompido"
        installed = set(check.namelist())
        assert installed == {e["path"] for e in manifest["files"]} | {"update_manifest.json"}
        dest = json.loads(check.read("update_manifest.json"))
        for entry in dest["files"]:
            data = check.read(entry["path"])
            assert sha256_bytes(data) == entry["sha256"]
            assert len(data) == entry["size"]
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--baseline", type=Path, help="ZIP completo da versão-base aprovada")
    parser.add_argument("--base-version", help="Versão exata da instalação-base")
    parser.add_argument("--base-sha256", help="SHA-256 verificado do ZIP completo base")
    args = parser.parse_args()
    try:
        m = create_update(args.package, args.out, args.version,
                          baseline=args.baseline, base_version=args.base_version,
                          base_sha256=args.base_sha256)
    except (ValueError, OSError, KeyError, zipfile.BadZipFile, json.JSONDecodeError) as e:
        parser.exit(1, f"Falha ao gerar UPDATE: {e}\n")
    print(f"UPDATE {m['type']} OK: {args.out}, versão {m['version_label']}, "
          f"{len(m['files'])} arquivos")


if __name__ == "__main__":
    main()
