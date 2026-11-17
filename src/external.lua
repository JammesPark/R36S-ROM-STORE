-- GameStoreBR: somente adaptador de dados. O layout pertence a main.lua.
local json=require('json')
local M={categories={{category='ALL',count=0}},games={},category='ALL',page=1,totalPages=1,total=0,
         pending=nil,phase='idle',message='',downloaded=0,expected=0,error=false,connected=nil,maintenance=false}
local home,state,lastStatus='',nil
local function read(path)
  local f=io.open(path,'rb');if not f then return nil end
  local txt=f:read('*a');f:close();return txt
end
local function quote(s) return "'"..tostring(s):gsub("'","'\\''").."'" end
local function command(args)
  local argv={'python3',quote(home..'/bin/gamestore_source.py')}
  for _,v in ipairs(args) do argv[#argv+1]=quote(v) end
  local ok=os.execute(table.concat(argv,' ')..' >/dev/null 2>&1 </dev/null &')
  return ok~=nil and ok~=false
end
local function cached(path)
  local txt=read(path);if not txt then return nil end
  local parsed=json.decode(txt)
  return type(parsed)=='table' and parsed or nil
end
function M.loadCategories()
  local data=cached(state..'/gamestore_categories.json')
  if data and type(data.categories)=='table' and #data.categories>0 then
    M.categories=data.categories
  end
end
function M.loadGames()
  local data=cached(state..'/gamestore_games.json')
  if data and type(data.games)=='table' then
    M.games=data.games;M.category=data.category or M.category
    M.page=tonumber(data.page) or 1
    M.totalPages=math.max(1,tonumber(data.total_pages) or 1)
    M.total=math.max(0,tonumber(data.total) or #M.games)
    return true
  end
  return false
end
function M.init(appPath, statePath)
  home,state=appPath,statePath
  M.loadCategories();M.loadGames()
end
function M.request(task,args)
  if M.pending then return false end
  args=args or {}; local cmd={task}
  for _,arg in ipairs(args) do cmd[#cmd+1]=arg end
  lastStatus='';os.remove(state..'/gamestore_status.json')
  M.pending=task;M.phase='loading';M.message='Conectando...';M.error=false;M.maintenance=false
  if not command(cmd) then
    M.pending=nil;M.phase='error';M.message='Python 3 indisponível';M.error=true
    return false
  end
  return true
end
function M.enter()
  if #M.categories<=1 then M.request('categories')
  elseif #M.games==0 then M.request('games',{M.category,tostring(M.page)}) end
end
function M.refresh()
  return M.request('categories')
end
function M.categoryChange(category)
  if M.pending then return false end
  local old=M.category
  M.category=category;M.page=1
  local ok=M.request('games',{category,'1'})
  if not ok then M.category=old end
  return ok
end
function M.pageChange(delta)
  local target=M.page+delta
  if M.pending or target<1 or target>M.totalPages then return false end
  return M.request('games',{M.category,tostring(target)})
end
function M.download(g,card)
  if not g or not g.game_path or not g.category then return false end
  return M.request('download',{g.game_path,g.category,card==2 and 'sd2' or 'sd1',g.name or 'ROM',g.sha256 or ''})
end
function M.update()
  local raw=read(state..'/gamestore_status.json')
  if not raw or raw==lastStatus then return end
  local s=json.decode(raw)
  if type(s)~='table' or not M.pending or (s.task and s.task~=M.pending) then return end
  lastStatus=raw
  M.phase=s.phase or 'idle';M.message=s.message or ''
  M.downloaded=tonumber(s.downloaded) or M.downloaded or 0
  M.expected=tonumber(s.expected) or 0
  if M.phase=='error' then
    local task=M.pending
    M.error=true;M.pending=nil
    if task=='categories' or task=='games' then M.connected=false end
    M.maintenance=M.message:lower():find('manuten',1,true)~=nil or M.message:lower():find('maintenance',1,true)~=nil
  elseif M.phase=='done' then
    local task=M.pending;M.pending=nil
    if task=='categories' or task=='games' then M.connected=true;M.maintenance=false end
    if task=='categories' then
      M.loadCategories()
      if not M.request('games',{M.category,tostring(M.page)}) then M.error=true end
    elseif task=='games' then
      M.loadGames()
      -- As capas sao opcionais: baixadas em paralelo, sem bloquear o menu.
      command({'covers'})
    end
  end
end
function M.totalCatalog()
  -- O agregado exclui ALL para não contar todas as ROMs em duplicidade.
  local total=0;local haveCounts=false
  for _,item in ipairs(M.categories) do
    if type(item)=='table' and item.category~='ALL' then
      haveCounts=true
      total=total+math.max(0,math.floor(tonumber(item.count) or 0))
    end
  end
  if haveCounts then return total end
  return nil
end
function M.networkState()
  if M.maintenance then return 'maintenance' end
  if M.pending=='categories' or M.pending=='games' then return 'syncing' end
  if M.connected==true then return 'online' end
  if M.connected==false then return 'offline' end
  return 'syncing' -- Ainda sem uma resposta remota confirmada.
end

function M.busy() return M.pending~=nil end
function M.statePath() return state end
return M
