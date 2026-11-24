-- Compatibilidade para telas antigas: a Experimental nao consulta APIs de ROMs.
-- As ROMs ja estao integralmente em core.catalog, a partir de catalogo_proprio.zlib.
local R = {}
function R.reset() end
function R.state()
  return { page = 1, total_pages = 1, loading = false, failed = false }
end
function R.is_supported() return false end
function R.ensure() return false end
function R.refresh(_, on_done)
  if on_done then on_done(false, 0, "Use Atualizar catalogo local") end
  return false
end
function R.retry() return false end
function R.search(_, _, cb)
  if cb then cb(false, nil, "Busca local: catalogo completo ja carregado") end
  return false
end
function R.source_label() return "Catálogo próprio (local)" end
return R
