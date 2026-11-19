#!/usr/bin/env python3
# Adaptado de R36S PORT HUB por Lag do Lira, GPL-3.0.
# Original preservado em docs/preservacao/original/tools/mkbiosdb.py.
"""Gera banco de BIOS a partir de tools/ref/System.dat, sem sobrescrever o aplicativo.

Saida padrão: build/generated-data/bios_db.lua
Usa somente hashes, tamanhos, nomes e sistemas descritos no DAT do libretro.
"""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def generate(src, out, commit):
    src = Path(src).resolve()
    out = Path(out).resolve()
    for protected in (ROOT / "game", ROOT / "r36sportsbrstore"):
        if out.is_relative_to(protected.resolve()):
            raise ValueError(f"Destino protegido: {out}; gere em build/ para revisao.")
    if not src.is_file():
        raise ValueError(f"System.dat inexistente: {src}")
    text = src.read_text(encoding="utf-8")
    version = (re.search(r'^\s*version\s+(\S+)', text, re.M) or [None, "?"])[1]
    system = None
    rows = []
    rx = re.compile(r'rom \(\s*name\s+("([^"]+)"|(\S+))(.*)\)')
    for line in text.splitlines():
        m = re.match(r'\s*comment\s+"(.*)"\s*$', line)
        if m and m.group(1) != "System":
            system = m.group(1)
            continue
        m = rx.search(line)
        if m:
            name = m.group(2) or m.group(3)
            kv = dict(re.findall(r'(size|crc|md5|sha1)\s+(\w+)', m.group(4)))
            if "md5" not in kv:
                continue
            rows.append((name, int(kv.get("size", -1)), kv["md5"].lower(), kv.get("sha1", "").lower(), system or "?"))

    def q(s):
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

    systems = sorted({r[4] for r in rows})
    sid = {s: i + 1 for i, s in enumerate(systems)}
    if not rows:
        raise ValueError("Nenhuma BIOS com MD5 encontrada no System.dat")
    with out.open("w", encoding="utf-8") as f:
        f.write("-- =============================================================================\n")
        f.write("--  Banco de hashes de BIOS (gerado por tools/mkbiosdb.py, nao editar a mao)\n")
        f.write("--  Fonte: libretro-database, dat/System.dat %s%s\n" % (version, (" (commit " + commit + ")") if commit else ""))
        f.write("--  https://github.com/libretro/libretro-database/blob/master/dat/System.dat\n")
        f.write("--  n = caminho dentro da pasta de BIOS, s = tamanho, m = MD5, h = SHA-1, y = sistema\n")
        f.write("-- =============================================================================\n")
        f.write("local M = {}\n")
        f.write("M.SOURCE = %s\n" % q("libretro-database System.dat " + version + ((" " + commit[:12]) if commit else "")))
        f.write("M.SYSTEMS = {\n")
        for s in systems:
            f.write("  %s,\n" % q(s))
        f.write("}\n")
        f.write("M.LIST = {\n")
        for name, size, md5, sha1, s in rows:
            f.write("  { n = %s, s = %d, m = %s, h = %s, y = %d },\n" % (q(name), size, q(md5), q(sha1), sid[s]))
        f.write("}\n")
        f.write("return M\n")

    print("Entradas:", len(rows), "sistemas:", len(systems), "fonte:", version, "arquivo:", out)
    return len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'tools/ref/System.dat')
    parser.add_argument('--out', type=Path, default=ROOT / 'build/generated-data/bios_db.lua')
    parser.add_argument('--commit', default='', help='SHA do commit da fonte libretro')
    args = parser.parse_args()
    try:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        generate(args.source, args.out, args.commit)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))


if __name__ == '__main__':
    main()
