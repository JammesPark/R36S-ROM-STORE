-- =============================================================================
--  Fila de downloads pequenos (catalogo e capas) em uma thread separada
-- =============================================================================
local C = require("config")
local U = require("lib.util")

local F = { thread = nil, handlers = {}, pending = 0, seq = 0, catalog = {} }

function F.start()
  if F.thread then return end
  F.req = love.thread.getChannel("hub_fetch_req")
  F.res = love.thread.getChannel("hub_fetch_res")
  F.req:clear(); F.res:clear()
  F.thread = love.thread.newThread("threads/fetch_thread.lua")
  F.thread:start(C.FETCH_SH)
end

-- Catalogo proprio usa canal independente para nao bloquear a fila de capas.
local function start_catalog()
  local q = F.catalog
  if q.thread then return q end
  q.req = love.thread.getChannel("hub_own_catalog_req")
  q.res = love.thread.getChannel("hub_own_catalog_res")
  q.req:clear(); q.res:clear()
  q.thread = love.thread.newThread("threads/fetch_thread.lua")
  q.thread:start(C.FETCH_SH, "hub_own_catalog")
  return q
end

--- Agenda um download. cb(ok, out_path, reason)
function F.get(kind, url, out, cb, priority)
  if kind == "own_catalog" then
    local q = start_catalog()
    F.seq = F.seq + 1
    local id = kind .. ":" .. F.seq
    q.id, q.cb = id, cb
    F.pending = F.pending + 1
    q.req:push({id = id, kind = kind, url = url, out = out})
    return id
  end
  F.start()
  F.seq = F.seq + 1
  local id = kind .. ":" .. F.seq
  F.handlers[id] = cb
  F.pending = F.pending + 1
  if priority then
    -- catalogo passa na frente das capas
    local queued = {}
    local m = F.req:pop()
    while m do queued[#queued + 1] = m; m = F.req:pop() end
    F.req:push({ id = id, kind = kind, url = url, out = out })
    for _, q in ipairs(queued) do F.req:push(q) end
  else
    F.req:push({ id = id, kind = kind, url = url, out = out })
  end
  return id
end

function F.update()
  local q = F.catalog
  if q.thread then
    local err = q.thread:getError()
    local msg = not err and q.res:pop() or nil
    if err or msg then
      local cb = q.cb
      q.cb, q.id = nil, nil
      if err then q.thread = nil end
      if cb then
        F.pending = math.max(0, F.pending - 1)
        local ok, e = pcall(cb, msg and msg.ok or false, msg and msg.out, err or (msg and msg.reason))
        if not ok then U.log("erro no retorno do catalogo:", e) end
      end
    end
  end
  if not F.thread then return end
  local err = F.thread:getError()
  if err then
    U.log("erro na thread de downloads:", err)
    F.thread = nil
    -- avisa todos os pendentes
    for id, cb in pairs(F.handlers) do pcall(cb, false, nil, "erro interno") end
    F.handlers = {}
    F.pending = F.catalog.cb and 1 or 0
    return
  end
  local m = F.res:pop()
  while m do
    local cb = F.handlers[m.id]
    F.handlers[m.id] = nil
    F.pending = math.max(0, F.pending - 1)
    if cb then
      local ok, e = pcall(cb, m.ok, m.out, m.reason)
      if not ok then U.log("erro no retorno do download:", e) end
    end
    m = F.res:pop()
  end
end

--- Baixa so os primeiros `bytes` de um arquivo (ex.: manifesto de um .zip).
--- cb(ok, out_path, reason)
function F.get_part(kind, url, out, bytes, cb)
  F.start()
  F.seq = F.seq + 1
  local id = kind .. ":" .. F.seq
  F.handlers[id] = cb
  F.pending = F.pending + 1
  local queued = {}
  local m = F.req:pop()
  while m do queued[#queued + 1] = m; m = F.req:pop() end
  F.req:push({ id = id, kind = kind, url = url, out = out, part = bytes })
  for _, q in ipairs(queued) do F.req:push(q) end
  return id
end

--- Remove pedidos de capa ainda nao iniciados (ao trocar de tela)
function F.drop_covers()
  if not F.req then return end
  local keep = {}
  local m = F.req:pop()
  while m do
    if m.kind ~= "cover" then keep[#keep + 1] = m
    else
      local cb = F.handlers[m.id]
      F.handlers[m.id] = nil
      F.pending = math.max(0, F.pending - 1)
      if cb then pcall(cb, false, nil, "cancelado") end
    end
    m = F.req:pop()
  end
  for _, k in ipairs(keep) do F.req:push(k) end
end

function F.stop()
  if F.req then F.req:clear(); F.req:push({ t = "quit" }) end
  if F.catalog.req then F.catalog.req:clear(); F.catalog.req:push({ t = "quit" }) end
end

return F
