-- Navegador independente de metadados GameStoreBR. Não reutiliza o app original.
local json=require('json')
local M={active=true}
local HOME,STATE
local games,categories={},{}
local view='games'
local selected,categorySelected,page,totalPages=1,1,1,1
local category='ALL'
local prompt=nil
local pending=nil
local info='Pressione Y para atualizar o catálogo externo'
local recentStatus=''
local cachedGames=''
local cachedCategories=''
local sd=1
local sizes={}
local colors={
  panel={.068,.100,.157},chosen={.09,.136,.202},line={.16,.24,.32},
  fg={.94,.97,1},soft={.56,.65,.74},cyan={.19,.73,1},green={.27,.91,.77},
  red={1,.39,.45}
}
local function read(file)
  local f=io.open(file,'rb');if not f then return nil end
  local x=f:read('*a');f:close();return x
end
local function quote(s) return "'"..tostring(s):gsub("'","'\\''").."'" end
local function command(args)
  local list={"python3",quote(HOME.."/bin/gamestore_source.py")}
  for _,v in ipairs(args) do list[#list+1]=quote(v) end
  local result=os.execute(table.concat(list," ").." >/dev/null 2>&1 </dev/null &")
  return result~=false and result~=nil
end
local function launch(task,args)
  if pending then
    info="Já existe uma operação GameStoreBR em andamento"
    return
  end
  pending=task
  recentStatus=''
  os.remove(STATE..'/gamestore_status.json') -- descarta status de operacao anterior
  info="Conectando ao catálogo remoto..."
  if not command(args) then
    info="Não foi possível iniciar Python 3"
    pending=nil
  end
end
local function loadCategories()
  local raw=read(STATE..'/gamestore_categories.json')
  if raw and raw~=cachedCategories then
    local d=json.decode(raw)
    if d and type(d.categories)=='table' then
      cachedCategories=raw
      categories=d.categories
    end
  end
end
local function loadGames()
  local raw=read(STATE..'/gamestore_games.json')
  if raw and raw~=cachedGames then
    local d=json.decode(raw)
    if d and type(d.games)=='table' then
      cachedGames=raw;games=d.games
      category=d.category or category
      page=tonumber(d.page) or 1
      totalPages=tonumber(d.total_pages) or 1
      selected=1
    end
  end
end
local function font(n)
  if not sizes[n] then sizes[n]=love.graphics.newFont(n) end
  return sizes[n]
end
local function label(s,x,y,n,c,maxw)
  love.graphics.setFont(font(n))
  love.graphics.setColor(c)
  if maxw then love.graphics.printf(tostring(s or ''),x,y,maxw,'left')
  else love.graphics.print(tostring(s or ''),x,y) end
end
local function rect(x,y,w,h,active)
  love.graphics.setColor(active and colors.chosen or colors.panel)
  love.graphics.rectangle('fill',x,y,w,h,8,8)
  love.graphics.setColor(active and colors.cyan or colors.line)
  love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,8,8)
end
function M.init(home,state)
  HOME,STATE=home,state
  loadCategories();loadGames()
end
function M.enter()
  if not pending and #categories==0 then
    M.refresh()
  elseif not pending and #games==0 then
    launch('games',{'games',category,tostring(page)})
  end
end
function M.card() return sd end
function M.toggleCard() sd=sd==1 and 2 or 1 end
function M.refresh()
  launch('categories',{'categories'})
end
function M.update()
  if not M.active then return end
  local raw=read(STATE..'/gamestore_status.json') or ''
  if not pending or not raw or raw=='' or raw==recentStatus then return end
  local s=json.decode(raw)
  if not s or (s.task and s.task~=pending) then return end
  recentStatus=raw
  if s.phase=='error' then
    info=s.message or 'API indisponível';pending=nil
  elseif s.phase=='done' then
    local completed=pending
    pending=nil;info=s.message or 'Concluído'
    if completed=='categories' then
      loadCategories()
      launch('games',{'games',category,tostring(page)})
    elseif completed=='games' then
      loadGames()
    end
  elseif s.message then info=s.message end
end
local function chooseCategory()
  if #categories==0 then M.refresh();return end
  view='categories';categorySelected=1
  for i,v in ipairs(categories) do
    if v.category==category then categorySelected=i;break end
  end
end
local function changePage(n)
  local nextPage=page+n
  if not pending and nextPage>=1 and nextPage<=totalPages then
    launch('games',{'games',category,tostring(nextPage)})
  end
end
function M.draw()
  label('GAMESTORE BR  /  CATÁLOGO',24,120,15,colors.fg)
  label('START: PLATAFORMA   Y: ATUALIZAR',24,140,11,colors.cyan)
  if view=='games' then
    label(category..'  |  Página '..page..' / '..totalPages..'  |  '..(sd==1 and 'SD1' or 'SD2'),24,158,11,colors.soft)
    local begin=math.max(1,selected-4)
    for i=begin,math.min(begin+4,#games) do
      local game=games[i]
      local y=180+(i-begin)*46
      rect(24,y,592,43,i==selected)
      label(game.name or '?',39,y+6,14,colors.fg,540)
      label(game.category or '',39,y+26,10,colors.soft,540)
    end
    if #games==0 then label('Sem jogos carregados. Aperte Y para atualizar.',34,237,13,colors.soft,560) end
    label('A: BAIXAR    ◄/►: PÁGINA    Y: ATUALIZAR',24,418,11,colors.soft)
  else
    label('ESCOLHA UMA PLATAFORMA',24,162,12,colors.soft)
    local begin=math.max(1,categorySelected-4)
    for i=begin,math.min(begin+4,#categories) do
      local item=categories[i]
      local y=184+(i-begin)*46
      rect(24,y,592,43,i==categorySelected)
      label((item.category or '?')..'   •   '..tostring(item.count or 0),39,y+12,14,colors.fg,530)
    end
    label('A: SELECIONAR    B: VOLTAR',24,418,11,colors.soft)
  end
  if pending or info~='' then
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle('fill',24,393,592,22,5,5)
    label(info,32,397,11,colors.soft,570)
  end
  if prompt then
    love.graphics.setColor(0,0,0,.75)
    love.graphics.rectangle('fill',0,0,640,480)
    rect(54,145,532,196,true)
    label('BAIXAR JOGO PARA O CARTÃO?',76,167,17,colors.fg)
    label(prompt.name or '',76,205,14,colors.soft,482)
    label('SD: '..(sd==1 and 'SD1' or 'SD2')..'  •  '..(prompt.category or ''),76,240,13,colors.cyan)
    label('A: CONFIRMAR  B: CANCELAR  X: TROCAR SD',76,293,12,colors.green)
  end
end
function M.handle(key)
  if not M.active then return false end
  if prompt then
    if key=='b' then prompt=nil
    elseif key=='x' then sd=sd==1 and 2 or 1
    elseif key=='a' then
      local g=prompt;prompt=nil
      launch('download',{'download',g.game_path,g.category,sd==1 and 'sd1' or 'sd2',g.name,g.sha256 or ''})
    end
    return true
  end
  if key=='y' then M.refresh();return true end
  if key=='start' then chooseCategory();return true end
  if key=='b' then
    if view=='categories' then view='games';return true end
    return false
  end
  if key=='up' then
    if view=='categories' then categorySelected=math.max(1,categorySelected-1)
    else selected=math.max(1,selected-1) end
    return true
  end
  if key=='down' then
    if view=='categories' then categorySelected=math.min(#categories,categorySelected+1)
    else selected=math.min(#games,selected+1) end
    return true
  end
  if key=='left' or key=='right' then
    if view=='games' then changePage(key=='right' and 1 or -1) end
    return true
  end
  if key=='a' then
    if view=='categories' then
      local choice=categories[categorySelected]
      if choice then
        category=choice.category;page=1;view='games'
        launch('games',{'games',category,'1'})
      end
    else
      local choice=games[selected]
      if choice then prompt=choice end
    end
    return true
  end
  return false
end
return M
