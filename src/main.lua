local json=require('json')
local external=require('external')
local W,H=640,480
local HOME=os.getenv('R36S_STORE_HOME') or '/roms/ports/r36s-store-kpm'
local STATE=HOME..'/state'
local tabs={'INICIO','CATALOGO','INSTALADOS','DOWNLOADS','AJUSTES'}
local labels={
  pt={'INICIO','CATALOGO','INSTALADOS','DOWNLOADS','AJUSTES'},
  en={'HOME','CATALOG','INSTALLED','DOWNLOADS','SETTINGS'}
}
local palette={
  bg={0.035,0.054,0.09},panel={0.068,0.100,0.157},panel2={0.090,0.136,0.202},
  line={0.16,0.24,0.32},txt={0.94,0.97,1.0},muted={0.56,0.65,0.74},
  blue={0.19,0.73,1},teal={0.27,0.91,0.77},red={1,0.39,0.45}
}
local lang='pt';local card=1;local tab=1;local chosen=1;local modal=nil
local catalog={};local installed={};local status={phase='idle',message=''}
local notice='';local noticeTime=0;local poll=0;local fonts={}
local function t(pt,en) return lang=='pt' and pt or en end
local function col(c,a) love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function panel(x,y,w,h,active)
  col(active and palette.panel2 or palette.panel)
  love.graphics.rectangle('fill',x,y,w,h,10,10)
  col(active and palette.blue or palette.line)
  love.graphics.rectangle('line',x+0.5,y+0.5,w-1,h-1,10,10)
end
local function printx(s,x,y,sz,color,width)
  col(color or palette.txt);love.graphics.setFont(fonts[sz or 14])
  if width then
    love.graphics.printf(tostring(s or ''),x,y,width,'left')
  else love.graphics.print(tostring(s or ''),x,y) end
end
local function read(path)
  local f=io.open(path,'rb');if not f then return nil end
  local s=f:read('*a');f:close();return s
end
local function write(path,data)
  local f=io.open(path,'wb');if not f then return false end
  f:write(data);f:close();return true
end
local function validPort(p)
  if type(p)~='table' or type(p.id)~='string' or
    not p.id:match('^[a-z0-9][a-z0-9_-]*$') or #p.id>64 or
    type(p.name)~='string' or #p.name>160 or
    type(p.download_url)~='string' or
    not p.download_url:match('^https://') then return false end
  return true
end
local function setCatalog(raw)
  local data=json.decode(raw or '')
  if not data or type(data)~='table' or type(data.ports)~='table' then return false end
  local fresh={};local seen={}
  for _,p in ipairs(data.ports) do
    if validPort(p) and not seen[p.id] then
      fresh[#fresh+1]=p;seen[p.id]=true
    end
  end
  table.sort(fresh,function(a,b) return a.name:lower()<b.name:lower() end)
  catalog=fresh;chosen=1
  return true
end
local function loadCatalog()
  if setCatalog(read(STATE..'/catalog.json')) then return end
  local pack=love.filesystem.read('catalog.json')
  if pack then setCatalog(pack) end
end
local function loadInstalled()
  local result={}
  local pipe=io.popen('find "'..STATE..'/installations" -maxdepth 1 -type f -name "*.json" -print 2>/dev/null')
  if pipe then
    for path in pipe:lines() do
      local p=json.decode(read(path) or '')
      if type(p)=='table' and type(p.id)=='string' and type(p.name)=='string'
        and (p.root=='/roms/ports' or p.root=='/roms2/ports')
        and type(p.script)=='string' and p.script:match('^[^/]+%.sh$') then
        result[#result+1]=p
      end
    end
    pipe:close()
  end
  table.sort(result,function(a,b)return a.name:lower()<b.name:lower() end)
  installed=result
end
local function parseStatus()
  local st={phase='idle',message=''}
  for line in (read(STATE..'/job.status') or ''):gmatch('[^\r\n]+') do
    local k,v=line:match('^([a-z_]+)=(.*)$')
    if k then st[k]=v end
  end
  status=st
end
local function shout(msg)
  notice=msg;noticeTime=5
end
local function quote(s)
  return "'"..tostring(s):gsub("'","'\\''").."'"
end
local function worker(cmd,args)
  if status.phase=='catalog' or status.phase=='downloading' or
    status.phase=='verifying' or status.phase=='extracting' or status.phase=='installing' or
    status.phase=='uninstalling' then
    shout(t('Uma operacao ja esta em andamento','An operation is already running'));return
  end
  local all={'/bin/bash',quote(HOME..'/bin/worker.sh'),quote(cmd)}
  for _,v in ipairs(args) do all[#all+1]=quote(v) end
  local command=table.concat(all,' ')..' >/dev/null 2>&1 </dev/null &'
  local result=os.execute(command)
  if result==false or result==nil then shout(t('Falha ao iniciar operacao','Cannot start operation'))
  else status={phase=cmd=='catalog' and 'catalog' or cmd=='install' and 'downloading' or 'uninstalling',
      message=t('Preparando operacao...','Preparing operation...')} end
end
local function refresh()
  local raw=read(HOME..'/config/catalog_url.txt') or ''
  local url=raw:match('https://[^%s]+') or ''
  if url=='' then
    shout(t('Defina catalog_url.txt com uma URL publica HTTPS','Set public HTTPS URL in catalog_url.txt'))
  else worker('catalog',{url}) end
end
local function install(p)
  local sha=p.sha256 or ''
  if type(sha)~='string' or #sha~=64 or not sha:match('^%x+$') then
    shout(t('Port sem SHA-256: instalacao bloqueada','Missing SHA-256: install blocked'));return
  end
  local root=card==1 and '/roms/ports' or '/roms2/ports'
  local n=math.floor(tonumber(p.size_bytes) or 0)
  worker('install',{p.id,root,p.download_url,sha,tostring(n),p.name})
  tab=4
end
local function remove(p)
  worker('uninstall',{p.id,p.root});tab=4
end
local function launch(p)
  local path=p.root..'/'..p.script
  if path:match('^/roms2?/ports/[^/]+%.sh$') and write(STATE..'/launch.request',path..'\n') then
    love.event.quit()
  else shout(t('Nao foi possivel iniciar','Unable to launch')) end
end
local function currentList()
  if tab==2 then return catalog elseif tab==3 then return installed else return {} end
end
local function drawHeader()
  col(palette.bg);love.graphics.rectangle('fill',0,0,W,H)
  col(palette.blue,0.065);love.graphics.circle('fill',600,20,170)
  col(palette.teal,0.035);love.graphics.circle('fill',-35,470,150)
  col(palette.blue);love.graphics.rectangle('fill',0,0,4,H)
  printx('R36S',24,18,22,palette.blue)
  printx('PORTS BR STORE',96,19,19)
  printx('KPM  /  '..t('CENTRAL DE PORTS','PORT CENTER'),24,50,11,palette.muted)
  for i,txt in ipairs(labels[lang]) do
    local x=24+(i-1)*119
    if tab==i then
      panel(x,75,115,34,true)
    end
    printx(txt,x+9,84,11,tab==i and palette.blue or palette.muted)
  end
end
local function drawFooter()
  col(palette.panel);love.graphics.rectangle('fill',0,449,W,31)
  col(palette.line);love.graphics.rectangle('fill',0,449,W,1)
  printx(t('A OK  B VOLTAR  L/R ABAS  Y SINCRONIZAR','A SELECT  B BACK  L/R TABS  Y SYNC'),22,459,11,palette.muted)
  printx('v0.1.0',568,459,11,palette.blue)
end
local function drawHome()
  panel(24,130,592,128)
  printx(t('SEUS PORTS, EM UM SO LUGAR','ALL YOUR PORTS. ONE PLACE.'),43,150,21,palette.txt,550)
  printx(t('Catalogo online, validacao SHA-256 e instalacao no SD.','Online catalog, SHA-256 and SD install.'),43,193,13,palette.muted,540)
  printx(t('Pressione A para explorar o catalogo','Press A to browse the catalog'),43,221,13,palette.blue)
  local blocks={{t('NO CATALOGO','IN CATALOG'),#catalog},{t('INSTALADOS','INSTALLED'),#installed},{t('CARTAO','CARD'),card==1 and 'SD1' or 'SD2'}}
  for i,item in ipairs(blocks) do
    local x=24+(i-1)*201;panel(x,273,191,112)
    printx(item[1],x+16,289,12,palette.muted)
    printx(tostring(item[2]),x+16,313,28,palette.teal)
  end
end
local function drawList()
  local list=currentList()
  printx(tab==2 and t('CATALOGO KPM  •  X: GAMESTORE BR','KPM CATALOG  •  X: GAMESTORE BR') or t('PORTS INSTALADOS','INSTALLED PORTS'),26,119,15)
  if #list==0 then
    panel(24,148,592,197)
    printx(tab==2 and t('Catalogo vazio. Configure URL em AJUSTES.','Empty catalog. Configure the URL in SETTINGS.')
      or t('Nenhum port instalado por esta loja.','No managed ports installed.'),42,225,14,palette.muted,550)
    return
  end
  local first=math.max(1,chosen-4)
  if first>math.max(1,#list-4) then first=math.max(1,#list-4) end
  for i=first,math.min(first+4,#list) do
    local p,y=list[i],150+(i-first)*55
    panel(24,y,592,50,i==chosen)
    if i==chosen then col(palette.blue);love.graphics.rectangle('fill',24,y+8,3,34,2,2) end
    printx(p.name or p.id,43,y+7,15,palette.txt,425)
    local subtitle=tab==2 and (p.category or 'PORT') or (p.root=='/roms2/ports' and 'SD2' or 'SD1')
    if tab==2 and type(p.size_bytes)=='number' and p.size_bytes>0 then
      subtitle=subtitle..'  /  '..math.floor(p.size_bytes/1048576)..' MB'
    end
    printx(subtitle,43,y+30,11,palette.muted,470)
    printx('>',582,y+14,16,i==chosen and palette.blue or palette.muted)
  end
  printx(chosen..' / '..#list,540,425,12,palette.muted)
end
local function drawDownload()
  printx(t('TRANSFERENCIAS','TRANSFERS'),26,121,16)
  panel(24,155,592,241)
  local phase=status.phase or 'idle'
  local color=phase=='error' and palette.red or phase=='done' and palette.teal or palette.blue
  printx(phase:upper(),43,180,21,color)
  printx(status.message or '',43,220,13,palette.muted,545)
  local progress=0
  if phase=='downloading' and status.file and tonumber(status.expected) and tonumber(status.expected)>0 then
    local f=io.open(status.file,'rb')
    if f then progress=math.min(1,(f:seek('end') or 0)/tonumber(status.expected));f:close() end
  elseif phase=='done' then progress=1 end
  col(palette.line);love.graphics.rectangle('fill',43,281,553,13,7,7)
  col(color);love.graphics.rectangle('fill',43,281,553*progress,13,7,7)
  printx(phase=='downloading' and string.format('%.0f%%',progress*100) or
       t('Progresso por etapa','Progress by stage'),43,309,13,palette.muted)
  printx(t('Logs: state/logs/worker.log','Logs: state/logs/worker.log'),43,365,11,palette.muted)
end
local function drawSettings()
  printx(t('PREFERENCIAS','PREFERENCES'),26,119,16)
  panel(24,151,592,238)
  printx(t('A  /  ALTERNAR IDIOMA','A  /  CHANGE LANGUAGE'),44,173,16,palette.blue)
  printx(lang=='pt' and 'PORTUGUES (BR)' or 'ENGLISH',44,202,13,palette.muted)
  printx(t('X  /  ALTERNAR CARTAO','X  /  CHANGE CARD'),44,241,16,palette.blue)
  printx(card==1 and 'SD1  /roms/ports' or 'SD2  /roms2/ports',44,270,13,palette.muted)
  printx(t('Y  /  SINCRONIZAR CATALOGO','Y  /  SYNC CATALOG'),44,309,16,palette.blue)
  printx('config/catalog_url.txt  /  HTTPS',44,338,12,palette.muted)
end
local function drawModal()
  if not modal then return end
  col({0,0,0},0.70);love.graphics.rectangle('fill',0,0,W,H)
  panel(65,145,510,189,true)
  printx(modal.kind=='install' and t('CONFIRMAR INSTALACAO','CONFIRM INSTALLATION')
    or t('CONFIRMAR REMOCAO','CONFIRM REMOVAL'),86,168,18,palette.txt)
  printx(modal.item.name or modal.item.id,86,204,14,palette.muted,465)
  if modal.kind=='install' then
    printx(t('Destino: ','Destination: ')..(card==1 and 'SD1' or 'SD2'),86,239,13,palette.blue)
  else printx(t('Os arquivos e saves internos serao excluidos.','Files and internal saves will be deleted.'),86,239,12,palette.red) end
  printx(t('A CONFIRMAR    B CANCELAR','A CONFIRM    B CANCEL'),86,286,13,palette.teal)
end
function love.load()
  love.graphics.setDefaultFilter('linear','linear')
  fonts[11]=love.graphics.newFont(11)
  fonts[12]=love.graphics.newFont(12)
  fonts[13]=love.graphics.newFont(13)
  fonts[14]=love.graphics.newFont(14)
  fonts[15]=love.graphics.newFont(15)
  fonts[16]=love.graphics.newFont(16)
  fonts[18]=love.graphics.newFont(18)
  fonts[19]=love.graphics.newFont(19)
  fonts[21]=love.graphics.newFont(21)
  fonts[22]=love.graphics.newFont(22)
  fonts[28]=love.graphics.newFont(28)
  external.init(HOME,STATE)
  loadCatalog();loadInstalled();parseStatus()
end
function love.update(dt)
  external.update(dt)
  poll=poll+dt
  noticeTime=math.max(0,noticeTime-dt)
  if poll>=0.55 then
    poll=0;parseStatus()
    local pending=read(STATE..'/catalog.pending.json')
    if pending and status.phase=='done' then
      if setCatalog(pending) then
        os.rename(STATE..'/catalog.pending.json',STATE..'/catalog.json')
        shout(t('Catalogo atualizado!','Catalog updated!'))
      else
        os.remove(STATE..'/catalog.pending.json')
        shout(t('Catalogo remoto invalido; cache preservado.','Invalid remote catalog; cache preserved.'))
      end
    end
    loadInstalled()
  end
end
function love.draw()
  drawHeader()
  if tab==1 then drawHome() elseif tab==2 and external.active then external.draw()
  elseif tab==2 or tab==3 then drawList()
  elseif tab==4 then drawDownload() else drawSettings() end
  if noticeTime>0 then
    panel(24,404,592,35,true)
    printx(notice,36,415,12,palette.txt,565)
  end
  drawFooter();drawModal()
end
local function action(key)
  if tab==2 and external.active and external.handle(key) then return end
  if tab==2 and key=='x' then external.toggle(); return end
  if modal then
    if key=='b' then modal=nil
    elseif key=='a' then
      local m=modal;modal=nil
      if m.kind=='install' then install(m.item) else remove(m.item) end
    end
    return
  end
  if key=='l' or key=='left' then tab=tab==1 and 5 or tab-1;chosen=1
  elseif key=='r' or key=='right' then tab=tab==5 and 1 or tab+1;chosen=1
  elseif key=='up' then chosen=math.max(1,chosen-1)
  elseif key=='down' then chosen=math.min(math.max(#currentList(),1),chosen+1)
  elseif key=='y' then refresh()
  elseif key=='b' then tab=1;chosen=1
  elseif key=='x' then
    if tab==5 then card=card==1 and 2 or 1
    elseif tab==3 then
      local p=installed[chosen];if p then modal={kind='remove',item=p} end
    end
  elseif key=='a' then
    if tab==1 then tab=2;chosen=1
    elseif tab==5 then lang=lang=='pt' and 'en' or 'pt'
    elseif tab==2 then
      local p=catalog[chosen];if p then modal={kind='install',item=p} end
    elseif tab==3 then
      local p=installed[chosen];if p then launch(p) end
    end
  end
end
function love.keypressed(k)
  local keys={['return']='a',kpenter='a',escape='b',backspace='b',
    up='up',down='down',left='left',right='right',q='l',e='r',
    f5='y',r='y',delete='x',x='x',start='start'}
  action(keys[k] or k)
end
function love.gamepadpressed(_,button)
  local keys={a='a',b='b',x='x',y='y',dpup='up',dpdown='down',
    dpleft='left',dpright='right',leftshoulder='l',rightshoulder='r',start='start'}
  if keys[button] then action(keys[button]) end
end
