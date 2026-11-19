#!/usr/bin/env python3
"""Verifica se os arquivos anteriores a recuperacao continuam presentes.

A lista em docs/preservacao/baseline.json e uma salvaguarda contra remocoes
acidentais. Alteracoes intencionais no codigo sao permitidas: nao fixa hashes
do aplicativo, para continuar permitindo desenvolvimento normal.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT / "docs/preservacao/baseline.json"


def main():
    data = json.loads(BASELINE.read_text(encoding="utf-8"))
    required = set(data["protected_existing_files"])
    required.update(data["restored_original_files"])
    required.update(data.get("additional_protected_files", []))
    bad = sorted(p for p in required if not (ROOT / p).is_file())
    if bad:
        raise SystemExit("Arquivos protegidos ausentes:\n" + "\n".join(bad))

    # O backup offline do Lira precisa ser copia integral de ports.json.
    source = (ROOT / "ports.json").read_bytes()
    offline = (ROOT / "game/catalog/lira_catalog_original.json").read_bytes()
    if source != offline:
        raise SystemExit("Catalogo original offline diverge do ports.json restaurado")
    cat = json.loads(offline.decode("utf-8"))
    if not isinstance(cat.get("ports"), list) or not cat["ports"]:
        raise SystemExit("O catalogo offline do Lira ficou vazio ou invalido")

    # As fontes da STORE nao podem desaparecer durante atualizacoes.
    for file in ["game/catalog/catalog.json", "game/catalog/lira_catalog.json",
                 "game/core/portstorage.lua", "game/config.lua",
                 "R36SPORTSBR STORE.sh", "NOTICE.md", "LICENSE"]:
        if not (ROOT / file).is_file():
            raise SystemExit("Arquivo proprio da STORE ausente: " + file)

    # O importador antigo jamais deve executar nem escrever na main.
    workflow = (ROOT / ".github/workflows/import-source.yml").read_text(encoding="utf-8")
    if "if: false" not in workflow or "contents: read" not in workflow:
        raise SystemExit("Workflow legado perigoso nao esta desativado")
    pub = (ROOT / "publicar.sh").read_text(encoding="utf-8")
    if "exit 1" not in pub:
        raise SystemExit("Publicador original nao esta bloqueado")

    print(f"Preservacao aprovada: {len(required)} arquivos protegidos; "
          f"{len(cat['ports'])} ports na copia offline do Lira.")


if __name__ == "__main__":
    main()
