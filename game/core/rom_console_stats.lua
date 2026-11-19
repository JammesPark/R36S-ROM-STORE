-- Contagem exclusiva do painel local: SD1 e SD2, sem afetar a Biblioteca.
-- Le pastas/extensoes do EmulationStation; nao conta capas, videos, BIOS ou ports.
-- Nao cria arquivos no cartao. Tudo e executado em segundo plano.
local U=require("lib.util")
local Lib=require("core.library")
local Ports=require("core.portstorage")
local M={state="idle",total=nil,sd1=nil,sd2=nil,scan_time=0}
local MAX_AGE=30

local function card_root(card)
  local data=Ports.get(card)
  if data and (data.available or data.readable) then return data.root end
  -- A contagem tambem deve funcionar com cartao somente leitura, ou sem
  -- pasta /ports. Nao confundir /roms2 com segunda particao no mesmo disco.
  local path=card=="sd1" and "/roms" or "/roms2"
  if not U.is_dir(path) then return nil end
  if card=="sd1" then return path end
  local function device(dir)
    local out=U.capture("df -Pk "..U.shq(dir).." 2>/dev/null | tail -n 1") or ""
    return out:match("^(%S+)")
  end
  local one,two=device("/roms"),device("/roms2")
  if one and two and one~=two then return "/roms2" end
  return nil
end

function M.refresh(force)
  if M.state=="scanning" then return false end
  if not force and M.state=="done" and os.time()-(M.scan_time or 0)<MAX_AGE then return false end
  if #Lib.systems==0 then
    local ok=Lib.load_systems()
    if not ok then M.state="error";M.total=nil;return false end
  end
  local roots={sd1=card_root("sd1"),sd2=card_root("sd2")}
  -- Pasta -> conjunto das extensoes aceitas, segundo es_systems.cfg.
  local paths,extensions={},{}
  for _,sys in ipairs(Lib.systems) do
    local suffix=tostring(sys.path or ""):match("^/roms2?(/.+)$")
    if suffix and suffix~="/ports" and not suffix:match("^/ports/") then
      for card,root in pairs(roots) do
        if root then
          local dir=root..suffix
          if U.is_dir(dir) and not U.exec_ok("test -L "..U.shq(dir)) then
            if not extensions[dir] then
              paths[#paths+1]=dir
              extensions[dir]={}
            end
            for ext,yes in pairs(sys.exts or {}) do
              if yes then extensions[dir][ext:lower()]=true end
            end
          end
        end
      end
    end
  end
  if #paths==0 then
    -- Configuracao sem pastas reconhecidas: nao inventar contagem zero.
    M.state="error";M.sd1=nil;M.sd2=nil;M.total=nil;return false
  end
  table.sort(paths,function(a,b) return #a>#b end)
  local quoted={}
  for _,path in ipairs(paths) do quoted[#quoted+1]=U.shq(path) end
  M.state="scanning"
  -- O shell da thread executa find sem seguir links para evitar contagem duplicada.
  local cmd="find "..table.concat(quoted," ").." -maxdepth 3 -type f -printf '%p\\n' 2>/dev/null"
  require("core.shjob").start({cmd},function(results)
    if not results or not results[1] or tonumber(results[1].rc or 0)~=0 then
      M.state="error";M.total=nil;M.sd1=nil;M.sd2=nil;return
    end
    local seen={}
    local count={sd1=0,sd2=0}
    for file in (results[1].out or ""):gmatch("[^\n]+") do
      if not seen[file] then
        for _,dir in ipairs(paths) do
          if file:sub(1,#dir+1)==dir.."/" then
            local name=file:match("([^/]+)$") or ""
            local ext=name:match("(%.[^%.]+)$")
            if ext and extensions[dir][ext:lower()]
                and name:sub(1,1)~="." then
              -- Evita tratar caches de arte como ROMs quando um sistema
              -- usa pastas de midia dentro da mesma arvore.
              local rel=file:sub(#dir+2)
              local folder=rel:match("^([^/]+)/")
              if not folder or not ({images=true,videos=true,manuals=true,
                    media=true,snap=true,snaps=true})[folder:lower()] then
                local card=file:sub(1,7)=="/roms2/" and "sd2" or "sd1"
                count[card]=count[card]+1;seen[file]=true
              end
            end
            break
          end
        end
      end
    end
    M.sd1=roots.sd1 and count.sd1 or nil
    M.sd2=roots.sd2 and count.sd2 or nil
    M.total=count.sd1+count.sd2
    M.scan_time=os.time();M.state="done"
  end)
  return true
end

return M
