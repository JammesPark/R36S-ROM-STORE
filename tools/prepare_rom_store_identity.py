#!/usr/bin/env python3
"""Prepare the ROM STORE rebrand only. Keep source attribution and data paths."""
from pathlib import Path
import re
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def write(p,s): (ROOT/p).write_text(s,encoding="utf-8")
def rename(s):
    for a,b in [
        ("R36S ROMS STORE & HUB","R36S ROM STORE"),
        ("R36S ROM STORE & HUB","R36S ROM STORE"),
        ("R36S ROMS HUB STORE","R36S ROM STORE"),
        ("R36S ROM HUB STORE","R36S ROM STORE"),
        ("R36S ROMS STORE","R36S ROM STORE"),
        ("R36S_ROMS_STORE","R36S_ROM_STORE"),
        ("R36S ROMs Store","R36S ROM Store"),
        ("R36S Roms Store","R36S ROM Store"),
        ("r36s roms store.sh","r36s rom store.sh"),
    ]: s=s.replace(a,b)
    return s
# Active source, build and test code. Not historical source imports, license, or old release notes.
for d in ["src","port","tools","tests"]:
    for p in (ROOT/d).rglob("*"):
        if p.is_file() and p.suffix in {".lua",".sh",".py",".json",".md",".txt",".html",".ini"} and p.name!="prepare_rom_store_identity.py":
            if p.name.startswith("LICENSE"): continue
            try: s=p.read_text(encoding="utf-8")
            except UnicodeError: continue
            if d=="tools":
                # ROM build helpers inherited from PORTS, not the PORTS project itself.
                if p.name in {"version.py","make_update.py"}:
                    s=s.replace("R36SPORTSBR STORE","R36S ROM STORE")
            new=rename(s)
            if new!=s:p.write_text(new,encoding="utf-8")
for name in ["README.md","NOTICE.md","CONTRIBUTORS.md"]:
    write(name,rename(read(name)))
p=ROOT/"port/R36S ROMS STORE.sh"
if p.exists():p.rename(p.with_name("R36S ROM STORE.sh"))
# Keep old directory/LOVE identity to preserve local files. No official OTA even with stale override.
p="src/config.lua";s=read(p)
s=re.sub(r'^C\.EDITION\s*=.*$', 'C.EDITION = "Experimental"  -- identidade ROM STORE isolada',s,flags=re.M)
s=re.sub(r'^C\.UPDATE_URL\s*=.*$', 'C.UPDATE_URL = ""  -- canal independente ainda não configurado\nC.EXPERIMENTAL_NO_OTA = true',s,flags=re.M)
s=s.replace('Ports de jogos e utilitários para o console R36S, criados por fãs e para fãs.','ROMs e ferramentas para o console R36S, criadas por fãs e para fãs.')
# Protect both launcher names and preserve original source project protection.
s=s.replace('["r36sromsstore"] = true,','["r36sromsstore"] = true, ["r36s rom store.sh"] = true, ["r36s roms store.sh"] = true,')
write(p,s)
p="src/core/update.lua";s=read(p).replace("function M.source_url()\n","function M.source_url()\n  if C.EXPERIMENTAL_NO_OTA then return nil end\n")
write(p,s)
# Explicit project independence on About; maintain translated credit strings.
p="src/ui/screens/about.lua";s=read(p)
s=s.replace('R36S ROM STORE é uma loja independente de ROMs e ferramentas para o console R36S.','R36S ROM STORE é uma loja independente de ROMs e ferramentas para o console R36S.')
write(p,s)
# Remove old official-release references from README; keep real historical docs as historical.
p="README.md";s=read(p)
s=re.sub(r'  <a href="https://github\.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest">.*?</a>\n','  <img alt="Experimental" src="https://img.shields.io/badge/Canal-Experimental-2563eb?style=for-the-badge">\n',s)
s=s.replace("— beta oficial.","— experimental de identidade, sem OTA.")
start=s.index("## ⬇️ Downloads")
end=s.index("## 🎨 Temas e interface",start)
s=s[:start]+"## ⬇️ Downloads\n\nEsta edição experimental tem distribuição privada para teste manual. Gere o ZIP com \`sh tools/build.sh\`. Não há versão pública nem OTA deste canal.\n\n---\n\n"+s[end:]
start=s.index("| Menu principal — Pulse")
end=s.index("---",start)
s=s[:start]+"As capturas da marca anterior foram retiradas da apresentação atual. Novas capturas serão feitas após validar o visual.\n\n"+s[end:]
s=s.replace("[página de download oficial](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest)","pacote experimental privado")
s=s.replace("[GitHub Issues](https://github.com/JammesPark/R36S-ROMS-HUB-STORE/issues)","canal de testes do projeto")
s=s.replace("O pacote oficial é preparado","O pacote experimental é preparado")
s=s.replace("Consulta online, confirmação, verificação de pacote, histórico e recuperação.","OTA desativada nesta edição; verificação de pacote, histórico e recuperação preservados.")
s=s.replace("O aplicativo tem origem no R36S PORT HUB, de Lag do Lira, e preserva a autoria de ferramentas e temas herdados.","O aplicativo tem origem no R36S PORT HUB, de Lag do Lira, e preserva a autoria de ferramentas e temas herdados. Não é uma loja oficial, afiliada ou mantida pelo projeto-base.")
write(p,s)
p="port/r36sromsstore/README.md";s=read(p).replace("— beta oficial.","— experimental de identidade, sem OTA.")
s=re.sub(r"Atualizações pelo canal oficial: https://github\.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases\.","Atualizações online desativadas até configurar o novo canal independente.",s)
write(p,s)
# Existing approved launcher icon already has R36S ROM STORE without HUB.
# Generate logo variants with transparent padding, preserve pixel art and developer mark.
source=Image.open(ROOT/"port/r36sromsstore/logo.png").convert("RGBA")
bbox=source.getchannel("A").getbbox()
assert bbox
source=source.crop(bbox)
sizes={"logo_header.png":(140,40,2),"logo_menu.png":(218,74,4),"logo_about.png":(132,62,3),"logo_splash.png":(252,170,5)}
for folder in [ROOT/"src/assets/logo", ROOT/"src/themes/default",ROOT/"src/themes/neongrid"]:
    for name,(w,h,pad) in sizes.items():
        scale=min((w-2*pad)/source.width,(h-2*pad)/source.height)
        im=source.resize((max(1,round(source.width*scale)),max(1,round(source.height*scale))),Image.Resampling.NEAREST if scale>=1 else Image.Resampling.LANCZOS)
        out=Image.new("RGBA",(w,h));out.alpha_composite(im,((w-im.width)//2,(h-im.height)//2));out.save(folder/name,optimize=True)
# Remove old PORTS-branded source artwork and generator so it cannot overwrite the new ROM mark.
for p in ["tools/brand/logo_oficial_cloud.webp","tools/brand/logo_alternativa_sem_bandeira.webp","tools/make_brand_logos.py","tools/tests/test_brand_logos.py"]:
    f=ROOT/p
    if f.exists():f.unlink()
# The committed old packed game is stale; regenerated during the workflow.
old=ROOT/"port/r36sromsstore/game.love"
if old.exists(): old.unlink()
write("docs/IDENTIDADE_EXPERIMENTAL.md", """# R36S ROM STORE — identidade experimental

Base: main 0.7.0-beta. Apenas identidade, sem integrar as branches de armazenamento,
região ou Temas Store. Mantidos o projeto-base R36S PORT HUB, autoria de Lag do Lira,
GPL-3.0, créditos dos temas Pulse e Matrix e arquivos de licença.
O símbolo existente do launcher já contém R36S ROM STORE e foi reutilizado nos
cabeçalhos, menu, Sobre e splash. Logos do desenvolvedor preservadas.
Instalador renomeado para R36S ROM STORE.sh e ZIP para R36S_ROM_STORE_<versão>.zip.
Diretório interno r36sromsstore, save identity, IDs e catálogo preservados.
OTA desativada inclusive com update_url.txt legado. URL do catálogo de ROMs
permanece funcionando na origem antiga, que não foi renomeada.
Os documentos históricos e backups do projeto preservam referências de época;
R36 Hub OS refere-se a um sistema externo, não à identidade desta loja.
Capturas anteriores removidas da apresentação atual, não alteradas artificialmente.
Novo repositório ainda precisa ser criado antes de migrar o código ou configurar
novos endereços; nenhuma publicação oficial autorizada.
""")
print("Identity prepared: name, active strings, launcher, docs, 12 logo variants, OTA disabled")
