#!/usr/bin/env python3
"""No commercial BIOS bytes: only synthetic dummy file fixtures."""
import importlib.util
import io
import json
import os
import tempfile
import zipfile
from pathlib import Path

BASE=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('bios',BASE/'port/r36s-roms-store/bin/bios_manager.py')
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as temp:
    root=Path(temp)
    app=root/'roms/ports/r36s-roms-store'
    bios=root/'roms/bios'
    app.mkdir(parents=True)
    bios.mkdir(parents=True)
    mgr=mod.BIOSManager(app,bios)
    first=mgr.scan()
    assert first['missing'] == len(mod.BIOS_GROUPS)
    assert not (bios/'gba_bios.bin').exists()
    folder=mgr.import_dir
    folder.mkdir(parents=True)
    (folder/'gba_bios.bin').write_bytes(b'synthetic-firmware-v1')
    assert mgr.install()==1
    assert (bios/'gba_bios.bin').read_bytes()==b'synthetic-firmware-v1'
    assert mgr.scan()['present']>=1
    assert mgr.restore()==1
    assert not (bios/'gba_bios.bin').exists()
    assert not mgr.last.exists()
    # Test backup of an existing BIOS, install and restore the original.
    (bios/'gba_bios.bin').write_bytes(b'previous-owner-data')
    assert mgr.install()==1
    assert (bios/'gba_bios.bin').read_bytes()==b'synthetic-firmware-v1'
    assert mgr.restore()==1
    assert (bios/'gba_bios.bin').read_bytes()==b'previous-owner-data'
    # Idempotent install should not create another backup.
    (folder/'gba_bios.bin').write_bytes(b'previous-owner-data')
    assert mgr.install()==0
    # An unknown file in import folder must be ignored.
    (folder/'notsure.exe').write_bytes(b'evil')
    assert mgr.install()==0
    # A ZIP that contains traversal must be refused.
    (folder/'gba_bios.bin').unlink()
    with zipfile.ZipFile(folder/'bundle.zip','w') as z:
        z.writestr('../outside/gba_bios.bin',b'bad')
    try:
        mgr.install()
        raise AssertionError('Unsafe ZIP path accepted')
    except ValueError as e:
        assert 'inseguro' in str(e)
    (folder/'bundle.zip').unlink()
    # Valid ZIP with known file under a shallow folder.
    with zipfile.ZipFile(folder/'bios.zip','w') as z:
        z.writestr('BIOS/scph5501.bin',b'fake-psx-for-tests')
    assert mgr.install()==1
    assert (bios/'scph5501.bin').read_bytes()==b'fake-psx-for-tests'
    # A post-install user modification is never overwritten by restore.
    (bios/'scph5501.bin').write_bytes(b'user-replaced-it')
    try:
        mgr.restore()
        raise AssertionError('Unsafe restore accepted')
    except ValueError as e:
        assert 'modificada' in str(e)
    # Symlinks inside BIOS tree must not be followed.
    (bios/'scph5501.bin').unlink()
    outside=root/'user-important.bin'; outside.write_bytes(b'user-data')
    (bios/'scph5501.bin').symlink_to(outside)
    try:
        mgr.install()
        raise AssertionError('Symlink allowed')
    except ValueError as e:
        assert 'simbólico' in str(e)
    assert outside.read_bytes()==b'user-data'
print('BIOS: scan, import, zip safety, backup, restore, unchanged files and symlink protection: OK')
