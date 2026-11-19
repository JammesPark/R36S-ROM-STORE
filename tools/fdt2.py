#!/usr/bin/env python3
# Adaptado para a R36SPORTSBR STORE a partir do R36S PORT HUB (Lag do Lira).
# Codigo sob GPL-3.0; original preservado em docs/preservacao/original/tools/.
"""Extrai assinaturas de DTBs dArkOSRE e AeolusUX para JSON de pesquisa."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from fdtparse import parse, txt

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build/generated-data/darkosre_sigs.json"


def u32(data):
    return struct.unpack(">I", data[:4])[0] if data and len(data) >= 4 else None


def records(folder):
    result = []
    for path in sorted(folder.rglob("rk3326-r*-linux.dtb")):
        if not path.is_file():
            continue
        try:
            nodes = parse(path.read_bytes())
            root = nodes["/"]
            rel = str(path.relative_to(folder)).replace("\\", "/")
            name = rel.split("/dtb/", 1)[-1]
            rec = {"file": name, "model": txt(root.get("model")), "compat": txt(root.get("compatible"))}
            for key, properties in nodes.items():
                if "panel-init-sequence" in properties:
                    seq = properties["panel-init-sequence"]
                    rec.update(panel_node=key, panel_compat=txt(properties.get("compatible")),
                               init_sha1=hashlib.sha1(seq).hexdigest(), init_len=len(seq))
                if ("display-timings" in key and
                        u32(properties.get("hactive")) is not None and
                        u32(properties.get("vactive")) is not None):
                    rec["res"] = f'{u32(properties["hactive"])}x{u32(properties["vactive"])}'
                if key.count("/") <= 1 and any("joypad" in p for p in txt(properties.get("compatible"))):
                    rec["joypad"] = txt(properties["compatible"])
            result.append(rec)
        except (OSError, ValueError) as exc:
            raise ValueError(f"{path}: {exc}") from exc
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("directory", type=Path, help="Pasta com rk3326-*-linux.dtb")
    ap.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    ap.add_argument("--out", type=Path, help="Destino JSON (substitui output)")
    args = ap.parse_args()
    if not args.directory.is_dir():
        ap.error("Diretorio de DTBs inexistente")
    try:
        data = records(args.directory)
    except ValueError as exc:
        ap.error(str(exc))
    if not data:
        ap.error("Nenhum DTB rk3326-r*-linux.dtb encontrado")
    target = args.out or args.output
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Extraidos {len(data)} DTBs -> {target}")


if __name__ == "__main__":
    main()
