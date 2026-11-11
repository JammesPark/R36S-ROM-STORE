#!/usr/bin/env python3
"""Validacao e extracao de arquivos sem reutilizar codigo de projetos externos."""
import os
import pathlib
import re
import shutil
import stat
import subprocess
import sys
import zipfile

MAX_FILES = 15000
MAX_EXPANDED = 12 * 1024**3

def check_name(name):
    if not name or "\x00" in name or "\\" in name or ":" in name or name.startswith("/"):
        raise ValueError("Caminho proibido no pacote")
    parts = pathlib.PurePosixPath(name).parts
    if ".." in parts or "." in parts or not parts:
        raise ValueError("Caminho relativo inseguro")
    if any(p in ("", ".", "..") for p in parts):
        raise ValueError("Componente inseguro")
    return parts

def extract_zip(archive, dest):
    count = total = 0
    with zipfile.ZipFile(archive) as z:
        for info in z.infolist():
            count += 1
            total += info.file_size
            if count > MAX_FILES or total > MAX_EXPANDED:
                raise ValueError("Pacote excede limite de arquivos ou tamanho")
            parts = check_name(info.filename)
            mode = (info.external_attr >> 16) & 0xFFFF
            if stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR):
                raise ValueError("Link ou arquivo especial nao permitido")
            target = os.path.join(dest, *parts)
            if info.is_dir():
                os.makedirs(target, exist_ok=True)
                continue
            os.makedirs(os.path.dirname(target), exist_ok=True)
            # O_EXCL evita sobrescrever entradas repetidas e links.
            flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
            if hasattr(os, "O_NOFOLLOW"):
                flags |= os.O_NOFOLLOW
            fd = os.open(target, flags, 0o600)
            with os.fdopen(fd, "wb") as out, z.open(info) as src:
                shutil.copyfileobj(src, out, 1024 * 1024)

def extract_7z(archive, dest, exe):
    result = subprocess.run([exe, "l", "-slt", archive], capture_output=True, text=True, check=True)
    block = {}
    files = []
    started = False
    for line in result.stdout.splitlines():
        if line.startswith("----------"):
            started = True
            block = {}
        elif started and not line.strip():
            if "Path" in block:
                files.append(block)
            block = {}
        elif started and " = " in line:
            k, v = line.split(" = ", 1)
            block[k] = v
    if block.get("Path"):
        files.append(block)
    if not files or len(files) > MAX_FILES:
        raise ValueError("Indice ausente ou grande demais")
    total = 0
    for item in files:
        check_name(item["Path"])
        total += int(item.get("Size", "0") or "0")
        if total > MAX_EXPANDED:
            raise ValueError("Pacote muito grande")
        attr = item.get("Attributes", "")
        if "L" in attr.upper() or item.get("Symbolic Link"):
            raise ValueError("Link simbolico no arquivo")
    subprocess.run([exe, "x", "-y", "-o" + dest, archive], check=True,
                   stdout=subprocess.DEVNULL)
    # Nao instalar links/arquivos especiais caso tenham escapado da listagem.
    for root, dirs, names in os.walk(dest, followlinks=False):
        for name in dirs + names:
            p = os.path.join(root, name)
            if os.path.islink(p) or not (os.path.isfile(p) or os.path.isdir(p)):
                raise ValueError("Arquivo extraido contem link ou tipo especial")

def main():
    archive, dest = sys.argv[1:3]
    os.makedirs(dest, mode=0o700, exist_ok=True)
    with open(archive, "rb") as f:
        sig = f.read(8)
    if sig.startswith((b"PK\x03\x04", b"PK\x05\x06")):
        extract_zip(archive, dest)
    elif sig.startswith((b"7z\xBC\xAF\x27\x1C", b"Rar!\x1A\x07")):
        exe = shutil.which("7zz") or shutil.which("7z")
        if not exe:
            raise ValueError("7zz/7z nao instalado para este formato")
        extract_7z(archive, dest, exe)
    else:
        raise ValueError("Arquivo nao e ZIP, 7z ou RAR valido")
    print("Pacote verificado e extraido")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("ERRO: " + str(e), file=sys.stderr)
        sys.exit(1)
