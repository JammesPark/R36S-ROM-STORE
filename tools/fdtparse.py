#!/usr/bin/env python3
# Adaptado para a R36SPORTSBR STORE a partir do R36S PORT HUB (Lag do Lira).
# Codigo sob GPL-3.0; original preservado em docs/preservacao/original/tools/.
"""Lê Device Trees binárias (DTB) sem bibliotecas externas."""
import argparse
import hashlib
import struct
from pathlib import Path

MAGIC = 0xD00DFEED
MAX_BYTES = 32 * 1024 * 1024


def parse(blob):
    """Devolve nós e propriedades: dict[caminho][nome] = bytes."""
    if not isinstance(blob, (bytes, bytearray)) or not 40 <= len(blob) <= MAX_BYTES:
        raise ValueError("DTB ausente, muito pequeno ou maior que 32 MiB")
    magic, total, off_struct, off_strings, _, version, _, _, size_strings, size_struct = struct.unpack_from(">10I", blob)
    if magic != MAGIC:
        raise ValueError("Assinatura DTB invalida")
    if total > len(blob) or total < 40:
        raise ValueError("Tamanho total do DTB invalido")
    if version < 16:
        raise ValueError("Versao DTB nao suportada")
    if (off_struct >= total or off_strings >= total or
            size_struct > total - off_struct or
            size_strings > total - off_strings):
        raise ValueError("Offsets ou blocos DTB invalidos")
    pos, end = off_struct, off_struct + size_struct
    names = blob[off_strings:off_strings + size_strings]
    stack, nodes = [], {}
    finished = False

    def text_at(block, start):
        if start >= len(block):
            raise ValueError("Offset de string DTB invalido")
        stop = block.find(b"\0", start)
        if stop < 0:
            raise ValueError("String DTB sem terminador")
        return block[start:stop].decode("latin1")

    while pos + 4 <= end:
        token = struct.unpack_from(">I", blob, pos)[0]
        pos += 4
        if token == 1:  # FDT_BEGIN_NODE
            name = text_at(blob[:end], pos)
            pos = (pos + len(name.encode("latin1")) + 1 + 3) & ~3
            stack.append(name)
            nodes["/".join(stack) or "/"] = {}
        elif token == 2:  # FDT_END_NODE
            if not stack:
                raise ValueError("No DTB sem abertura")
            stack.pop()
        elif token == 3:  # FDT_PROP
            if pos + 8 > end or not stack:
                raise ValueError("Propriedade DTB fora de no")
            length, name_offset = struct.unpack_from(">II", blob, pos)
            pos += 8
            if pos + length > end:
                raise ValueError("Propriedade DTB truncada")
            path = "/".join(stack) or "/"
            nodes[path][text_at(names, name_offset)] = bytes(blob[pos:pos + length])
            pos = (pos + length + 3) & ~3
        elif token == 4:  # FDT_NOP
            continue
        elif token == 9:  # FDT_END
            if stack:
                raise ValueError("DTB com nos sem fechamento")
            finished = True
            break
        else:
            raise ValueError(f"Token DTB nao suportado: {token}")
    if not finished or "/" not in nodes:
        raise ValueError("DTB incompleto ou sem raiz")
    return nodes


def txt(value):
    """Interpreta propriedade como sequência de strings terminadas em NUL."""
    if value is None:
        return []
    return [s.decode("latin1") for s in value.split(b"\0") if s]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("dtbs", nargs="+", type=Path)
    opts = ap.parse_args()
    for path in opts.dtbs:
        try:
            nodes = parse(path.read_bytes())
            root = nodes["/"]
            print(path, "model=", txt(root.get("model")), "compatible=", txt(root.get("compatible")))
            for name, props in nodes.items():
                if "panel-init-sequence" in props:
                    seq = props["panel-init-sequence"]
                    print(" panel", name, "sha1", hashlib.sha1(seq).hexdigest(),
                          "length", len(seq))
        except (OSError, ValueError) as exc:
            ap.error(f"{path}: {exc}")


if __name__ == "__main__":
    main()
