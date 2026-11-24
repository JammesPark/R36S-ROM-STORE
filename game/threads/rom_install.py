#!/usr/bin/env python3
"""Instalacao conservadora de ROMs (chamado apenas pelo modo rom do LÖVE).
Nao sobrescreve arquivos existentes, nao executa scripts de arquivos baixados.
Usa somente bibliotecas Python padrao; 7z/RAR requer 7-Zip incluido no app.
"""
import argparse
import os
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import zipfile
from pathlib import Path

ALLOWED = {
    "3do": {"iso", "chd", "cue", "bin"},
    "amigacd32": {"iso", "chd", "cue", "bin"},
    "atari2600": {"a26", "bin", "rom"},
    "dreamcast": {"cdi", "gdi", "chd", "cue", "bin"},
    "gamegear": {"gg", "zip"},
    "gb": {"gb", "zip"},
    "gba": {"gba", "zip"},
    "gbc": {"gbc", "zip"},
    "mame": {"zip"},
    "mastersystem": {"sms", "zip"},
    "megadrive": {"md", "gen", "bin", "zip"},
    "n64": {"n64", "z64", "v64", "zip"},
    "nds": {"nds", "zip"},
    "neogeo": {"zip"},
    "nes": {"nes", "zip"},
    "pcengine": {"pce", "zip"},
    "psp": {"iso", "cso", "chd", "pbp"},
    "psp-minis": {"iso", "cso", "chd", "pbp"},
    "cps1": {"zip"}, "cps2": {"zip"}, "cps3": {"zip"},
    "psx": {"cue", "bin", "iso", "chd", "pbp", "ccd", "img", "sub", "m3u"},
    "saturn": {"cue", "bin", "iso", "chd", "ccd", "img", "mds", "mdf", "m3u"},
    "snes": {"sfc", "smc", "zip"},
}
DIRECT_ZIP = {"mame", "neogeo", "cps1", "cps2", "cps3"}
MAX_ENTRIES = 30000
MAX_NAME = 1024
CHUNK = 1024 * 1024

class RomError(Exception):
    def __init__(self, code, msg=""):
        self.code, self.msg = code, str(msg)
        super().__init__(msg)

def emit(*args):
    print("|".join(str(x).replace("|", " ").replace("\n", " ") for x in args), flush=True)

def check_cancel(flag):
    if Path(flag).exists():
        raise RomError("cancelled", "Cancelado pelo usuário")

def name_ok(name):
    if not name or len(name.encode("utf-8", errors="replace")) > MAX_NAME:
        raise RomError("unsafe_zip", "Caminho vazio ou muito longo")
    if "\x00" in name or "\\" in name or name.startswith("/") or re.match(r"^[a-zA-Z]:", name):
        raise RomError("unsafe_zip", name[:90])
    if any(c in ("", ".", "..") for c in name.rstrip("/").split("/")):
        raise RomError("unsafe_zip", name[:90])
    if any(ord(c) < 32 for c in name):
        raise RomError("unsafe_zip", "Caracteres de controle")
    if name.startswith("__MACOSX/") or name.endswith("/.DS_Store") or name == ".DS_Store":
        return False
    return True

def out_path(root, name):
    name_ok(name)
    target = root.joinpath(*name.rstrip("/").split("/"))
    if os.path.commonpath((str(root), str(target))) != str(root):
        raise RomError("unsafe_zip", name)
    return target

def check_space(root, unpacked, margin):
    if unpacked < 0:
        raise RomError("bad_zip", "Tamanho desconhecido")
    available = shutil.disk_usage(root).free
    if available < unpacked + margin:
        raise RomError("no_space", f"{unpacked + margin}|{available}")

def write_file(reader, dest, expected, cancel):
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Nao segue links preexistentes nem substitui arquivos no staging.
    with open(dest, "xb") as target:
        total = 0
        while True:
            check_cancel(cancel)
            part = reader.read(CHUNK)
            if not part:
                break
            target.write(part)
            total += len(part)
            if total > expected:
                raise RomError("bad_zip", "Arquivo extraído excede o tamanho informado")
        if total != expected:
            raise RomError("bad_zip", f"Tamanho extraído incorreto: {dest.name}")

def zip_extract(src, content, root, margin, cancel):
    try:
        with zipfile.ZipFile(src) as z:
            infos = z.infolist()
            if not infos or len(infos) > MAX_ENTRIES:
                raise RomError("bad_zip", "Número de arquivos inválido")
            total = 0
            for x in infos:
                name_ok(x.filename)
                mode = (x.external_attr >> 16) & 0xffff
                kind = stat.S_IFMT(mode)
                if kind and kind not in (stat.S_IFDIR, stat.S_IFREG):
                    raise RomError("unsafe_zip", "Link ou arquivo especial no ZIP")
                if x.flag_bits & 0x1:
                    raise RomError("encrypted", "ZIP com senha requer tratamento separado")
                total += x.file_size
            check_space(root, total, margin)
            emit("PHASE", "extract", len(infos))
            for idx, info in enumerate(infos, 1):
                check_cancel(cancel)
                if name_ok(info.filename):
                    dst = out_path(content, info.filename)
                    if info.is_dir():
                        dst.mkdir(parents=True, exist_ok=True)
                    else:
                        with z.open(info) as reader:
                            write_file(reader, dst, info.file_size, cancel)
                emit("PROGRESS", "extract", idx, len(infos))
    except (zipfile.BadZipFile, EOFError, RuntimeError) as exc:
        raise RomError("bad_zip", str(exc)) from exc

def tar_extract(src, content, root, margin, cancel):
    try:
        with tarfile.open(src, "r:*") as z:
            infos = z.getmembers()
            if not infos or len(infos) > MAX_ENTRIES:
                raise RomError("bad_zip", "Número de arquivos inválido")
            total = 0
            for x in infos:
                name_ok(x.name)
                if not (x.isfile() or x.isdir()):
                    raise RomError("unsafe_zip", "Link ou dispositivo no TAR")
                total += x.size if x.isfile() else 0
            check_space(root, total, margin)
            emit("PHASE", "extract", len(infos))
            for idx, member in enumerate(infos, 1):
                check_cancel(cancel)
                if name_ok(member.name):
                    dst = out_path(content, member.name)
                    if member.isdir():
                        dst.mkdir(parents=True, exist_ok=True)
                    else:
                        reader = z.extractfile(member)
                        if reader is None:
                            raise RomError("bad_zip", member.name)
                        with reader:
                            write_file(reader, dst, member.size, cancel)
                emit("PROGRESS", "extract", idx, len(infos))
    except (tarfile.TarError, EOFError, OSError) as exc:
        raise RomError("bad_zip", str(exc)) from exc

def seven_extract(src, content, root, margin, cancel, binary):
    if not binary or not os.path.isfile(binary) or not os.access(binary, os.X_OK):
        raise RomError("no_extractor", "7z/RAR")
    try:
        listing = subprocess.run([binary, "l", "-slt", "-p-", str(src)],
                                 capture_output=True, text=True, errors="replace")
    except OSError as exc:
        raise RomError("no_extractor", str(exc)) from exc
    if listing.returncode > 1:
        raise RomError("bad_zip", "Não foi possível listar o arquivo com 7-Zip")
    # O primeiro bloco e o cabecalho do proprio arquivo, NAO um item.
    section = listing.stdout.split("----------", 1)
    if len(section) != 2:
        raise RomError("bad_zip", "7-Zip não retornou uma lista de itens")
    infos = re.split(r"\n\s*\n", section[1])
    count = 0
    total = 0
    for block in infos:
        fields = {}
        for line in block.splitlines():
            if " = " in line:
                k, v = line.split(" = ", 1)
                fields[k] = v
        name = fields.get("Path")
        if not name:
            continue
        count += 1
        name_ok(name)
        if any(x in fields for x in ("Symbolic Link", "Hard Link")):
            raise RomError("unsafe_zip", "Links no pacote 7z/RAR")
        attrs = fields.get("Attributes", "")
        if attrs.startswith("l") or attrs.startswith("L") or attrs.startswith("h"):
            raise RomError("unsafe_zip", "Link no pacote 7z/RAR")
        total += int(fields.get("Size", "0") or "0")
    if count == 0 or count > MAX_ENTRIES:
        raise RomError("bad_zip", "Lista 7z/RAR vazia ou muito longa")
    check_space(root, total, margin)
    emit("PHASE", "extract", 1)
    check_cancel(cancel)
    cmd = [binary, "x", "-y", "-p-", "-mmt1", "-o" + str(content), str(src)]
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    # O controle de cancelamento e observado durante a extracao longa.
    import time
    while proc.poll() is None:
        if Path(cancel).exists():
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
            raise RomError("cancelled")
        time.sleep(0.2)
    err = (proc.stderr.read(500) if proc.stderr else b"").decode("utf-8", "replace")
    if proc.returncode > 1:
        raise RomError("bad_zip", err[:120])
    for item in content.rglob("*"):
        if item.is_symlink() or not (item.is_file() or item.is_dir()):
            raise RomError("unsafe_zip", "Link ou item especial após extração")
    emit("PROGRESS", "extract", 1, 1)

def validate_root(dest, system):
    if system not in ALLOWED:
        raise RomError("invalid_system", system)
    root = Path("/roms2" if str(dest).startswith("/roms2/") else "/roms")
    folder = "psp" if system == "psp-minis" else system
    allowed = (str(root) + "/" + folder)
    aliases = {"megadrive": "genesis", "mastersystem": "sms", "mame": "mame2003"}
    if system in aliases:
        valid = {allowed, str(root) + "/" + aliases[system]}
    else:
        valid = {allowed}
    if str(dest) not in valid:
        raise RomError("invalid_system", "Destino inesperado")
    if not root.is_dir() or root.is_symlink():
        raise RomError("no_ports_dir", "Cartão indisponível")
    if dest.is_symlink() or (dest.exists() and not dest.is_dir()):
        raise RomError("unsafe_zip", "Destino é link ou arquivo")
    if dest.exists() and dest.stat().st_dev != root.stat().st_dev:
        raise RomError("unsafe_zip", "Destino aponta para outro dispositivo")
    if not dest.exists():
        dest.mkdir(mode=0o755)
    return root

def game_files(content):
    # Pastas de encapsulamento unico: mantem a estrutura interna dos discos.
    folder = content
    while True:
        items = [x for x in folder.iterdir() if x.name not in ("__MACOSX", ".DS_Store")]
        if len(items) == 1 and items[0].is_dir():
            folder = items[0]
        else:
            return folder

def run(a):
    src = Path(a.source)
    dest = Path(a.dest)
    stage = Path(a.stage)
    if not src.is_file() or src.is_symlink():
        raise RomError("empty_file", "Download não encontrado")
    if not re.fullmatch(r"[a-zA-Z0-9_-]{1,120}", a.slug):
        raise RomError("internal", "Identificador do jogo inválido")
    if not a.filename or len(a.filename.encode("utf-8")) > 200 or "/" in a.filename or "\\" in a.filename:
        raise RomError("internal", "Nome inválido")
    if a.filename in (".", ".."):
        raise RomError("internal", "Nome inválido")
    root = validate_root(dest, a.system)
    if stage.is_symlink() or os.path.commonpath((str(stage.resolve()), str(dest.resolve()))) == str(dest.resolve()):
        raise RomError("unsafe_zip", "Pasta temporária inválida")
    stage.mkdir(parents=True, exist_ok=True)
    # Nunca instalar a partir de uma pasta de staging preexistente.
    content = stage / "rom_content"
    if content.exists():
        raise RomError("internal", "Área temporária ocupada")
    content.mkdir()
    fmt = a.format
    suffix = Path(a.filename).suffix.lower().lstrip(".")
    allowed = ALLOWED[a.system]
    direct = fmt == "rom_direct" or (fmt == "zip" and a.system in DIRECT_ZIP and suffix == "zip")
    if direct:
        if fmt == "zip":
            try:
                with zipfile.ZipFile(src) as archive:
                    if not archive.infolist():
                        raise RomError("bad_zip", "ZIP vazio")
            except zipfile.BadZipFile as exc:
                raise RomError("bad_zip", str(exc)) from exc
        if suffix not in allowed:
            raise RomError("unsupported_rom", f"{a.system}: .{suffix}")
        target_name = a.filename
        staged = src
    else:
        if fmt == "zip":
            zip_extract(src, content, root, a.margin, a.cancel)
        elif fmt == "tar":
            tar_extract(src, content, root, a.margin, a.cancel)
        elif fmt in ("7z", "rar", "zip7"):
            seven_extract(src, content, root, a.margin, a.cancel, a.sevenzip)
        else:
            raise RomError("unsupported_rom", fmt)
        extracted = game_files(content)
        files = [x for x in extracted.rglob("*") if x.is_file()]
        blocked = {"sh", "exe", "dll", "so", "bat", "cmd", "ps1", "elf", "desktop"}
        if any(x.suffix.lower().lstrip(".") in blocked for x in files):
            raise RomError("unsafe_zip", "Executável ou script dentro do pacote de ROMs")
        if not files:
            raise RomError("empty_pkg", "Arquivo compactado sem ROM")
        # CPS: o .7z individual e um romset arcade. Em vez de instalar
        # chips soltos, conservar o nome do conjunto em um ZIP compativel.
        if a.system in {"cps1", "cps2", "cps3"} and fmt == "7z" and suffix == "7z":
            target_name = Path(a.filename).stem + ".zip"
            staged = stage / "arcade_romset.zip"
            if len(files) == 1 and files[0].suffix.lower() == ".zip":
                with zipfile.ZipFile(files[0]) as archive:
                    if not archive.infolist() or archive.testzip() is not None:
                        raise RomError("bad_zip", "ROMset ZIP inválido")
                staged = files[0]
            else:
                if any(x.suffix.lower() in {".zip", ".7z", ".rar"} for x in files):
                    raise RomError("unsupported_rom", "Pacote de múltiplos ROMsets")
                check_space(root, sum(x.stat().st_size for x in files) + 128 * len(files) + 65536, a.margin)
                with zipfile.ZipFile(staged, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=1) as archive:
                    for item in sorted(files):
                        check_cancel(a.cancel)
                        rel = item.relative_to(extracted).as_posix()
                        name_ok(rel)
                        with item.open("rb") as reader, archive.open(rel, "w") as writer:
                            while True:
                                check_cancel(a.cancel)
                                block = reader.read(CHUNK)
                                if not block:
                                    break
                                writer.write(block)
        else:
            # Pelo menos um arquivo precisa corresponder ao sistema selecionado.
            if not any(x.suffix.lower().lstrip(".") in allowed and
                       (x.suffix.lower() != ".zip" or a.system in DIRECT_ZIP) for x in files):
                raise RomError("unsupported_rom", f"Nenhum arquivo compatível com {a.system}")
            if len(files) == 1 and files[0].parent == extracted:
                target_name = files[0].name
                staged = files[0]
            else:
                target_name = a.slug[:100]
                staged = extracted
    if not name_ok(target_name) or target_name in (".", ".."):
        raise RomError("unsafe_zip", "Nome final inválido")
    target = dest / target_name
    if os.path.lexists(target):
        raise RomError("exists", "Já existe: " + target.name)
    check_cancel(a.cancel)
    emit("PHASE", "install", 1)
    if staged == src:
        # FAT32/exFAT dos cartoes SD nao suportam hard links (os.link -> EPERM).
        # Criacao exclusiva 'xb' impede sobrescrever ROMs existentes, inclusive
        # se outra operacao criar o destino apos a verificacao anterior.
        created = False
        try:
            with src.open("rb") as reader:
                with target.open("xb") as writer:
                    created = True
                    while True:
                        check_cancel(a.cancel)
                        block = reader.read(CHUNK)
                        if not block:
                            break
                        writer.write(block)
                    writer.flush()
                    os.fsync(writer.fileno())
        except FileExistsError as exc:
            raise RomError("exists", "Já existe: " + target.name) from exc
        except (OSError, RomError) as exc:
            # Nao deixar ROM parcial no cartao apos falha/cancelamento.
            # Apenas apaga se esta operacao criou o destino.
            if created:
                try:
                    target.unlink()
                except OSError:
                    pass
            if isinstance(exc, RomError):
                raise
            raise RomError("install_failed", str(exc)) from exc
    else:
        try:
            os.rename(staged, target)
        except OSError as exc:
            raise RomError("install_failed", str(exc)) from exc
    emit("PROGRESS", "install", 1, 1)
    emit("DONE", target_name, "1" if direct else "0")

def main():
    parser = argparse.ArgumentParser()
    for field in ("source", "stage", "dest", "system", "filename", "slug", "format", "cancel"):
        parser.add_argument("--" + field, required=True)
    parser.add_argument("--margin", type=int, default=33554432)
    parser.add_argument("--sevenzip", default="")
    a = parser.parse_args()
    try:
        run(a)
    except RomError as exc:
        emit("ERROR", exc.code, exc.msg[:160])
        sys.exit(2)
    except (OSError, ValueError, UnicodeError, shutil.Error, RuntimeError) as exc:
        emit("ERROR", "internal", str(exc)[:160])
        sys.exit(2)

if __name__ == "__main__":
    main()
