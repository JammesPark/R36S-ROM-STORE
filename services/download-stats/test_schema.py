#!/usr/bin/env python3
"""Testa a migracao real usando SQLite local (mesma logica de D1)."""
import sqlite3
from pathlib import Path

sql = (Path(__file__).parent / "schema.sql").read_text(encoding="utf-8")
db = sqlite3.connect(":memory:")
db.executescript(sql)

def send(event_id, source="r36sbr", game="nfsu"):
    db.execute("INSERT OR IGNORE INTO download_events (event_id,catalog,port_id) VALUES (?,?,?)",
               (event_id, source, game))

send("a" * 32)
send("a" * 32)  # evento identico nao soma
assert db.execute("SELECT downloads FROM download_totals WHERE catalog='r36sbr' AND port_id='nfsu'").fetchone()[0] == 1
send("b" * 32)  # download novo no mesmo console soma
send("c" * 32, "lira", "nfsu")
assert db.execute("SELECT downloads FROM download_totals WHERE catalog='r36sbr' AND port_id='nfsu'").fetchone()[0] == 2
assert db.execute("SELECT downloads FROM download_totals WHERE catalog='lira' AND port_id='nfsu'").fetchone()[0] == 1
print("D1 schema: reenvio idempotente, catalogos separados, totais corretos")
