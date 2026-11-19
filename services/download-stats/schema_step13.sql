-- Migracao aditiva (aplicada anteriormente na D1 remota).
-- Nao recriar o banco. Reexecutar apenas se a tabela estiver faltando.
CREATE TABLE IF NOT EXISTS approved_ports (
  catalog TEXT NOT NULL CHECK (catalog IN ('lira','r36sbr')),
  port_id TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
  added_at INTEGER NOT NULL DEFAULT (unixepoch()),
  PRIMARY KEY (catalog,port_id)
);
