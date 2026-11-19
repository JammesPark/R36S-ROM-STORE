#!/usr/bin/env python3
# Adaptado de R36S PORT HUB por Lag do Lira, GPL-3.0.
# Original preservado em docs/preservacao/original/tools/mkconsoledb.py.
"""Gera banco experimental de assinaturas da R36SPORTSBR STORE.

Entrada: três JSONs extraídos dos DTBs públicos e r36_devices.ini.
Saída padrão: build/generated-data/console_signatures.json
NÃO altera game/data/console_signatures.json nem executa git clone.
"""
import argparse
import datetime
import json
import re
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "build/generated-data"


def load_entries(path):
    if not path.is_file():
        raise ValueError(f"Arquivo de assinaturas ausente: {path}")
    rows = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(rows, list):
        raise ValueError(f"Esperada lista de assinaturas: {path}")
    return rows


def forbid_live_outputs(out):
    resolved = out.resolve()
    for protected in (ROOT / "game", ROOT / "r36sportsbrstore"):
        if resolved.is_relative_to(protected.resolve()):
            raise ValueError(f"Saída protegida: {resolved}. Gere no build/ para revisão.")


def generate(args):
    global DK, A4, AE, ini, SRC_DK, SRC_A4, SRC_AE
    DK = load_entries(args.dk)
    A4 = load_entries(args.a4)
    AE = load_entries(args.ae)
    if not args.ini.is_file():
        raise ValueError(f"Arquivo INI inexistente: {args.ini}")
    ini = {}
    cur = None
    for line in args.ini.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        m = re.match(r'^\[(.+)\]$', line)
        if m:
            cur = m.group(1); ini[cur] = {}; continue
        if cur and '=' in line and not line.startswith(';'):
            k, v = [x.strip() for x in line.split('=', 1)]
            ini[cur][k] = v
    SRC_DK = {'name': 'dArkOSRE-R36 (southoz)', 'url': 'https://github.com/southoz/dArkOSRE-R36', 'commit': args.dk_commit}
    SRC_A4 = {'name': 'ArkOS4Clone (lcdyk0517)', 'url': 'https://github.com/lcdyk0517/arkos4clone', 'commit': args.a4_commit}
    SRC_AE = {'name': 'R36S-DTB (AeolusUX)', 'url': 'https://github.com/AeolusUX/R36S-DTB', 'commit': args.ae_commit}

    def board_kind(model, variant):
        if variant=='clone': return 'clone'
        if variant=='soysauce': return 'variant'
        if model.startswith('R36S-V') or model.startswith('R36S-Y'): return 'r36s'
        return 'other'
    def board_name(model, kind):
        if kind=='r36s': return 'R36S'
        if kind=='clone': return 'Clone de R36S'
        if kind=='variant': return 'R36S Soy Sauce (Y3506)'
        for pre,n in [('HL-R36H','R36H'),('R35S','R35S'),('R36S Plus','R36S Plus'),('R36XX','R36XX'),('RG36S','RG36S')]:
            if model.startswith(pre): return n
        return model
    boards=[]
    seen=set()
    for r in DK:
        m=r['model'][0] if r.get('model') else ''
        if not m: continue
        if m in seen: continue
        seen.add(m)
        v=ini.get(m,{}).get('variant')
        if v is None:
            # nomes com caixa diferente no ini (ex.: Y3506_v03)
            for k in ini:
                if k.lower()==m.lower(): v=ini[k]['variant']
        k=board_kind(m,v)
        res=ini.get(m,{}).get('resolution') or r.get('res')
        boards.append({'match':{'model':m},'kind':k,'name':board_name(m,k),'board':m,'resolution':res,'panel_sha1':r.get('init_sha1'),
           'panel_compat':r.get('panel_compat'),'source':dict(SRC_DK,file='files/BOOT/dtb/'+r['file']),'source_class':'dArkOSRE: '+str(v),'reliability':'alta'})
    for m,d in ini.items():
        if m not in seen and m.lower() not in {x.lower() for x in seen}:
            k=board_kind(m,d.get('variant'))
            boards.append({'match':{'model':m},'kind':k,'name':board_name(m,k),'board':m,'resolution':d.get('resolution'),'panel_sha1':None,
              'source':dict(SRC_DK,file='files/BOOT/dtb/r36_devices.ini'),'source_class':'dArkOSRE: '+str(d.get('variant')),'reliability':'media'})
    # ArkOS4Clone: modelo + compatible
    for r in A4:
        m=r['model'][0].strip() if r.get('model') else ''
        if not m: continue
        c=r['compat'][0] if r.get('compat') else ''
        if 'R36S Clone' in m: k,n='clone','Clone de R36S ('+m.replace('R36S Clone ','')+')'
        elif 'Soy Sauce' in m: k,n='variant','R36S Soy Sauce'
        elif m=='GameConsole R36S': k,n='r36s','R36S'
        else: k,n='other',m.replace('GameConsole ','')
        boards.append({'match':{'model':m,'compatible':c},'kind':k,'name':n,'board':m+' ('+r['dir']+')','resolution':r.get('res'),'panel_sha1':r.get('init_sha1'),
          'panel_compat':r.get('panel_compat'),'source':dict(SRC_A4,file='boot/dArkOS/consoles/'+r['dir']+'/'+r['file']),'source_class':'ArkOS4Clone: '+r['dir'],'reliability':'alta'})
    # paineis: hash -> rotulos de todas as fontes
    panels={}
    def addp(h,label,kind,src):
        if not h: return
        panels.setdefault(h,[]).append({'label':label,'kind':kind,'source':src})
    for b in boards:
        addp(b.get('panel_sha1'),b['board'],b['kind'],b['source']['name'])
    for r in AE:
        f=r['file']
        if 'rk3326-r35s-linux' in f and '/R36S/' in f:
            p=f.split('/R36S/')[1].split('/')[0]
            addp(r.get('init_sha1'),'R36S '+p,'r36s',SRC_AE['name'])
    
    if not boards:
        raise ValueError("Nenhuma placa reconhecível gerada")
    payload = {
        'version': 1,
        'generated': datetime.date.today().isoformat(),
        'note': 'R36SPORTSBR STORE: assinaturas DTB geradas para revisao; nao substitui a base ativa.',
        'sources': [
            SRC_DK, SRC_A4, SRC_AE,
            {'name': 'ROCKNIX Wiki - Game Console R35S/R36S',
             'url': 'https://rocknix.org/devices/unbranded/game-console-r35s-r36s/'},
        ],
        'reference': {
            'name': 'R36S', 'soc': 'rk3326', 'cores': 4, 'cpu': 'Cortex-A35',
            'ram_mb': 1024, 'resolution': '640x480', 'emmc': False,
            'source': 'ROCKNIX Wiki: RK3326, Cortex-A35, Mali G31, 640x480, 1GB RAM',
        },
        'boards': boards, 'panels': panels,
    }
    forbid_live_outputs(args.out)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Geradas {len(boards)} placas e {len(panels)} painéis -> {args.out}")
    print("Tipos:", dict(Counter(board['kind'] for board in boards)))
    return payload


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dk', type=Path, default=GEN / 'darkosre_sigs.json')
    ap.add_argument('--a4', type=Path, default=GEN / 'a4c_sigs.json')
    ap.add_argument('--ae', type=Path, default=GEN / 'aeolus_sigs.json')
    ap.add_argument('--ini', type=Path, required=True, help='r36_devices.ini do dArkOSRE')
    ap.add_argument('--dk-commit', required=True)
    ap.add_argument('--a4-commit', required=True)
    ap.add_argument('--ae-commit', required=True)
    ap.add_argument('--out', type=Path, default=GEN / 'console_signatures.json')
    args = ap.parse_args()
    try:
        generate(args)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        ap.error(str(exc))


if __name__ == '__main__':
    main()
