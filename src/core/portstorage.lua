-- Escolha de destino dos ports. Nao confunde /roms2 com um segundo SD
-- quando a pasta existe mas esta no mesmo sistema de arquivos de /roms.
local L = require("lib.i18n").L
local C = require("config")
local U = require("lib.util")
local S = {}
local ROOTS = { sd1 = "/roms", sd2 = "/roms2" }

local function fsinfo(root)
  if not U.is_dir(root) then return nil end
  local txt = U.capture("df -Pk " .. U.shq(root) .. " 2>/dev/null | tail -n 1") or ""
  local dev, total, used, free, pct, mounted = txt:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%S+)%s+(%S+)")
  if not dev then return nil end
  local real = U.trim(U.capture("readlink -f " .. U.shq(root) .. " 2>/dev/null") or "")
  return { device = dev, free = tonumber(free) * 1024, real = real, mount = mounted }
end

function S.get(card)
  local root = ROOTS[card]
  if not root then return nil end
  local path = root .. "/ports"
  local data = { card = card, root = root, path = path, label = card == "sd1" and "SD1" or "SD2" }
  local info, primary = fsinfo(root), fsinfo(ROOTS.sd1)
  local path_info = U.is_dir(path) and fsinfo(path) or nil
  local separate = card ~= "sd2" or (primary and info and info.device ~= primary.device
    and info.mount ~= "/" and (info.real == "" or info.real ~= primary.real))
  data.readable = (info and separate and path_info and path_info.device == info.device) and true or false
  if not info then
    data.reason = L("cartão não encontrado")
  elseif card == "sd2" and (not primary or (info.device == primary.device) or info.mount == "/"
      or (info.real ~= "" and info.real == primary.real)) then
    data.reason = L("segundo cartão não montado separadamente")
  elseif U.is_dir(path) and fsinfo(path) and fsinfo(path).device ~= info.device then
    data.reason = L("a pasta ports aponta para outro cartão")
  elseif U.is_dir(path) and not U.exec_ok("test -w " .. U.shq(path)) then
    data.reason = L("pasta de ports sem permissão de gravação")
  elseif not U.is_dir(path) and not U.exec_ok("test -w " .. U.shq(root)) then
    data.reason = L("cartão sem permissão de gravação")
  else
    data.available = true
    data.free = info.free
  end
  return data
end

function S.from_path(path)
  if path == "/roms/ports" then return S.get("sd1") end
  if path == "/roms2/ports" then return S.get("sd2") end
  return nil
end

function S.validate(path)
  local d = S.from_path(path)
  if not d then return false, L("Destino inválido: escolha SD1 ou SD2.") end
  if not d.available then return false, d.label .. ": " .. (d.reason or L("indisponível")) end
  return true, d
end

-- Arquivos temporarios ficam no MESMO cartao selecionado. Assim mover os
-- arquivos extraidos nao depende de copiar dados entre cartoes.
function S.tmp_dir(path)
  local d = S.from_path(path)
  return d and (d.root .. "/.r36sromsstore_tmp") or C.TMP_DIR
end

return S
