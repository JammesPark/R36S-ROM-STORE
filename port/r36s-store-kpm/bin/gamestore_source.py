#!/usr/bin/env python3
"""Adaptador independente para o catálogo remoto usado pelo GameStoreBR.
Não importa nem redistribui o aplicativo/arquivos enviados pelo usuário.
Sem instalação/executável automático: ROMs são baixadas como arquivo no SD.
"""
import hashlib
import ipaddress
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API_PATH = "/getgames.php"
API_HOST = "r36swiki.com"
ALLOWED = frozenset("""3do amigacd32 atari2600 nes snes gba gb gbc psx mame neogeo
ports megadrive genesis n64 nds psp dreamcast saturn pcengine mastersystem
gamegear""".split())
CATEGORY_ALIAS = {"genesis": "megadrive"}
MAX_JSON = 3 * 1024 * 1024
MAX_DOWNLOAD = 16 * 1024**3
HOME = os.environ.get("R36S_STORE_HOME", "/roms/ports/r36s-store-kpm")
STATE = os.path.join(HOME, "state")
STATUS = os.path.join(STATE, "gamestore_status.json")
LOCK = os.path.join(STATE, "gamestore.lock")

def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp." + str(os.getpid())
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)

def status(phase, message, **extra):
    save_json(STATUS, {"phase": phase, "message": message, **extra})

def category_name(raw):
    raw = str(raw or "").lower()
    if raw == "all":
        return "ALL"
    if raw not in ALLOWED:
        raise ValueError("Plataforma não permitida: " + raw)
    return CATEGORY_ALIAS.get(raw, raw)

def safe_url(raw, *, allow_http=False):
    url = urllib.parse.urlsplit(str(raw))
    if url.scheme not in (("http", "https") if allow_http else ("https",)):
        raise ValueError("Endereço não permitido")
    if not url.hostname or url.username or url.password:
        raise ValueError("Host inválido")
    hostname = url.hostname.lower()
    if hostname in ("localhost",) or hostname.endswith(".local"):
        raise ValueError("Host privado")
    try:
        ip = ipaddress.ip_address(hostname)
        if not ip.is_global:
            raise ValueError("Host privado")
    except ValueError as exc:
        if str(exc) == "Host privado":
            raise
    return urllib.parse.urlunsplit(url)

class NoLocalRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        safe_url(newurl, allow_http=True)
        return super().redirect_request(req, fp, code, msg, headers, newurl)

OPENER = urllib.request.build_opener(NoLocalRedirect())

def load_api(action, **params):
    qs = urllib.parse.urlencode({"action": action, **params})
    last = None
    for proto in ("https", "http"):
        url = f"{proto}://{API_HOST}{API_PATH}?{qs}"
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "R36S-Ports-BR-Store-KPM/0.2"})
            with OPENER.open(req, timeout=22) as r:
                raw = r.read(MAX_JSON + 1)
                if len(raw) > MAX_JSON:
                    raise ValueError("Resposta grande demais")
                data = json.loads(raw.decode("utf-8"))
                if not isinstance(data, dict) or data.get("success") is not True:
                    raise ValueError("API indisponível ou resposta inválida")
                return data
        except (OSError, urllib.error.URLError, ValueError) as exc:
            last = exc
            # O aplicativo GameStoreBR enviado usa HTTP; aceita fallback somente
            # para esse host, sem executar qualquer conteúdo recebido.
    raise RuntimeError("GameStoreBR indisponível: " + str(last))

def categories():
    data = load_api("categories")
    result = [{"category": "ALL", "count": 0}]
    total = 0
    for entry in data.get("categories", [])[:80]:
        if not isinstance(entry, dict):
            continue
        try:
            cat = category_name(entry.get("category"))
            if cat == "ALL":
                continue
        except ValueError:
            continue
        count = max(0, int(entry.get("count", 0) or 0))
        total += count
        result.append({"category": cat, "count": count})
    result[0]["count"] = total
    save_json(os.path.join(STATE, "gamestore_categories.json"), {"categories": result})
    status("done", "Categorias GameStoreBR carregadas", task="categories", count=len(result))

def games(category, page):
    cat = category_name(category)
    page = int(page)
    if not 1 <= page <= 100000:
        raise ValueError("Página inválida")
    params = {"page": page, "limit": 10}
    if cat != "ALL":
        params["category"] = cat
    data = load_api("games", **params)
    clean = []
    for entry in data.get("games", [])[:30]:
        if not isinstance(entry, dict):
            continue
        name = str(entry.get("name") or "").strip()[:160]
        path = str(entry.get("game_path") or "").strip()
        raw_category = entry.get("category", "ports" if cat == "ALL" else cat)
        try:
            platform = category_name(raw_category)
        except ValueError:
            continue
        if platform == "ALL" or not name or not path:
            continue
        if not (path.startswith("http://") or path.startswith("https://")):
            path = urllib.parse.urljoin("http://"+API_HOST+"/", path.lstrip("/"))
        try:
            safe_url(path, allow_http=True)
        except ValueError:
            continue
        clean.append({"name": name, "category": platform, "game_path": path,
                      "image_url": str(entry.get("image_url") or "")[:400]})
    out = {"games": clean, "category": cat, "page": page,
           "total_pages": max(1,int(data.get("total_pages", 1) or 1)),
           "total": max(0,int(data.get("total", 0) or 0))}
    save_json(os.path.join(STATE, "gamestore_games.json"), out)
    status("done", f"{len(clean)} jogos recebidos: {cat}", task="games", page=page)

def target_root(sd):
    if sd not in ("sd1", "sd2"):
        raise ValueError("Cartão inválido")
    base = "/roms" if sd == "sd1" else "/roms2"
    if not os.path.isdir(base) or os.path.islink(base):
        raise ValueError("Cartão não montado")
    if sd == "sd2":
        a = subprocess.check_output(["findmnt", "-T", "/roms", "-no", "SOURCE"], text=True).strip()
        b = subprocess.check_output(["findmnt", "-T", "/roms2", "-no", "SOURCE"], text=True).strip()
        if not a or not b or a == b:
            raise ValueError("SD2 não está montado separadamente")
    return base

def download(url, category, sd, name, checksum=""):
    url = safe_url(url, allow_http=True)
    folder = category_name(category)
    if folder == "ALL":
        raise ValueError("Categoria inválida")
    base = target_root(sd)
    dest = os.path.join(base, folder)
    if os.path.islink(dest):
        raise ValueError("Destino é um link")
    os.makedirs(dest, exist_ok=True)
    basename = urllib.parse.unquote(urllib.parse.urlsplit(url).path.rsplit("/", 1)[-1])
    basename = re.sub(r"[^a-zA-Z0-9_. ()-]", "_", basename).strip(" .")[:160]
    if basename in ("", ".", ".."):
        raise ValueError("Nome de arquivo não identificado no link")
    final = os.path.join(dest, basename)
    if os.path.lexists(final):
        raise ValueError("Arquivo já existe no destino: " + basename)
    if checksum and not re.fullmatch(r"[a-fA-F0-9]{64}", checksum):
        raise ValueError("SHA-256 inválido")
    temp = os.path.join(dest, f".kpm-{os.getpid()}-{basename}.part")
    if os.path.lexists(temp):
        raise ValueError("Download temporário já existe")
    digest = hashlib.sha256()
    count = 0
    try:
        status("downloading", f"Baixando {name[:60]} para {sd.upper()}", task="download")
        req = urllib.request.Request(url, headers={"User-Agent": "R36S-Ports-BR-Store-KPM/0.2"})
        with OPENER.open(req, timeout=40) as response:
            expected = int(response.headers.get("Content-Length") or 0)
            if expected > MAX_DOWNLOAD:
                raise ValueError("Arquivo excede o limite")
            with open(temp, "xb") as out:
                while True:
                    block = response.read(256 * 1024)
                    if not block:
                        break
                    count += len(block)
                    if count > MAX_DOWNLOAD:
                        raise ValueError("Download grande demais")
                    out.write(block)
                    digest.update(block)
                    if count % (1024*1024) < len(block):
                        status("downloading", f"Baixando {name[:60]}", task="download",
                               downloaded=count, expected=expected)
                out.flush()
                os.fsync(out.fileno())
        if count == 0 or (expected and expected != count):
            raise ValueError("Download vazio ou incompleto")
        actual = digest.hexdigest()
        if checksum and actual.lower() != checksum.lower():
            raise ValueError("SHA-256 não confere")
        # Não descompacta ROMs nem executa os arquivos. Evita sobrescrever saves.
        if os.path.lexists(final):
            raise ValueError("Destino ocupado")
        os.rename(temp, final)
        status("done", f"Salvo em {folder}/{basename} ({sd.upper()})",
               task="download", downloaded=count, sha256=actual,
               verified=bool(checksum))
    finally:
        if os.path.exists(temp):
            os.remove(temp)

def run(args):
    os.makedirs(STATE, exist_ok=True)
    os.mkdir(LOCK)
    try:
        if args[0] == "categories":
            status("loading", "Consultando categorias", task="categories")
            categories()
        elif args[0] == "games":
            status("loading", "Consultando jogos", task="games")
            games(args[1], args[2])
        elif args[0] == "download":
            download(*args[1:])
        else:
            raise ValueError("Comando não identificado")
    finally:
        os.rmdir(LOCK)

if __name__ == "__main__":
    try:
        run(sys.argv[1:])
    except Exception as exc:
        status("error", str(exc)[:220], task=sys.argv[1] if len(sys.argv)>1 else "")
        sys.exit(1)
