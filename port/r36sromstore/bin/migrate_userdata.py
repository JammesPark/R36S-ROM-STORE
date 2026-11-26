#!/usr/bin/env python3
"""Copy missing user data on the same SD. Original backups stay usable by the old launcher."""
import fcntl
import hashlib
import os
from contextlib import contextmanager
from pathlib import Path
import shutil
import stat
import sys
import tempfile

USER_PATHS = (
    "conf", "gravacoes", "configuracoes", "bios", "logs", "catalogo_proprio.zlib",
    "catalogo_proprio_ultimo_valido.zlib", "catalog_url.txt", "themes_url.txt",
    "es_themes_url.txt", "bios_url.txt", "runtimes_url.txt", "stats_url.txt", "senhas.txt",
)
STOCK_CATALOG = "dfd620807ac1c853d8691ffd7efdce623d8579828f6085d56552047eb7177f13"
TRANSIENT = {".restart_es", ".run_tool", ".run_port", ".run_game", ".power", ".es_theme", ".restart_app"}

def atomic_copy(src, dst):
    with tempfile.NamedTemporaryFile(prefix=".romstore-", dir=dst.parent, delete=False) as tmp:
        path = Path(tmp.name)
    try:
        shutil.copyfile(src, path)
        try:
            shutil.copymode(src, path)
        except PermissionError:
            pass  # FAT media may use a mount-wide file mode.
        with path.open("rb") as copied:
            os.fsync(copied.fileno())
        os.replace(path, dst)
    finally:
        if path.exists():
            path.unlink()

def merge(src, dst):
    if src.is_symlink() or dst.is_symlink() or not src.exists():
        return
    mode = src.stat().st_mode
    if stat.S_ISDIR(mode):
        if dst.exists() and not dst.is_dir():
            return
        dst.mkdir(exist_ok=True)
        for entry in src.iterdir():
            if entry.name not in TRANSIENT:
                merge(entry, dst / entry.name)
    elif stat.S_ISREG(mode) and not dst.exists():
        atomic_copy(src, dst)

def migrate(old, new):
    if any(p.is_symlink() or not p.is_dir() for p in (old, new)):
        raise ValueError("Diretório de migração inválido")
    with open_directory_lock(new):
        merge_all(old, new)

@contextmanager
def open_directory_lock(path):
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        os.close(fd)

def merge_all(old, new):
    flag = new / ".legacy_migrated_v2"
    if flag.is_symlink():
        raise ValueError("Marcador de migração inválido")
    if flag.exists():
        return
    for name in USER_PATHS:
        merge(old / name, new / name)
    # ZIPs oficiais 0.6.7–0.7.1 trazem o mesmo catálogo de fábrica. Preservar
    # um catálogo editado no SD mesmo após a extração do pacote completo.
    src, dst = old / "catalog.json", new / "catalog.json"
    if src.is_file() and not src.is_symlink() and not dst.is_symlink():
        if not dst.exists() or (dst.is_file() and hashlib.sha256(dst.read_bytes()).hexdigest() == STOCK_CATALOG):
            if not dst.exists() or hashlib.sha256(src.read_bytes()).hexdigest() != STOCK_CATALOG:
                atomic_copy(src, dst)
    # The new updater must never replay a legacy journal or use a legacy feed override.
    flag.touch(exist_ok=False)

if __name__ == "__main__":
    try:
        migrate(Path(sys.argv[1]), Path(sys.argv[2]))
    except (OSError, ValueError) as exc:
        sys.exit("Falha ao copiar os dados antigos: " + str(exc))
