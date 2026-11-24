-- O gatilho faz a contagem automaticamente, na mesma transacao do INSERT.
-- IDs repetidos sao ignorados; logo, um reenvio nunca soma novamente.
CREATE TABLE IF NOT EXISTS download_events (
  event_id TEXT PRIMARY KEY NOT NULL,
  catalog TEXT NOT NULL CHECK (catalog IN ('lira', 'r36sbr')),
  port_id TEXT NOT NULL,
  received_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS download_totals (
  catalog TEXT NOT NULL CHECK (catalog IN ('lira', 'r36sbr')),
  port_id TEXT NOT NULL,
  downloads INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
  PRIMARY KEY (catalog, port_id)
);

CREATE TRIGGER IF NOT EXISTS count_new_download
AFTER INSERT ON download_events
BEGIN
  INSERT INTO download_totals (catalog, port_id, downloads, updated_at)
  VALUES (NEW.catalog, NEW.port_id, 1, unixepoch())
  ON CONFLICT(catalog, port_id)
  DO UPDATE SET downloads = downloads + 1, updated_at = unixepoch();
END;

CREATE INDEX IF NOT EXISTS idx_download_totals_rank
ON download_totals(downloads DESC);
