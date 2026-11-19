-- Destinos de ROMs: pastas de sistemas, independentes do instalador de ports.
-- Validacao de SD1/SD2 reaproveita a deteccao existente, sem gravar em /ports.
local L = require("lib.i18n").L
local U = require("lib.util")
local Ports = require("core.portstorage")
local R = {}
local FOLDERS = {
  ["3do"]="3do", amigacd32="amigacd32", atari2600="atari2600",
  dreamcast="dreamcast", gamegear="gamegear", gb="gb", gba="gba", gbc="gbc",
  mame="mame", mastersystem="mastersystem", megadrive="megadrive", n64="n64",
  nds="nds", neogeo="neogeo", nes="nes", pcengine="pcengine", psp="psp",
  psx="psx", saturn="saturn", snes="snes",
}
local ALIASES = { megadrive="genesis", mastersystem="sms", mame="mame2003" }
R.FOLDERS = FOLDERS

local function same_filesystem(a,b)
  local function dev(path)
    return (U.capture("df -Pk " .. U.shq(path) .. " 2>/dev/null | tail -n 1") or ""):match("^(%S+)")
  end
  return dev(a) and dev(a) == dev(b)
end

local function no_symlink(path)
  return not U.exec_ok("test -L " .. U.shq(path))
end

function R.get(card, system)
  local folder = FOLDERS[system]
  if not folder then return { available=false, reason=L("Sistema de ROM não suportado"), label=card } end
  local sd = Ports.get(card)
  if not sd then return {available=false, reason=L("Cartão inválido"), label=card} end
  local result={card=card, root=sd.root, system=system, label=sd.label, free=sd.free}
  local alias=ALIASES[system]
  if alias and U.is_dir(sd.root.."/"..alias) and not U.is_dir(sd.root.."/"..folder) then folder=alias end
  result.folder=folder
  result.path=sd.root.."/"..folder
  if not sd.available then result.reason=sd.reason; return result end
  if not no_symlink(result.root) or not no_symlink(result.path) then
    result.reason=L("O destino contém um link simbólico e não é seguro"); return result
  end
  if U.is_dir(result.path) and not same_filesystem(result.root,result.path) then
    result.reason=L("A pasta do sistema está em outro dispositivo"); return result
  end
  if U.is_dir(result.path) then
    if not U.exec_ok("test -w "..U.shq(result.path)) then
      result.reason=L("Sem permissão para gravar na pasta do sistema"); return result
    end
  elseif not U.exec_ok("test -w "..U.shq(result.root)) then
    result.reason=L("Cartão sem permissão de gravação"); return result
  end
  result.available=true
  return result
end

function R.validate(path, system)
  if not FOLDERS[system] then return false,L("Sistema de ROM inválido") end
  for _, card in ipairs({"sd1","sd2"}) do
    local d=R.get(card,system)
    if d.path==path then
      if d.available then return true,d end
      return false,d.label..": "..(d.reason or L("indisponível"))
    end
  end
  return false,L("Destino de ROM inválido para este sistema")
end

function R.tmp_dir(path, system)
  local ok, d = R.validate(path, system)
  return ok and (d.root.."/.r36sromsstore_tmp") or nil
end

-- Nao confiar na extensao de uma URL remota para escolher o sistema.
-- Ela serve somente para recuperar o nome original do arquivo.
function R.filename(p)
  local url=tostring(p.download_url or "")
  local filename=(url:match("([^/]+)$") or ""):gsub("[?#].*$", "")
  filename=filename:gsub("%%(%x%x)",function(h) return string.char(tonumber(h,16)) end)
  filename=filename:gsub("[/%\\%c]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
  if filename=="" or filename=="." or filename==".." or #filename>200 then return nil end
  return filename
end

return R
