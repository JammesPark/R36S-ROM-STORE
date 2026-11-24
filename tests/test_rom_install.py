import tempfile,zipfile,tarfile,importlib.util,io,pathlib,argparse,os
f=str(__import__('pathlib').Path(__file__).resolve().parents[1] / 'src/threads/rom_install.py')
spec=importlib.util.spec_from_file_location('rominst',f)
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
failures=[]
def test(label,system,filename,fmt,content=None,existing=False,exp=None):
 with tempfile.TemporaryDirectory() as t:
  root=pathlib.Path(t);src=root/'download.dat';stage=root/'stage';dst=root/'roms';dst.mkdir();
  if isinstance(content,dict):
   with zipfile.ZipFile(src,'w') as z:
    for k,v in content.items():z.writestr(k,v)
  else:src.write_bytes(content or b'FICTITIOUS ROM FILE')
  r.validate_root=lambda dest,sys:root
  a=argparse.Namespace(source=str(src),dest=str(dst),stage=str(stage),system=system,filename=filename,slug='example-game',format=fmt,margin=0,cancel=str(root/'cancel'),sevenzip='')
  if existing:
   old=dst/filename; old.write_bytes(b'ORIGINAL')
  try:
   r.run(a)
   if exp:
    failures.append((label,'success unexpected'))
   else:
    print('PASS',label, sorted(x.name for x in dst.iterdir()))
  except r.RomError as ex:
   if exp != ex.code:failures.append((label,f'{ex.code} not {exp}: {ex.msg}'))
   else:print('PASS',label,'refused',ex.code)
  if existing and (dst/filename).read_bytes()!=b'ORIGINAL':failures.append((label,'overwritten'))

test('GBA single ZIP','gba','Example.zip','zip',{'Example.gba':b'GBA-DATA'})
test('PSX multi-track','psx','Example.zip','zip',{'example.cue':b'FILE "track.bin" BINARY','track.bin':b'BIN'})
test('MAME zip kept','mame','galaga.zip','zip',{'1.bin':b'ROMSET'})
for cps in ('cps1','cps2','cps3'):
 test(cps+' zip kept',cps,'demo.zip','zip',{'1.bin':b'DUMMY-ROMSET'})
test('PSP Minis PBP','psp-minis','Demo.pbp','rom_direct',b'FICTITIOUS PBP')
test('PSP Minis ISO inside ZIP','psp-minis','Demo.zip','zip',{'Demo.iso':b'FICTITIOUS ISO'})
test('PSP Minis rejects NES','psp-minis','Demo.nes','rom_direct',b'FICTITIOUS NES',exp='unsupported_rom')
test('raw GBA','gba','Example.gba','rom_direct',b'GBA-DATA')
test('refuse existing GBA','gba','Example.gba','rom_direct',b'NEW',existing=True,exp='exists')
test('reject traversal','gba','evil.zip','zip',{'../escape.gba':b'XX'},exp='unsafe_zip')
test('wrong system','gba','Example.zip','zip',{'Example.nes':b'NES'},exp='unsupported_rom')
test('reject executable','gba','evil.zip','zip',{'bad.sh':b'run me','Example.gba':b'ROM'},exp='unsafe_zip')
if failures:
 print('FAILURES:',failures);raise SystemExit(1)

# FAT32/exFAT nao suportam os.link(); copiar ROMs diretas deve funcionar
# mesmo quando o sistema operacional rejeita hard links (Errno 1 EPERM).
from unittest import mock
with mock.patch.object(r.os, 'link', side_effect=PermissionError(1, 'Operation not permitted')):
    test('Neo Geo on FAT/exFAT (no hardlinks)', 'neogeo', 'doubledr.zip', 'zip', {'game1.bin': b'DUMMY-ROMSET'})
    test('MAME on FAT/exFAT (no hardlinks)', 'mame', 'galaga.zip', 'zip', {'1.bin': b'ROMSET'})
    test('raw Game Boy on FAT/exFAT (no hardlinks)', 'gb', 'Example.gb', 'rom_direct', b'GB-ROM-DATA')

# Se a copia for cancelada apos escrever parte do arquivo, nenhum arquivo
# incompleto pode ficar instalado nem o download original pode ser apagado.
with tempfile.TemporaryDirectory() as d:
    root=pathlib.Path(d); source=root/'download.zip'; source.write_bytes(b'EXAMPLE-NEOGEO-ROM-SET')
    stage=root/'stage'; dest=root/'neogeo'; dest.mkdir()
    a=argparse.Namespace(source=str(source),dest=str(dest),stage=str(stage),system='neogeo',
       filename='doubledr.zip',slug='double-dragon',format='rom_direct',margin=0,
       cancel=str(root/'cancel'),sevenzip='')
    old_check,old_validate,old_chunk=r.check_cancel,r.validate_root,r.CHUNK
    call_count=[0]
    def cancel_mid_copy(flag):
        call_count[0]+=1
        if call_count[0]>=4:
            raise r.RomError('cancelled','Interrupted during copy')
    try:
        r.check_cancel=cancel_mid_copy
        r.validate_root=lambda target,system:root
        r.CHUNK=4
        try:
            r.run(a)
            failures.append(('cancel mid copy','not cancelled'))
        except r.RomError as exc:
            if exc.code!='cancelled': failures.append(('cancel mid copy',exc.code))
        if (dest/'doubledr.zip').exists(): failures.append(('cancel mid copy','partial file left'))
        if source.read_bytes()!=b'EXAMPLE-NEOGEO-ROM-SET': failures.append(('cancel mid copy','source damaged'))
        print('PASS copy cancellation leaves no partial ROM')
    finally:
        r.check_cancel, r.validate_root, r.CHUNK=old_check,old_validate,old_chunk

if failures:
 print('FAILURES:',failures);raise SystemExit(1)

# Simula a extracao segura de um romset individual 7z; testa o ZIP resultante.
with tempfile.TemporaryDirectory() as d:
    root=pathlib.Path(d);src=root/'download.7z';src.write_bytes(b'FICTITIOUS')
    dest=root/'cps1';dest.mkdir();stage=root/'stage'
    a=argparse.Namespace(source=str(src),dest=str(dest),stage=str(stage),system='cps1',filename='demo.7z',slug='cps1-demo',format='7z',margin=0,cancel=str(root/'cancel'),sevenzip='')
    def fake_extract(src,content,*args):
        (content/'chip1.bin').write_bytes(b'CHIP1')
        (content/'chip2.bin').write_bytes(b'CHIP2')
    old_extract,old_validate=r.seven_extract,r.validate_root
    try:
        r.seven_extract=fake_extract;r.validate_root=lambda dest,sys:root
        r.run(a)
        with zipfile.ZipFile(dest/'demo.zip') as z:
            assert sorted(z.namelist())==['chip1.bin','chip2.bin']
            assert z.read('chip1.bin')==b'CHIP1' and z.testzip() is None
        assert sorted(p.name for p in dest.iterdir())==['demo.zip']
        print('PASS CPS 7z ROMset converted to intact ZIP')
    finally:
        r.seven_extract=old_extract;r.validate_root=old_validate
