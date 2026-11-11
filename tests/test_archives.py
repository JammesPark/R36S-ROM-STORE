import importlib.util, pathlib, tempfile, zipfile
from io import BytesIO

source = pathlib.Path("port/r36s-store-kpm/bin/archive_safe.py")
spec = importlib.util.spec_from_file_location("archive_safe", source)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def sample(entries, target):
    with zipfile.ZipFile(target, "w") as z:
        for name, content in entries.items():
            z.writestr(name, content)

with tempfile.TemporaryDirectory() as temp:
    root = pathlib.Path(temp)
    ok = root / "ok.zip"
    sample({"Cool Port.sh": "#!/bin/bash\n", "gamefiles/data.txt": "abc"}, ok)
    mod.extract_zip(str(ok), str(root / "out"))
    assert (root / "out/Cool Port.sh").exists()
    assert (root / "out/gamefiles/data.txt").read_text() == "abc"

    bad = root / "bad.zip"
    sample({"../escape.txt": "x"}, bad)
    try:
        mod.extract_zip(str(bad), str(root / "badout"))
        raise AssertionError("Traversal permitido")
    except ValueError:
        pass
    assert not (root / "escape.txt").exists()

    duplicate = root / "duplicate.zip"
    with zipfile.ZipFile(duplicate, "w") as z:
        z.writestr("same.txt","one")
        z.writestr("same.txt","two")
    try:
        mod.extract_zip(str(duplicate), str(root / "dupout"))
        raise AssertionError("Overwrite permitido")
    except FileExistsError:
        pass
print("Safe ZIP: normal, traversal e sobrescrita OK")
