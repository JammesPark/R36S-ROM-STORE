#!/usr/bin/env python3
"""Audit real theme previews from source repos; never substitute another theme's screenshot.
Only URL metadata is distributed for OGA and other third-party repositories.
"""
import os, sys, re, json, io, base64, concurrent.futures
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote, urlparse, unquote
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
CAT=ROOT/"src/catalog"
TOKEN=os.environ.get("GH_TOKEN","")
USERS=("Jetup13","CodyV59","farfenkugell","EmuELEC","RetroPie")
OGA="https://raw.githubusercontent.com/Jetup13/Emulationstation-OGA-Theme-Gallery/main/README.md"
MAX=10*1024*1024
def fetch(url, api=False):
    h={"User-Agent":"R36S-ROM-Store-preview-audit","Accept":"application/vnd.github+json" if api else "*/*"}
    if api and TOKEN and url.startswith("https://api.github.com/"):
        h["Authorization"]="Bearer "+TOKEN
    with urlopen(Request(url,headers=h),timeout=15) as r:
        b=r.read(MAX+1)
        if len(b)>MAX: raise ValueError("response too large")
        return b
def api(path):
    return json.loads(fetch("https://api.github.com/"+path,True))
def key(url):
    m=re.match(r"https://github\.com/([\w.-]+)/([\w.-]+)",url or "",re.I)
    return "/".join(m.groups()).lower() if m else None
def raw(repo,branch,path):
    return "https://raw.githubusercontent.com/"+repo+"/"+quote(branch,safe="/")+"/"+quote(path,safe="/")
def valid_image(url):
    if not url.startswith("https://"): return False
    try:
        with Image.open(io.BytesIO(fetch(url))) as im:
            w,h=im.size
            # LÖVE native PNG/JPEG support; don't accept SVG, badges, tiny logos, etc.
            if im.format not in ("PNG","JPEG") or w<240 or h<200 or w*h>4000000 or not 0.65<=w/h<=3.2: return False
            im.verify()
        return True
    except Exception: return False
def readme_images(text,repo,branch):
    # Only image links, not arbitrary background art; favor explicit screenshots.
    images=re.findall(r"!\[[^\]]*\]\(([^)\s]+)(?:\s+[^)]*)?\)",text)
    images+=re.findall(r'<img\b[^>]*\bsrc=["\x27]([^"\x27]+)',text,re.I)
    for p in images:
        p=unquote(p)
        if not re.search(r"\.(png|jpe?g)(?:\?.*)?$",p,re.I): continue
        if re.search(r"badge|logo|banner|icon|avatar|button|donat|shield",p,re.I): continue
        if p.startswith("https://"):
            m=re.match(r"https://github\.com/([^/]+/[^/]+)/(?:blob|raw)/([^/]+)/(.*)",p)
            if m:
                p=raw(m[1],m[2],m[3].split("?")[0])
            elif not p.startswith(("https://raw.githubusercontent.com/","https://user-images.githubusercontent.com/","https://github.com/user-attachments/","https://private-user-images.githubusercontent.com/")): continue
            # Don't use images hosted in another theme's repository.
            if p.startswith("https://raw.githubusercontent.com/") and not p.lower().startswith("https://raw.githubusercontent.com/"+repo.lower()+"/"): continue
            yield p
        elif not p.startswith(("/","../")):
            yield raw(repo,branch,p.removeprefix("./").split("?")[0])
def candidates(repo,branch):
    try:
        d=api("repos/"+repo+"/readme")
        readme=base64.b64decode(d.get("content","")).decode("utf-8","replace")
        yield from readme_images(readme,repo,branch)
    except Exception: pass
    try:
        d=api("repos/"+repo+"/git/trees/"+quote(branch,safe="")+"?recursive=1")
        paths=[]
        for x in d.get("tree",[]):
            p=x.get("path","")
            if x.get("type")!="blob" or not re.search(r"\.(png|jpe?g)$",p,re.I): continue
            if not re.search(r"(^|[/_. -])(screenshots?|previews?|screenshot\d+|preview\d+)([/_. -]|$)",p,re.I): continue
            if re.search(r"badge|logo|banner|icon|avatar|button",p,re.I): continue
            paths.append(p)
        for p in sorted(paths,key=lambda p:(0 if re.search(r"system|gamelist",p,re.I) else 1,len(p),p))[:8]:
            yield raw(repo,branch,p)
    except Exception: pass
def gallery_docs():
    # The official RetroPie docs explicitly map each theme to its own two views.
    out={}
    url="https://raw.githubusercontent.com/RetroPie/RetroPie-Docs/master/docs/Themes.md"
    try:
        for line in fetch(url).decode("utf-8","replace").splitlines():
            m=re.match(r"^\|\s*([\w-]+)\s*\|",line)
            if not m: continue
            urls=re.findall(r'<img src="(https://raw.githubusercontent.com/wetriner/es-theme-gallery/[^"]+)"',line)
            if urls:
                # Original gallery repository is now 404. A preserved mirror contains
                # the same exact theme-named files. Pin its commit, never infer a different theme.
                mirrors=[u.replace("wetriner/es-theme-gallery/master/","V0rt3x667/es-theme-gallery/1a52b6cb926889173f98bdf2270d09dde86c7a0f/") for u in urls]
                out["retropie/es-theme-"+m[1].lower()]=mirrors
    except Exception as exc: print("RetroPie documentation:",str(exc))
    return out
def check_download(url):
    if not isinstance(url,str) or not url.startswith("https://"):
        return {"status":"unknown","reason":"missing HTTPS link"}
    try:
        req=Request(url,headers={"User-Agent":"R36S-ROM-Store-audit","Range":"bytes=0-3"})
        with urlopen(req,timeout=25) as resp:
            header=resp.read(4)
            return {"status":"zip_header" if header==b"PK\x03\x04" else "not_zip","http":resp.status,"final_url":resp.geturl()}
    except Exception as exc:
        code=getattr(exc,"code",None)
        return {"status":"missing" if code in (404,410) else "unverified","http":code,"reason":str(exc)[:200]}
def main():
    base=json.loads((CAT/"es_themes.json").read_text())["themes"]
    tg=json.loads((CAT/"themegallery_metadata.json").read_text())
    records={}
    snapshot={"time":0,"gallery":[],"collections":{}}
    retro=gallery_docs()
    for x in base:
        k=key(x["project_url"])
        if k: records[k]={"repo":x["project_url"].split("github.com/")[1].rstrip("/"),"name":x["name"],"url":x.get("preview",""),"source":"base","download_url":x["download_url"],"compat":x.get("compat",{}),"resolution":x.get("resolution")}
    text=fetch(OGA).decode("utf-8","replace")
    for line in text.splitlines():
        m=re.match(r"^\|\s*\[([^]]+)\]\((https://github\.com/[^/]+/[^/)]+)\/?\)",line)
        if not m: continue
        k=key(m[2])
        im=re.search(r"!\[[^]]*\]\((https?://[^)\s]+)\)",line)
        repo=m[2].split("github.com/")[1].rstrip("/")
        cells=[x.strip().lower() for x in line.split("|")[3:8]]
        res=dict(zip(("480x320","640x480","854x480","960x544","720x720"),[x if x in ("yes","no","untested") else "untested" for x in cells]))
        snapshot["gallery"].append({"owner":repo.split("/")[0],"repo":repo.split("/")[1],"name":m[1],"url":m[2],"preview":im[1] if im else None,"res":res})
        r=records.setdefault(k,{"repo":repo,"name":m[1],"source":"oga","download_url":m[2]+"/archive/HEAD.zip","compat":{"arkos":"experimental","darkos":"experimental","darkosre":"experimental"}})
        r["res"]=res
        if not r.get("url") and im:r["url"]=im[1]
    errors=[]
    for user in USERS:
        try:
            repos=api("users/"+user+"/repos?per_page=100")
            snapshot["collections"][user]=[]
            for x in repos:
                if x["name"].lower().startswith("es-theme") and not x["fork"] and not x["archived"]:
                    k=x["full_name"].lower()
                    snapshot["collections"][user].append({"owner":x["owner"]["login"],"repo":x["name"],"url":x["html_url"],"branch":x["default_branch"],"description":x.get("description"),"updated":(x.get("pushed_at") or "")[:10]})
                    r=records.setdefault(k,{"repo":x["full_name"],"name":x["name"],"source":"collection","download_url":x["html_url"]+"/archive/refs/heads/"+x["default_branch"]+".zip","compat":{}})
                    r["branch"]=x["default_branch"]
        except Exception as exc: errors.append(user+": "+str(exc))
    for g in tg:
        k=key(g["project_url"])
        r=records.setdefault(k,{"repo":g["project_url"].split("github.com/")[1].rstrip("/"),"name":g["name"],"source":"themegallery","download_url":g["download_url"],"compat":{}})
        r["local"]=g["previews"][0]
    def inspect(item):
        k,r=item
        if r.get("local"):return k,{"source":"themegallery","local":r["local"],"name":r["name"]}
        if k in retro:
            urls=[u for u in retro[k] if valid_image(u)]
            if urls:return k,{"source":"retropie-docs","url":urls[0],"previews":urls,"name":r["name"]}
        url=r.get("url","")
        if url and valid_image(url):return k,{"source":r["source"],"url":url,"name":r["name"]}
        repo=r["repo"]
        branch=r.get("branch")
        if not branch:
            try:
                d=api("repos/"+repo)
                repo=d["full_name"];branch=d["default_branch"]
            except Exception: return k,{"source":r["source"],"name":r["name"],"missing":True}
        seen=set()
        for u in candidates(repo,branch):
            if u in seen:continue
            seen.add(u)
            if len(seen)>12: break
            if valid_image(u):return k,{"source":"repo-preview","url":u,"name":r["name"]}
        return k,{"source":r["source"],"name":r["name"],"missing":True}
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        index=dict(pool.map(inspect,sorted(records.items())))
    def link(item):
        k,r=item
        result=check_download(r.get("download_url"))
        result.update({"url":r.get("download_url"),"name":r["name"],"compatibility":r.get("compat",{}),"resolution":r.get("res",{})})
        # A theme.xml in the upstream tree establishes structure, not firmware compatibility.
        try:
            branch=r.get("branch") or "HEAD"
            tree=api("repos/"+r["repo"]+"/git/trees/"+quote(branch,safe="")+"?recursive=1")
            paths=[x["path"] for x in tree.get("tree",[]) if x["type"]=="blob" and x["path"].lower().endswith("theme.xml") and x["path"].count("/")<=1]
            result["theme_xml_count"]=len(paths)
            result["tree_truncated"]=bool(tree.get("truncated"))
        except Exception as exc:result["tree_error"]=str(exc)[:200]
        return k,result
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
        links=dict(pool.map(link,sorted(records.items())))
    for k,v in links.items():
        index[k]["download"]=v
    (CAT/"es_gallery_snapshot.json").write_text(json.dumps(snapshot,ensure_ascii=False)+"\n",encoding="utf-8")
    counts={s:sum(v["status"]==s for v in links.values()) for s in ("zip_header","missing","not_zip","unverified","unknown")}
    print("DOWNLOAD AUDIT",json.dumps(counts))
    missing=[{"repo":k,"name":v["name"],"source":v["source"]} for k,v in index.items() if v.get("missing")]
    stats={"total":len(index),"local":sum("local" in v for v in index.values()),"remote":sum("url" in v for v in index.values()),"missing":len(missing),"collection_errors":errors}
    report={"counts":stats,"missing":missing,"download_counts":counts,"links":links,"index":index}
    (CAT/"es_theme_preview_index.json").write_text(json.dumps(index,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    (ROOT/"build").mkdir(exist_ok=True)
    (ROOT/"build/theme_preview_audit.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(stats,ensure_ascii=False))
    for m in missing:print("NO VERIFIED SCREENSHOT",m["repo"])
if __name__=="__main__":main()
