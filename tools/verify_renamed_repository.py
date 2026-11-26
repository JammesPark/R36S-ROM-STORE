#!/usr/bin/env python3
"""Read-only validation of the renamed public repository's existing endpoints."""
import hashlib, json, re, urllib.request, zlib
from pathlib import Path
root = Path(__file__).resolve().parents[1]
config = (root / "src/config.lua").read_text()
def setting(name):
    return re.search(r'^C\.'+name+r'\s*=\s*"([^"]*)"',config,re.M).group(1)
def fetch(url):
    req=urllib.request.Request(url,headers={"User-Agent":"R36S-ROM-STORE-Validation"})
    with urllib.request.urlopen(req,timeout=30) as r:
        return r.read()
catalog=setting("OWN_CATALOG_URL")
feed=setting("UPDATE_URL")
assert "JammesPark/R36S-ROM-STORE-UPDATES/" in catalog and "JammesPark/R36S-ROM-STORE-UPDATES/" in feed
assert feed.endswith("/main/ota/rom-store/update.json")
assert "/catalogo-estavel/" in catalog
raw=fetch(catalog)
data=json.loads(zlib.decompress(raw))
assert isinstance(data,(dict,list))
print("Catalog validated:",len(raw),"bytes; SHA256",hashlib.sha256(raw).hexdigest())
legacy = feed.replace("/ota/rom-store/", "/ota/")
f=json.loads(fetch(legacy))
assert isinstance(f["version"],str) and re.fullmatch(r"[0-9a-fA-F]{64}",f["sha256"]) and int(f["size"])>0
print("Existing official feed readable:",f["version"],"(legacy endpoint)")
