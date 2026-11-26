#!/usr/bin/env python3
"""Controla o numero da versao do R36SPORTSBR STORE (sem dependencias externas).

Fonte principal: C.VERSION_NUM e C.VERSION em src/config.lua.
Outras referencias documentais sao sincronizadas no comando bump.

Uso:
  python3 tools/version.py get
  python3 tools/version.py check
  python3 tools/version.py bump patch --note "Descricao desta entrega"
  python3 tools/version.py bump minor --note "Descricao desta entrega"
"""
import argparse
import datetime
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src" / "config.lua"
READMES = [ROOT / "README.md", ROOT / "port" / "r36sromstore" / "README.md"]
CHANGELOG = ROOT / "CHANGELOG.md"
LABEL = re.compile(r'(?m)^(C\.VERSION\s*=\s*L\(")([^"]+)("\))')
NUMBER = re.compile(r'(?m)^(C\.VERSION_NUM\s*=\s*")([^"]+)(")')
SEMVER = re.compile(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-beta)?$')
STATUS = re.compile(r'(?m)^(\*\*Status:\*\*\s*versão\s+)(\S+)')


def current():
    text = CONFIG.read_text(encoding="utf-8")
    labels = list(LABEL.finditer(text))
    numbers = list(NUMBER.finditer(text))
    if len(labels) != 1 or len(numbers) != 1:
        raise ValueError("src/config.lua: marcadores de versao ausentes ou duplicados")
    a, b = labels[0].group(2), numbers[0].group(2)
    if a != b or not SEMVER.fullmatch(b):
        raise ValueError("C.VERSION e C.VERSION_NUM devem ser iguais e ter formato x.y.z[-beta]")
    return b


def check():
    value = current()
    for path in READMES:
        doc = path.read_text(encoding="utf-8")
        matches = list(STATUS.finditer(doc))
        if len(matches) != 1 or matches[0].group(2) != value:
            raise ValueError(f"{path}: status nao coincide com a versao {value}")
    log = CHANGELOG.read_text(encoding="utf-8")
    if f"## [{value}]" not in log:
        raise ValueError(f"CHANGELOG.md: falta a versao {value}")
    print(f"Versao consistente: {value}")
    return value


def bump(kind, note):
    if not note or not note.strip():
        raise ValueError("Informe --note com o resumo da nova entrega")
    old = check()
    match = SEMVER.fullmatch(old)
    major, minor, patch = (int(match.group(i)) for i in (1, 2, 3))
    suffix = match.group(4) or ""
    if kind == "patch":
        patch += 1
    elif kind == "minor":
        minor, patch = minor + 1, 0
    elif kind == "major":
        major, minor, patch = major + 1, 0, 0
    else:
        raise ValueError(f"Incremento desconhecido: {kind}")
    new = f"{major}.{minor}.{patch}{suffix}"
    cfg = CONFIG.read_text(encoding="utf-8")
    cfg = LABEL.sub(lambda m: m.group(1) + new + m.group(3), cfg)
    cfg = NUMBER.sub(lambda m: m.group(1) + new + m.group(3), cfg)
    doc_versions = []
    for path in READMES:
        doc = path.read_text(encoding="utf-8")
        doc_versions.append((path, STATUS.sub(lambda m: m.group(1) + new, doc)))
    log = CHANGELOG.read_text(encoding="utf-8")
    if f"## [{new}]" in log:
        raise ValueError(f"CHANGELOG.md ja contem {new}")
    date = datetime.date.today().isoformat()
    new_entry = f"## [{new}] - {date}\n\n- {note.strip()}\n\n"
    anchor = "# Histórico de versões\n\n"
    if anchor not in log:
        raise ValueError("CHANGELOG.md: cabecalho esperado nao encontrado")
    log = log.replace(anchor, anchor + new_entry, 1)
    CONFIG.write_text(cfg, encoding="utf-8")
    for path, content in doc_versions:
        path.write_text(content, encoding="utf-8")
    CHANGELOG.write_text(log, encoding="utf-8")
    check()
    print(f"{old} -> {new}")
    return new


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("command", choices=("get", "check", "bump"))
    ap.add_argument("kind", nargs="?", choices=("patch", "minor", "major"))
    ap.add_argument("--note", help="Descricao da entrega; obrigatoria ao incrementar")
    args = ap.parse_args()
    try:
        if args.command == "get":
            print(current())
        elif args.command == "check":
            check()
        else:
            if not args.kind:
                ap.error("bump exige patch, minor ou major")
            bump(args.kind, args.note)
    except (ValueError, OSError) as err:
        ap.exit(1, f"Erro de versao: {err}\n")


if __name__ == "__main__":
    main()
