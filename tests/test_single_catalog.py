from pathlib import Path

root=Path(".")
main=(root/"src/main.lua").read_text(encoding="utf-8")
external=(root/"src/external.lua").read_text(encoding="utf-8")
worker=(root/"port/r36s-store-kpm/bin/worker.sh").read_text(encoding="utf-8")
assert not (root/"src/catalog.json").exists()
assert not (root/"port/r36s-store-kpm/config/catalog_url.txt").exists()
assert "external.draw()" in main
assert "external.enter()" in main
assert "external.handle(key)" in main
assert "CATALOGO KPM" not in main
assert "setCatalog(" not in main
assert "catalog.pending.json" not in main
assert "X: KPM" not in external
assert "M.enter()" in external
assert "M.toggle()" not in external
assert "catalog) shift" not in worker
assert "uninstall) shift" in worker
print("Catalogo unico GameStoreBR e compatibilidade de instalados: OK")
