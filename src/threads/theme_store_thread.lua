-- Instalacao segura de temas visuais da STORE, nunca temas EmulationStation.
require("love.timer")
local job = ...
local json = require("lib.json")
local OUT, IN = love.thread.getChannel(job.out), love.thread.getChannel(job.inn)
local function shq(s) return "'" .. tostring(s or ""):gsub("'", "'\\''") .. "'" end
local function cmd(s)
  local ok, kind, code = os.execute(s)
  return ok == true or ok == 0
end
local function capture(s)
  local h = io.popen(s); if not h then return "" end
  local str = h:read("*a") or ""; h:close(); return str
end
local function filesize(p)
  local f=io.open(p,"rb"); if not f then return 0 end
  local n=f:seek("end") or 0; f:close(); return n
end
local function read(p)
  local f=io.open(p,"rb"); if not f then return nil end
  local s=f:read("*a"); f:close(); return s
end
local function fail(s) OUT:push({t="error",msg=s}); error("__stop__",0) end
local ROOT=job.save_dir .. "/theme_store_work"
local ZIP=ROOT .. "/theme.zip"
local STAGE=ROOT .. "/stage"
local DST=job.save_dir .. "/user_themes/" .. job.id
local BACKUP_DIR=job.save_dir .. "/theme_store_backups"
local BACK=BACKUP_DIR .. "/" .. job.id .. "-" .. tostring(os.time())
local allowed={["theme.json"]=true,["preview.png"]=true,
  ["logo_header.png"]=true,["logo_menu.png"]=true,["logo_splash.png"]=true,
  ["logo_about.png"]=true,["background_v4.png"]=true,["selected_tiles_v4.png"]=true}
local keys={"bg0","bg1","bg2","bg3","line","text","dim","faint","accent","accent2",
  "yellow","green","red","orange","black","shadow"}
local function valid_manifest(path)
  local raw=read(path)
  if not raw or #raw > 32768 then fail("theme.json ausente ou grande demais") end
  local ok, d=pcall(json.decode,raw)
  if not ok or type(d)~="table" or d.id~=job.id or d.version~=job.version
      or type(d.colors)~="table" then fail("ID, versão ou estrutura do tema inválidos") end
  for _, k in ipairs(keys) do
    local c=d.colors[k]
    if type(c)~="string" or not (c:match("^#%x%x%x%x%x%x$")
      or c:match("^#%x%x%x%x%x%x%x%x$")) then
      fail("theme.json tem cor obrigatória inválida: " .. k)
    end
  end
  if d.style and type(d.style) ~= "table" then fail("Estilo inválido") end
end
local function run()
  if type(job.id)~="string" or #job.id>48 or not job.id:match("^[%w_%-]+$")
      or type(job.url)~="string" or not job.url:match("^https://[^%s]+%.zip$")
      or type(job.sha256)~="string" or #job.sha256~=64 or not job.sha256:match("^%x+$")
      or type(job.size)~="number" or job.size<100 or job.size>12582912 then
    fail("Parâmetros do pacote inválidos")
  end
  if not cmd("mkdir -p " .. shq(job.save_dir .. "/user_themes")) then fail("Não foi possível criar pasta de temas") end
  if not cmd("rm -rf " .. shq(ROOT) .. " && mkdir -p " .. shq(STAGE)) then
    fail("Não foi possível preparar pasta temporária")
  end
  OUT:push({t="phase",phase="download"})
  local rc=ROOT.."/dl.rc"; local pid=ROOT.."/dl.pid"
  if not cmd("( sh "..shq(job.fetch_sh).." get "..shq(job.url).." "..shq(ZIP).." "..shq(pid).." "..shq(rc).." 0 >/dev/null 2>&1 & )") then
    fail("Falha ao iniciar download")
  end
  while true do
    local f=io.open(rc,"rb")
    if f then
      local code=tonumber((f:read("*a") or ""):match("%d+")) or 1; f:close()
      if code==143 or code==137 then OUT:push({t="cancelled"}); error("__stop__",0) end
      if code~=0 then fail("Erro de download (código "..code..")") end
      break
    end
    if IN:pop()=="cancel" then
      local p=read(pid); local n=p and p:match("^%d+")
      if n then cmd("kill "..n.." 2>/dev/null") end
      OUT:push({t="cancelled"}); error("__stop__",0)
    end
    OUT:push({t="progress",done=filesize(ZIP),total=job.size})
    love.timer.sleep(.25)
  end
  OUT:push({t="phase",phase="verify"})
  if filesize(ZIP)~=job.size then fail("Tamanho do pacote não confere") end
  if capture("sha256sum "..shq(ZIP).." 2>/dev/null"):match("^(%x+)") ~= job.sha256 then
    fail("SHA-256 incorreto: instalação recusada")
  end
  if not cmd("unzip -tqq "..shq(ZIP).." >/dev/null 2>&1") then fail("ZIP corrompido") end
  local names=capture("unzip -Z1 "..shq(ZIP).." 2>/dev/null")
  local root, files, count=nil,{},0
  for name in names:gmatch("[^\r\n]+") do
    count=count+1
    if count>16 or name:find("\\",1,true) or name:sub(1,1)=="/"
       or name:find("..",1,true) or name:find(":",1,true) or name:find("//",1,true) then
      fail("ZIP com nomes inseguros")
    end
    local first,rest=name:match("^([^/]+)/(.+)$")
    local file=rest or name
    if not allowed[file] then fail("Arquivo não permitido no pacote: "..name) end
    if rest then
      if root and root~=first then fail("Pacote com mais de uma pasta raiz") end
      root=first
    elseif root then fail("Pacote mistura arquivos com e sem pasta raiz") end
    if files[file] then fail("Arquivo repetido no pacote") end
    files[file]=true
  end
  if count==0 or not files["theme.json"] then fail("Pacote sem theme.json") end
  if capture("unzip -Z -l "..shq(ZIP).." 2>/dev/null"):match("\nl[rwx%-]") then
    fail("ZIP contém link simbólico")
  end
  local bytes=tonumber(capture("unzip -Zt "..shq(ZIP).." 2>/dev/null"):match("(%d+) bytes uncompressed") or "0") or 0
  if bytes<=0 or bytes>16777216 then fail("Pacote descompactado excede limite de 16 MB") end
  OUT:push({t="phase",phase="extract"})
  if not cmd("unzip -q "..shq(ZIP).." -d "..shq(STAGE).." >/dev/null 2>&1") then
    fail("Não foi possível descompactar o ZIP")
  end
  if capture("find "..shq(STAGE).." -type l 2>/dev/null | head -n 1"):match("%S") then
    fail("Conteúdo contém link simbólico")
  end
  local staged=STAGE..(root and ("/"..root) or "")
  valid_manifest(staged.."/theme.json")
  OUT:push({t="phase",phase="install"})
  local has_old=cmd("test -d "..shq(DST))
  if has_old then
    if not cmd("mkdir -p "..shq(BACKUP_DIR)) or cmd("test -e "..shq(BACK)) then
      fail("Não foi possível reservar backup individual para o tema antigo")
    end
    if not cmd("mv "..shq(DST).." "..shq(BACK)) then fail("Falha no backup do tema antigo") end
  end
  if not cmd("mv "..shq(staged).." "..shq(DST)) then
    if has_old then cmd("mv "..shq(BACK).." "..shq(DST)) end
    fail("Instalação não concluída; backup restaurado")
  end
  if not read(DST.."/theme.json") then
    cmd("rm -rf "..shq(DST))
    if has_old then cmd("mv "..shq(BACK).." "..shq(DST)) end
    fail("Instalação inválida; versão anterior restaurada")
  end
  cmd("rm -rf "..shq(ROOT))
  OUT:push({t="done"})
end
local ok,err=pcall(run)
if not ok and err~="__stop__" then OUT:push({t="error",msg="Falha interna: "..tostring(err)}) end
if not ok then
  -- Em caso de falha depois de mover a pasta anterior, restaura o backup.
  if cmd("test -d "..shq(BACK)) and not cmd("test -d "..shq(DST)) then
    cmd("mv "..shq(BACK).." "..shq(DST))
  end
end
