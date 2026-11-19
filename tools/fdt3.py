#!/usr/bin/env python3
# Adaptado para a R36SPORTSBR STORE a partir do R36S PORT HUB (Lag do Lira).
# Codigo sob GPL-3.0; original preservado em docs/preservacao/original/tools/.
"""Extrai assinaturas DTB do diretório consoles do ArkOS4Clone."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from fdtparse import parse, txt

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build/generated-data/a4c_sigs.json"


def u32(data):
    return struct.unpack(">I", data[:4])[0] if data and len(data) >= 4 else None


def records(consoles_dir):
    out = []
    for file in sorted(consoles_dir.glob("*/*.dtb")):
        try:
            nodes = parse(file.read_bytes())
            root = nodes["/"]
            rec = {"dir": file.parent.name, "file": file.name,
                   "model": txt(root.get("model")), "compat": txt(root.get("compatible"))}
            for name, properties in nodes.items():
                if "panel-init-sequence" in properties:
                    rec["panel_compat"] = txt(properties.get("compatible"))
                    rec["init_sha1"] = hashlib.sha1(properties["panel-init-sequence"]).hexdigest()
                if ("/display-timings/" in name and
                        u32(properties.get("hactive")) is not None and
                        u32(properties.get("vactive")) is not None):
                    rec["res"] = f'{u32(properties["hactive"])}x{u32(properties["vactive"])}'
            out.append(rec)
        except (OSError, ValueError) as exc:
            raise ValueError(f"{file}: {exc}") from exc
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("consoles", type=Path, help="Pasta boot/dArkOS/consoles")
    ap.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()
    if not args.consoles.is_dir():
        ap.error("Diretorio de consoles inexistente")
    try:
        out = records(args.consoles)
    except ValueError as exc:
        ap.error(str(exc))
    if not out:
        ap.error("Nenhum DTB encontrado em */*.dtb")
    target = args.out or args.output
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Extraidos {len(out)} DTBs -> {target}")


if __name__ == "__main__":
    main()
