-- R36S ROMS STORE | Tema de 19 telas (conceito HTML 640x480) aplicado em Lua/LÖVE.
-- Catálogo real: GameStoreBR; nenhum jogo demonstrativo é distribuído.
local json=require('json')
local external=require('external')
local ui=require('ui')
local theme=require('theme')
local i18n=require('i18n')
local device=require('device_status')
local HOME=os.getenv('R36S_STORE_HOME') or '/roms/ports/r36s-roms-store'
local STATE=HOME..'/state'
local mainPages={'home','catalog','downloads','installed','favorites','settings','about'}
local menuPages={'home','catalog','downloads','installed','favorites','settings','about','exit'}
local screen='startup'
local stack={}
local settings={language='pt',theme='ocean',font_size='medium'}
local favorites={}
local downloads={}
local focus='grid'; local menuIndex=1;local categoryIndex=1;local gameIndex=1
local favIndex=1;local installIndex=1;local historyIndex=1;local settingsIndex=1;local downloadScroll=0
local languageIndex=1;local themeIndex=1;local fontSizeIndex=2;local searchIndex=1;local query='';local searchResultIndex=1
local selectedGame=nil
local lastStatus='';local lastManifest='';local coverImages={};local coverSeen={}
local clock=0;local startupTime=0;local notice='';local noticeTime=0
local selectedCard=1;local transferHandled=false
local homeFocus='explore';local homeSlideIndex=1;local homeOverviewIndex=1;local homeSlideClock=0
local storageInfo={};local storageLast=-999
local suboptions={'languages','themes','font_size','storage','network','help'}
local fontSizes={'small','medium','large'}
local keyboard={'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','SPACE','DEL','CLEAR','OK'}
local function tr(key) return i18n.get(settings.language,key) end
local function txt(s,x,y,sz,c,w,center) ui.text(s,x,y,sz,c,w,center) end
local function R(x,y,w,h,c,round,border,a) ui.rect(x,y,w,h,c,round,border,a) end
local function panel(x,y,w,h,active) ui.panel(x,y,w,h,active) end
local function read(path)
  local f=io.open(path,'rb');if not f then return nil end
  local s=f:read('*a');f:close();return s
end
local function write(path,value)
  local f=io.open(path,'wb');if not f then return false end
  f:write(value);f:close();return true
end
local function encodeString(s)
  local replacements={['\\']='\\\\',['"']='\\"',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
  return '"'..tostring(s or ''):gsub('[\\"\n\r\t]',replacements)..'"'
end
local function saveSettings()
  write(STATE..'/roms_settings.json',string.format('{"language":%s,"theme":%s,"font_size":%s}',
    encodeString(settings.language),encodeString(settings.theme),encodeString(settings.font_size)))
end
local function saveFavorites()
  local items={}
  for _,g in ipairs(favorites) do
    local pairs={}
    for _,k in ipairs({'name','category','game_path','image_url','cover_id'}) do
      if type(g[k])=='string' then pairs[#pairs+1]=encodeString(k)..':'..encodeString(g[k]) end
    end
    items[#items+1]='{'..table.concat(pairs,',')..'}'
  end
  write(STATE..'/roms_favorites.json','['..table.concat(items,',')..']')
end
local function loadData()
  local c=json.decode(read(STATE..'/roms_settings.json') or '')
  if type(c)=='table' then
    for _,l in ipairs(i18n.languages) do if l.code==c.language then settings.language=l.code end end
    for _,t in ipairs(theme.options) do if t.key==c.theme then settings.theme=t.key end end
    for idx,v in ipairs(fontSizes) do
      if v==c.font_size then settings.font_size=v;fontSizeIndex=idx end
    end
  end
  local f=json.decode(read(STATE..'/roms_favorites.json') or '')
  if type(f)=='table' then
    for _,v in ipairs(f) do
      if type(v)=='table' and type(v.game_path)=='string' and type(v.name)=='string' then
        favorites[#favorites+1]=v
      end
    end
  end
  theme.set(settings.theme)
  ui.setFontSize(settings.font_size)
end
local function reloadDownloads()
  local s=read(STATE..'/roms_downloads.json')
  if not s or s==lastManifest then return end
  local list=json.decode(s)
  if type(list)=='table' then downloads=list;lastManifest=s end
end
local function favoriteIdx(g)
  if not g or not g.game_path then return nil end
  for i,item in ipairs(favorites) do
    if item.game_path==g.game_path then return i end
  end
end
local function toggleFavorite(g)
  if not g then return end
  local index=favoriteIdx(g)
  if index then table.remove(favorites,index);notice='★ '..tr('favorites')..': -'
  else favorites[#favorites+1]={name=g.name,category=g.category,game_path=g.game_path,
    image_url=g.image_url or '',cover_id=g.cover_id or ''}
    notice='★ '..tr('favorites')..': +'
  end
  saveFavorites();noticeTime=2.4
end
local function exists(path)
  local f=io.open(path,'rb');if not f then return false end
  f:close();return true
end
local function sdLocation(game)
  local a,b=false,false
  if not game then return tr('not_downloaded') end
  for _,d in ipairs(downloads) do
    if d.game_path==game.game_path and type(d.filename)=='string' and
       type(d.category)=='string' and d.filename:find('/',1,true)==nil and
       d.category:match('^[a-z0-9_%-]+$') then
      local path=(d.card=='sd2' and '/roms2/' or '/roms/')..d.category..'/'..d.filename
      if exists(path) then if d.card=='sd2' then b=true else a=true end end
    end
  end
  if a and b then return tr('both') end
  if a then return 'SD1' end
  if b then return 'SD2' end
  return tr('not_downloaded')
end
local function currentGames()
  if screen=='favorites' then return favorites end
  if screen=='search_results' then return external.searchResults end
  return external.games
end
local function dfUsage(path)
  local pipe=io.popen('df -Pk '..path..' 2>/dev/null','r')
  if not pipe then return nil end
  local line
  for v in pipe:lines() do line=v end
  pipe:close()
  if not line then return nil end
  local tokens={}
  for tok in line:gmatch('%S+') do tokens[#tokens+1]=tok end
  if #tokens<5 then return nil end
  local total,available=tonumber(tokens[2]),tonumber(tokens[4])
  if not total or total<=0 or not available then return nil end
  return {total=total*1024,free=math.max(0,available)*1024}
end
local function mountSource(path)
  local cmd='findmnt -T '..path..' -no SOURCE 2>/dev/null'
  local pipe=io.popen(cmd,'r')
  if not pipe then return nil end
  local src=pipe:read('*l');pipe:close()
  return src and src~='' and src or nil
end
local function refreshStorage()
  local sd1=mountSource('/roms')
  local sd2=mountSource('/roms2')
  storageInfo[1]=dfUsage('/roms')
  -- SD2 não pode mostrar o espaço do SD1 ou da raiz quando não montado.
  storageInfo[2]=(sd1 and sd2 and sd1~=sd2) and dfUsage('/roms2') or nil
  storageLast=clock
end
local function formatBytes(bytes)
  if not bytes then return tr('unavailable') end
  local gb=bytes/1073741824
  if gb>=1 then return string.format('%.1f GB',gb) end
  return string.format('%.0f MB',bytes/1048576)
end

local function navigate(route)
  if screen~=route then stack[#stack+1]=screen end
  screen=route
  if route=='storage' then refreshStorage() end
  if route=='font_size' then
    for idx,v in ipairs(fontSizes) do if v==settings.font_size then fontSizeIndex=idx end end
  end
end
local function mainRoute(route)
  screen=route;stack={};focus=route=='home' and 'sidebar' or 'grid'
  if route=='home' then homeFocus='explore';homeOverviewIndex=1 end
  for i,k in ipairs(mainPages) do if k==route then menuIndex=i end end
  if route=='catalog' then external.enter() end
end
local function back()
  if #stack>0 then screen=table.remove(stack)
  elseif screen~='home' then mainRoute('home') end
end
local function selectedFromGames()
  local list=currentGames()
  return list[screen=='search_results' and searchResultIndex or gameIndex]
end
local function enterGame(g)
  if not g then return end
  selectedGame=g
  navigate('detail')
end
local function chooseCategory()
  local cat=external.categories[categoryIndex]
  if cat then
    external.categoryChange(cat.category)
    gameIndex=1;focus='grid'
  end
end
local function cachedImage(game)
  if not game or not game.cover_id or game.cover_id=='' then return nil end
  local id=game.cover_id
  if coverImages[id] then return coverImages[id] end
  if coverSeen[id] and clock-coverSeen[id]<3 then return nil end
  coverSeen[id]=clock
  local bytes=read(STATE..'/covers/'..id..'.img')
  if not bytes or #bytes>700*1024 then return nil end
  local ok,im=pcall(function()
    local file=love.filesystem.newFileData(bytes,'rom-cover.png')
    return love.graphics.newImage(file)
  end)
  if ok and im then
    local count=0
    for _ in pairs(coverImages) do count=count+1 end
    if count>14 then coverImages={} end
    coverImages[id]=im
    return im
  end
end
local function cover(game,x,y,w,h,index)
  ui.poster(x,y,w,h,game and game.name or '?',index or 1)
  local img=cachedImage(game)
  if img then
    R(x,y,w,h,theme.panel,4)
    ui.imageContain(img,x+2,y+2,w-4,h-4)
  end
end
local function platformTitle(code)
  code=tostring(code or '')
  if code=='ALL' then return tr('all') end
  if code:lower()=='ports' then return 'Homebrew' end
  local aliases={nes='NES',snes='SNES',psx='PSX',ps1='PS1',ps2='PS2',psp='PSP',
    gba='GBA',gb='GB',gbc='GBC',nds='NDS',n64='N64',n3ds='3DS',mame='MAME',
    nintendo64='Nintendo 64',megadrive='Mega Drive',genesis='Genesis',
    dreamcast='Dreamcast',saturn='Saturn',wii='Wii',gamecube='GameCube'}
  local raw=code:lower()
  if aliases[raw] then return aliases[raw] end
  return raw:gsub('(%a)([%w]*)',function(c,rest) return c:upper()..rest end)
end
local function sideItem(name,y,active,index,count)
  if active then
    R(13,y,134,34,theme.panel2,8,theme.accent)
    R(13,y+7,3,20,theme.accent,1)
  end
  -- Icones vetoriais especificos para cada categoria/plataforma.
  local iconColor=active and theme.accent or theme.muted
  if screen=='catalog' or screen=='search_results' then
    local c=external.categories[index]
    ui.platformIcon(c and c.category or 'ALL',26,y+9,iconColor)
  else
    ui.menuIcon(menuPages[index] or 'home',26,y+9,iconColor)
  end
  txt(ui.ellipsize(name,17),47,y+9,11,active and theme.text or theme.muted,83)
  if count then txt(tostring(count),131,y+10,9,theme.accent,13) end
end
local function sidebar()
  local isCatalog=screen=='catalog' or screen=='search_results'
  local isCategory=isCatalog
  ui.layout(isCatalog,focus)
  if isCategory then
    txt(tr('platforms'),27,89,10,theme.low)
    local top=121
    local total=#external.categories
    local scroll=math.max(1,math.min(categoryIndex-4,total-7))
    for idx=scroll,math.min(total,scroll+7) do
      local cat=external.categories[idx]
      local name=platformTitle(cat.category)
      sideItem(name,top+(idx-scroll)*37,cat.category==external.category,idx)
      if focus=='sidebar' and idx==categoryIndex then ui.stroke(16,top+(idx-scroll)*37+2,128,30,theme.accent,7,2) end
    end
  else
    txt(tr('navigation'),27,89,10,theme.low)
    for i,route in ipairs(menuPages) do
      local y=121+(i-1)*38
      sideItem(tr(route),y,menuIndex==i)
      if screen=='home' and focus=='sidebar' and menuIndex==i then
        ui.stroke(15,y+1,130,32,theme.accent,7,2)
      end
    end
  end
  txt('●',20,449,11,theme.green)
  txt('ROMS STORE',30,452,10,theme.muted)
  txt('640×480',106,452,9,theme.low)
end
local function header(eyebrow,title,right)
  ui.kicker(eyebrow,179,23)
  txt(title,179,42,24,theme.text,440)
  if right then ui.pill(right,548,15,78,false) end
end
local function footer(phrase)
  if screen=='catalog' or screen=='search_results' then
    ui.catalogFooter(tr('select'),tr('back'),tr('search'),tr('page'))
  else
    ui.footer(tr('select'),tr('back'))
  end
  txt('v0.2.6',579,452,10,theme.accent)
end
local function card(game,x,y,w,h,idx,active,badge)
  panel(x,y,w,h,active)
  -- A imagem inteira fica visível; texto isolado numa faixa inferior.
  local coverH=h-34
  cover(game,x+3,y+3,w-6,coverH-4,idx)
  if badge then
    R(x+7,y+coverH-19,w-14,17,theme.sidebar,4,nil,.93)
    txt(ui.ellipsize(badge,18),x+10,y+coverH-16,10,theme.accent,w-20)
  end
  txt(ui.ellipsize(game.name or '?',26),x+7,y+h-29,10,theme.text,w-14)
  if active then ui.stroke(x,y,w,h,theme.accent,9,2) end
end
local function centerEmpty(text,sub)
  panel(180,135,439,243)
  txt(text,201,213,15,theme.text,400,true)
  if sub then txt(sub,201,246,12,theme.muted,400,true) end
end
local function totalRoms()
  return external.totalCatalog()
end

local function homePage()
  header(tr('welcome'),tr('title_home'))
  -- Respiro real entre o cabecalho e o conteudo principal.
  panel(179,103,441,87,focus=='content' and homeFocus=='explore')
  ui.kicker('R36S ROMS STORE',194,110)
  txt(tr('subtitle'),193,133,17,theme.text,401)
  txt(tr('intro'),193,155,10,theme.muted,260)
  R(465,160,143,24,theme.accent,6)
  if focus=='content' and homeFocus=='explore' then ui.stroke(465,160,143,24,theme.text,6,2) end
  txt(tr('explore'),470,165,10,theme.bg,132,true)
  txt(tr('overview'),183,209,12,theme.text,185)
  txt(tr('featured'),422,197,12,theme.text,173)
  local count=totalRoms()
  local stats={{tr('catalog_games'),count and tostring(count) or '—'},
    {tr('installed_games'),tostring(#downloads)},
    {tr('favorites'),tostring(#favorites)}}
  for i,item in ipairs(stats) do
    local y=237+(i-1)*64
    panel(180,y,190,57,focus=='content' and homeFocus=='overview' and homeOverviewIndex==i)
    txt(ui.ellipsize(item[1],23),191,y+6,11,theme.muted,166)
    txt(item[2],191,y+27,19,theme.accent,162)
  end
  -- Slide 1x1 quase vertical, bem mais estreito que a versao anterior.
  panel(418,208,185,220,focus=='content' and homeFocus=='featured')
  local total=#external.games
  if total==0 then
    txt(tr('loading'),425,301,11,theme.muted,166,true)
  else
    homeSlideIndex=math.max(1,math.min(total,homeSlideIndex))
    local game=external.games[homeSlideIndex]
    cover(game,425,217,171,162,homeSlideIndex)
    R(424,381,173,40,theme.panel,4,nil,.98)
    txt(ui.ellipsize(game.name or '?',20),430,387,10,theme.text,159)
    txt(homeSlideIndex..'/'..total,557,407,9,theme.accent,36,true)
    if total>1 then
      local shown=math.min(5,total)
      local first=math.max(1,math.min(homeSlideIndex-math.floor(shown/2),total-shown+1))
      for n=0,shown-1 do
        local dotIndex=first+n
        ui.color(dotIndex==homeSlideIndex and theme.accent or theme.low)
        love.graphics.circle('fill',476+(n-(shown-1)/2)*10,412,dotIndex==homeSlideIndex and 3 or 2)
      end
    end
  end
  footer()
end
-- Lista de ROMs e preview grande da capa do item em foco.
local function gameList(items,chosen)
  local total=#items
  if total==0 then
    centerEmpty(external.error and tr('network_error') or tr('loading'),tr('press_sync'))
    return
  end
  local first=math.floor((chosen-1)/6)*6+1
  local last=math.min(total,first+5)
  for i=first,last do
    local row=i-first;local y=128+row*47
    local active=chosen==i and focus~='sidebar'
    panel(180,y,237,42,active)
    R(188,y+12,3,18,active and theme.accent or theme.border,1)
    txt(ui.ellipsize(items[i].name or '?',31),197,y+7,12,active and theme.text or theme.muted,207)
    txt(string.format('%02d',i),197,y+26,9,active and theme.accent or theme.low,45)
  end
  local selected=items[math.max(1,math.min(total,chosen))]
  panel(428,128,191,289,true)
  txt(tr('game'),438,137,10,theme.accent,167)
  cover(selected,437,159,173,195,chosen)
  R(437,361,173,48,theme.panel2,4)
  txt(ui.ellipsize(selected.name or '?',22),444,368,12,theme.text,158)
  txt('A  '..tr('select'),444,392,10,theme.accent,149)
end
local function catalogPage()
  header(tr('library'),tr('title_catalog'))
  R(578,56,41,29,theme.panel,8,theme.border)
  ui.searchIcon(591,63,theme.accent)
  txt(ui.ellipsize(platformTitle(external.category),18),180,102,12,theme.muted,220)
  txt('• '..(external.total>0 and external.total or #external.games)..' '..tr('games'),352,103,11,theme.accent,119)
  gameList(external.games,gameIndex)
  txt(tr('page')..' '..external.page..'/'..external.totalPages,495,420,10,theme.muted,116)
  footer()
end
local function searchResultsPage()
  header(tr('search'),tr('search_results'))
  ui.searchIcon(590,66,theme.accent)
  txt(ui.ellipsize(external.searchQuery,20),180,103,12,theme.accent,232)
  txt(tostring(external.searchTotal)..' '..tr('games'),443,103,11,theme.muted,165)
  if external.busy() and external.pending=='search' then
    centerEmpty(tr('loading'),tr('search'))
  elseif external.error then
    centerEmpty(tr('network_error'),external.message)
  elseif #external.searchResults==0 then
    centerEmpty(tr('no_results'),tr('search'))
  else
    gameList(external.searchResults,searchResultIndex)
  end
  txt(tr('page')..' '..external.searchPage..'/'..external.searchTotalPages,495,420,10,theme.muted,120)
  footer()
end
local function detailsPage()
  local g=selectedGame or external.games[1]
  header(tr('game'),tr('detail'))
  if not g then centerEmpty(tr('invalid'));footer();return end
  panel(179,113,441,260)
  cover(g,192,129,171,201,gameIndex)
  txt(ui.ellipsize(g.name,32),376,138,17,theme.text,228)
  txt(tostring(g.category or ''):upper(),376,183,12,theme.accent,228)
  txt('● '..sdLocation(g),376,211,11,theme.muted,220)
  txt('★ '..(favoriteIdx(g) and tr('favorites') or tr('favorite_toggle')),376,240,11,theme.muted,215)
  R(376,282,227,35,theme.accent,8)
  txt(tr('download')..' ›',395,293,13,theme.bg,205)
  R(179,382,441,36,theme.panel,7,theme.border)
  txt(tr('favorite_toggle'),190,393,11,theme.accent,402)
  footer()
end
local function searchPage()
  header(tr('search'),tr('search_results'))
  panel(179,102,441,47,true)
  txt(ui.ellipsize(query,44)..(math.floor(clock*2)%2==0 and '|' or ''),194,117,15,theme.text,405)
  txt(tr('search_hint'),187,155,10,theme.low,430)
  for i,key in ipairs(keyboard) do
    local x=180+((i-1)%10)*44;local y=185+math.floor((i-1)/10)*51
    panel(x,y,39,43,searchIndex==i)
    txt(key=='SPACE' and '_' or key=='CLEAR' and 'CLR' or key=='DEL' and '←' or key,
      x+3,y+12,10,searchIndex==i and theme.accent or theme.text,33,true)
  end
  txt(tr('select')..': A    '..tr('search')..': START',187,371,11,theme.muted,430)
  footer()
end
local function confirmPage()
  header(tr('confirm'),tr('choose_sd'))
  local g=selectedGame
  if not g then centerEmpty(tr('invalid'));footer();return end
  panel(180,113,440,95)
  cover(g,188,120,104,80,gameIndex)
  txt(ui.ellipsize(g.name,27),308,140,16,theme.text,295)
  txt(tostring(g.category or ''):upper(),308,177,11,theme.muted,290)
  for n=1,2 do
    local x=180+(n-1)*226
    panel(x,228,213,103,selectedCard==n)
    txt('SD'..n,x+18,240,26,selectedCard==n and theme.accent or theme.text)
    txt(n==1 and '/roms/' or '/roms2/',x+18,284,11,theme.muted)
  end
  R(180,350,440,47,theme.accent,9)
  txt(tr('confirm_download')..'  •  SD'..selectedCard,193,366,14,theme.bg,412,true)
  footer()
end
local function transfersPage(route)
  header(tr('downloads'),tr('title_downloads'))
  -- Download em andamento no topo; downloads concluídos listados abaixo.
  panel(180,89,440,130)
  txt(tr('current_download'),195,98,12,theme.accent,408)
  local active=external.activeDownload
  local isCurrent=active and (external.pending=='download' or
    (screen=='transferring' and external.phase~='done' and not external.error))
  local finished=active and external.phase=='done' and not external.busy()
  if isCurrent or finished then
    txt(ui.ellipsize(active.name or '?',46),196,122,13,theme.text,390)
    txt('SD'..tostring(active.card or 1)..'  ·  '..(
      finished and tr('done') or external.error and tr('download_failed') or tr('progress')),
      196,145,11,theme.muted,390)
    local p=0
    if finished then p=1
    elseif (external.expected or 0)>0 then
      p=math.max(0,math.min(1,(external.downloaded or 0)/external.expected)) end
    R(196,169,402,12,theme.border,6)
    if p>0 then R(196,169,402*p,12,theme.accent,6) end
    txt((((external.expected or 0)>0 or finished) and
      string.format('%d%%',math.floor(p*100+0.5))) or tr('download_progress'),
      196,189,10,theme.muted,398)
  else
    txt(tr('no_current_download'),196,143,12,theme.muted,399)
  end
  txt(tr('completed_downloads')..'  ('..tostring(#downloads)..')',181,232,13,theme.text,421)
  if #downloads==0 then
    panel(180,252,440,168)
    txt(tr('history_empty'),196,321,12,theme.muted,403,true)
  else
    local total=#downloads
    local maxScroll=math.max(0,total-4)
    downloadScroll=math.max(0,math.min(downloadScroll,maxScroll))
    for slot=1,math.min(4,total-downloadScroll) do
      local item=downloads[total-downloadScroll-slot+1]
      local y=252+(slot-1)*43
      panel(180,y,440,39)
      R(190,y+11,6,16,theme.green,3)
      txt(ui.ellipsize(item.name or '?',42),204,y+5,11,theme.text,298)
      txt((item.card or '?'):upper(),530,y+5,10,theme.accent,78)
      txt(os.date('%d/%m',tonumber(item.time) or os.time()),204,y+23,9,theme.muted,162)
      txt(tr('done'),519,y+23,9,theme.green,92)
    end
    if total>4 then
      txt('▲▼ '..tostring(downloadScroll+1)..'-'..tostring(math.min(total,downloadScroll+4))..'/'..total,
        477,425,9,theme.muted,134)
    end
  end
  footer()
end
local function historyPage()
  header(tr('downloads'),tr('history'))
  if #downloads==0 then centerEmpty(tr('history_empty'));footer();return end
  local first=math.max(1,historyIndex-4)
  for idx=first,math.min(#downloads,first+4) do
    local d=downloads[#downloads-idx+1]
    local y=124+(idx-first)*55
    panel(180,y,440,49,idx==historyIndex)
    txt(ui.ellipsize(d.name or '?',38),190,y+6,12,theme.text,330)
    txt((d.card or '?'):upper()..' · '..tostring(d.category or ''),190,y+28,10,theme.muted,340)
  end
  footer()
end
local function installedPage()
  header(tr('manage'),tr('title_installed'))
  local n=#downloads
  txt(tr('files')..': '..n,181,107,12,theme.accent)
  if n==0 then centerEmpty(tr('no_installed'));footer();return end
  local list={}
  for _,d in ipairs(downloads) do list[#list+1]={name=d.name,subtitle=(d.card or ''):upper()..' / '..(d.category or '')} end
  for i=math.max(1,installIndex-5),math.min(#list,math.max(1,installIndex-5)+5) do
    local d=list[i];local y=130+(i-math.max(1,installIndex-5))*46
    panel(180,y,440,42,i==installIndex)
    txt(ui.ellipsize(d.name,39),190,y+6,12,theme.text,415)
    txt(d.subtitle,190,y+23,10,theme.muted,415)
  end
  footer()
end
local function favoritesPage()
  header(tr('personalize'),tr('title_favorites'))
  if #favorites==0 then centerEmpty(tr('no_favorites'),tr('favorite_toggle'));footer();return end
  local first=math.floor((favIndex-1)/6)*6+1
  for i=first,math.min(#favorites,first+5) do
    local g=favorites[i]; local slot=i-first
    local x=180+(slot%3)*149;local y=130+math.floor(slot/3)*143
    card(g,x,y,140,133,i,favIndex==i,sdLocation(g))
  end
  footer()
end
local function settingsPage()
  header(tr('personalize'),tr('title_settings'))
  local values={tr('language'),tr('theme'),tr('font_size'),tr('storage'),tr('network'),tr('help')}
  local shown={i18n.languages[1].name,tr('theme_blue'),tr('font_'..settings.font_size),
    tr('free_space')..' / '..tr('total_space'),tr('status'),'A / B / X / Y'}
  for _,o in ipairs(i18n.languages) do if o.code==settings.language then shown[1]=o.name end end
  for _,o in ipairs(theme.options) do if o.key==settings.theme then shown[2]=tr(o.name) end end
  for i,label in ipairs(values) do
    local y=108+(i-1)*53
    panel(180,y,440,47,i==settingsIndex)
    txt(label,195,y+4,13,theme.text,310)
    txt(shown[i],195,y+25,10,theme.muted,385)
    txt('›',589,y+10,18,theme.accent)
  end
  footer()
end
local function fontSizePage()
  header(tr('personalize'),tr('font_size'))
  txt(tr('font_size_note'),183,104,11,theme.muted,428)
  for i,key in ipairs(fontSizes) do
    local y=146+(i-1)*78
    panel(180,y,440,68,fontSizeIndex==i)
    txt(tr('font_'..key),200,y+12,16,theme.text,309)
    txt('Aa 123',200,y+38,12,theme.muted,272)
    if settings.font_size==key then txt('✓',581,y+22,19,theme.accent) end
  end
  footer()
end
local function languagesPage()
  header(tr('personalize'),tr('languages'))
  txt(tr('language_note'),182,98,11,theme.muted,431)
  for i,lang in ipairs(i18n.languages) do
    local y=123+(i-1)*72
    local active=settings.language==lang.code
    panel(180,y,440,62,languageIndex==i)
    R(193,y+13,42,35,theme.panel2,7,active and theme.accent or theme.border)
    ui.flag(lang.code,198,y+20,32,21)
    txt(lang.name,247,y+20,15,theme.text,290)
    if active then txt('✓',583,y+20,16,theme.accent) end
  end
  footer()
end
local function themesPage()
  header(tr('personalize'),tr('themes'))
  txt(tr('theme_note'),182,96,11,theme.muted,436)
  for i,opt in ipairs(theme.options) do
    local x=180+((i-1)%3)*149;local y=126+math.floor((i-1)/3)*94
    local active=theme.current==opt.key
    panel(x,y,140,86,themeIndex==i)
    R(x+13,y+10,112,30,theme.hex(opt.hex),8)
    txt(ui.ellipsize(tr(opt.name),14),x+9,y+50,11,theme.text,122)
    if active then txt('✓',x+110,y+13,16,theme.bg) end
  end
  footer()
end
local function storagePage()
  header(tr('manage'),tr('storage'))
  for n=1,2 do
    local y=125+(n-1)*146
    panel(180,y,440,130)
    txt('SD'..n,199,y+16,23,theme.text)
    local entry=storageInfo[n]
    if entry then
      txt(tr('free_space')..': '..formatBytes(entry.free),298,y+17,15,theme.accent,292)
      txt(tr('total_space')..': '..formatBytes(entry.total),199,y+53,12,theme.muted,400)
      R(200,y+88,399,11,theme.border,5)
      local used=math.max(0,math.min(1,(entry.total-entry.free)/entry.total))
      if used>0 then R(200,y+88,399*used,11,theme.accent,5) end
    else
      txt(tr('not_mounted'),298,y+25,13,theme.muted,290)
    end
  end
  footer()
end
local function networkPage()
  header(tr('info'),tr('network'))
  panel(180,116,440,279)
  local state=external.networkState()
  local color=state=='online' and theme.green or state=='offline' and theme.error or theme.accent
  local label=state=='online' and tr('online') or state=='offline' and tr('offline') or
    state=='maintenance' and tr('maintenance') or tr('syncing')
  txt(tr('connection_status'),202,158,14,theme.muted,373)
  R(202,216,396,63,theme.panel2,10,theme.border)
  ui.color(color);love.graphics.circle('fill',233,248,11)
  ui.color(color,.18);love.graphics.circle('fill',233,248,17)
  txt(label,260,234,18,theme.text,300)
  R(202,320,396,45,theme.accent,8)
  ui.stroke(202,320,396,45,theme.text,8,1)
  txt(tr('refresh'),213,332,14,theme.bg,370,true)
  footer()
end
local function aboutPage()
  header(tr('info'),tr('title_about'))
  -- Referencia: cartao de autoria e mensagem do projeto da imagem enviada.
  -- Mantem visual proprio sem reproduzir logo/marca de terceiros.
  panel(180,92,440,109)
  R(188,100,423,4,theme.accent,2)
  ui.drawLogo(191,110,163,80)
  txt('v0.2.6  •  TESTE',359,169,10,theme.muted,105)
  R(473,119,136,60,theme.panel2,8,theme.border)
  txt(tr('about_author'),482,129,9,theme.muted,114,true)
  txt('JAMES PARK',481,148,14,theme.accent,116,true)

  panel(180,209,440,142)
  ui.kicker(tr('about_project'),195,217)
  txt(tr('about_line1'),196,241,12,theme.text,400)
  txt(tr('about_line2'),196,261,12,theme.text,400)
  R(195,288,408,1,theme.border,1)
  txt('640×480  •  LUA + LÖVE 11.5  •  SD1 / SD2',196,301,11,theme.accent,406)
  txt(tr('about_community'),196,326,10,theme.muted,407)

  panel(180,360,440,69)
  txt(tr('about_warning'),195,368,11,theme.accent,402)
  txt(tr('about_warning1'),195,387,10,theme.muted,408)
  txt(tr('about_warning2'),195,404,10,theme.muted,408)
  footer()
end
local function helpPage()
  header(tr('info'),tr('help'))
  panel(180,115,440,292)
  local pairs={
    {'A',tr('select')},{'B',tr('back')},{'L/R',tr('tabs')},
    {'X',tr('search')..' / '..tr('favorites')},{'Y',tr('sync')},
    {'START',tr('search')}
  }
  for i,pair in ipairs(pairs) do
    local x=201+((i-1)%2)*210;local y=140+math.floor((i-1)/2)*69
    R(x,y,57,31,theme.panel2,7,theme.border)
    txt(pair[1],x+8,y+8,12,theme.accent,42,true)
    txt(pair[2],x+66,y+8,11,theme.text,133)
  end
  footer()
end
local function offlinePage()
  header(tr('info'),tr('offline'))
  panel(180,120,440,269)
  txt('!',391,147,28,theme.error)
  txt(tr('network_error'),204,214,15,theme.text,391,true)
  txt(tr('loading_note'),204,253,12,theme.muted,391,true)
  R(201,327,397,39,theme.accent,8)
  txt(tr('try_again'),210,339,13,theme.bg,375,true)
  footer()
end
local function splashPage()
  -- Tela de entrada exclusiva, sem menu lateral, com a logo vetorial da loja.
  R(0,0,640,480,theme.bg)
  ui.color(theme.accent,.065);love.graphics.circle('fill',344,205,220)
  ui.color(theme.accent,.035);love.graphics.circle('fill',344,205,285)
  R(102,100,438,256,theme.panel,20,theme.border)
  R(102,100,438,5,theme.accent,3)
  ui.drawLogo(160,116,320,168)
  txt(tr('startup_note'),135,287,12,theme.muted,370,true)
  R(168,331,304,8,theme.border,4)
  local progress=math.max(0,math.min(1,startupTime/1.2))
  R(168,331,304*progress,8,theme.accent,4)
  txt(tr('loading'),135,352,10,theme.accent,370,true)
  txt('640 × 480  •  LÖVE 11.5',185,409,10,theme.low,270,true)
end
local function exitDialog()
  -- Modal de confirmação visível acima da Home.
  R(0,0,640,480,{0,0,0},0,nil,.78)
  panel(143,137,356,208,true)
  txt(tr('exit_question'),169,164,20,theme.text,306,true)
  txt(tr('exit_note'),170,210,12,theme.muted,301,true)
  R(166,276,142,43,theme.accent,8)
  txt('A  '..tr('confirm_yes_short'),169,290,12,theme.bg,136,true)
  R(334,276,142,43,theme.panel2,8,theme.border)
  txt('B  '..tr('cancel'),339,290,12,theme.text,132,true)
end
function love.load()
  love.graphics.setDefaultFilter('linear','linear')
  ui.init();loadData()
  external.init(HOME,STATE)
  reloadDownloads()
  device.update(0,true)
  screen='startup'
  if os.getenv('R36S_STORE_OFFLINE_TEST')~='1' then external.enter() end
end
function love.update(dt)
  clock=clock+dt
  device.update(dt)
  if screen=='storage' and clock-storageLast>30 then refreshStorage() end
  external.update(dt)
  if screen=='home' and not (focus=='content' and homeFocus=='featured') and #external.games>1 then
    homeSlideClock=homeSlideClock+dt
    if homeSlideClock>5 then
      homeSlideClock=0
      homeSlideIndex=homeSlideIndex%#external.games+1
    end
  end
  if screen=='startup' then
    startupTime=startupTime+dt
    if startupTime>1.2 then mainRoute('home') end
  end
  noticeTime=math.max(0,noticeTime-dt)
  if math.floor(clock*2)~=math.floor((clock-dt)*2) then
    reloadDownloads()
  end
  if external.phase=='done' and lastStatus~='done' and not external.busy() then
    if screen=='transferring' then screen='success' end
  end
  if external.error and screen=='transferring' then screen='downloads' end
  lastStatus=external.phase
end
function love.draw()
  if screen=='startup' then splashPage();ui.statusBar(device.get());return end
  sidebar()
  if screen=='home' or screen=='exit_confirm' then homePage()
  elseif screen=='catalog' then catalogPage()
  elseif screen=='search_results' then searchResultsPage()
  elseif screen=='search' then searchPage()
  elseif screen=='detail' then detailsPage()
  elseif screen=='confirm' then confirmPage()
  elseif screen=='downloads' or screen=='transferring' or screen=='success' then transfersPage(screen)
  elseif screen=='history' then historyPage()
  elseif screen=='installed' then installedPage()
  elseif screen=='favorites' then favoritesPage()
  elseif screen=='settings' then settingsPage()
  elseif screen=='languages' then languagesPage()
  elseif screen=='font_size' then fontSizePage()
  elseif screen=='themes' then themesPage()
  elseif screen=='storage' then storagePage()
  elseif screen=='network' then networkPage()
  elseif screen=='about' then aboutPage()
  elseif screen=='help' then helpPage()
  elseif screen=='offline' then offlinePage()
  else homePage() end
  if noticeTime>0 then
    R(180,401,440,30,theme.panel2,7,theme.accent)
    txt(ui.ellipsize(notice,60),190,409,11,theme.text,420)
  end
  ui.statusBar(device.get())
  if screen=='exit_confirm' then exitDialog() end
end
local function changeTheme()
  local o=theme.options[themeIndex];if not o then return end
  settings.theme=o.key;theme.set(o.key);saveSettings()
  notice=tr('theme')..': '..tr(o.name);noticeTime=2.0
end
local function changeFontSize()
  local size=fontSizes[fontSizeIndex]
  if size then
    settings.font_size=size
    ui.setFontSize(size)
    saveSettings()
    notice=tr('font_size')..': '..tr('font_'..size)
    noticeTime=2
  end
end
local function changeLanguage()
  local o=i18n.languages[languageIndex];if not o then return end
  settings.language=o.code;saveSettings();notice=tr('language')..': '..o.name;noticeTime=2.0
end
local function moveGrid(dx,dy)
  local n=#external.games
  if n==0 then return end
  local next=gameIndex+dx+dy*3
  if dx==-1 and ((gameIndex-1)%3)==0 then focus='sidebar';return end
  if dx==1 and (gameIndex%3)==0 then return end
  gameIndex=math.max(1,math.min(n,next))
end
local function refreshCatalog()
  if external.busy() then
    notice=tr('syncing');noticeTime=2
    return false
  end
  if external.refresh() then
    notice=tr('syncing');noticeTime=2
    return true
  end
  notice=tr('network_error');noticeTime=2.5
  return false
end
local function handleKey(key)
  if screen=='startup' then if key=='a' or key=='b' then mainRoute('home') end;return end
  if screen=='exit_confirm' then
    if key=='a' then love.event.quit()
    elseif key=='b' or key=='x' then back() end
    return
  end
  -- Não troca abas com L1/R1: o menu lateral centraliza a navegação.
  -- L1/R1 servem apenas à paginação quando o catálogo está em foco.
  if (screen=='catalog' or screen=='search_results') and (key=='l' or key=='r') then
    if screen=='search_results' then
      if external.searchPageChange(key=='r' and 1 or -1) then searchResultIndex=1 end
    elseif external.pageChange(key=='r' and 1 or -1) then gameIndex=1 end
    return
  end
  if screen=='catalog' then
    if key=='start' or key=='x' then navigate('search');searchIndex=1;return end
    if key=='y' then external.refresh();return end
    if focus=='sidebar' then
      if key=='up' then categoryIndex=math.max(1,categoryIndex-1)
      elseif key=='down' then categoryIndex=math.min(#external.categories,categoryIndex+1)
      elseif key=='right' then focus='grid'
      elseif key=='a' then chooseCategory()
      elseif key=='b' then mainRoute('home') end
      return
    end
    if key=='left' then focus='sidebar';return end
    if key=='right' then return end
    if key=='up' then gameIndex=math.max(1,gameIndex-1);return end
    if key=='down' then gameIndex=math.min(#external.games,gameIndex+1);return end
    if key=='a' then enterGame(selectedFromGames());return end
    if key=='b' then mainRoute('home');return end
    if key=='pageup' or key=='pagedown' then
      if external.pageChange(key=='pagedown' and 1 or -1) then gameIndex=1 end
      return
    end
  elseif screen=='search_results' then
    if key=='b' or key=='x' then back();return end
    if key=='up' then searchResultIndex=math.max(1,searchResultIndex-1)
    elseif key=='down' then searchResultIndex=math.min(#external.searchResults,searchResultIndex+1)
    elseif key=='a' then enterGame(selectedFromGames())
    elseif key=='pageup' or key=='pagedown' then
      if external.searchPageChange(key=='pagedown' and 1 or -1) then searchResultIndex=1 end
    end
    return
  elseif screen=='search' then
    if key=='b' then back();return end
    if key=='left' then searchIndex=math.max(1,searchIndex-1)
    elseif key=='right' then searchIndex=math.min(#keyboard,searchIndex+1)
    elseif key=='up' then searchIndex=math.max(1,searchIndex-10)
    elseif key=='down' then searchIndex=math.min(#keyboard,searchIndex+10)
    elseif key=='x' then query=query:sub(1,-2)
    elseif key=='y' then query=''
    elseif key=='start' then
      if #query>=2 and external.search(query,1) then
        searchResultIndex=1
        navigate('search_results')
      else
        notice=(#query<2 and tr('search_hint') or tr('network_error'))
        noticeTime=2.5
      end
    elseif key=='a' then
      local value=keyboard[searchIndex]
      if value=='SPACE' then query=query..' '
      elseif value=='DEL' then query=query:sub(1,-2)
      elseif value=='CLEAR' then query=''
      elseif value=='OK' then handleKey('start')
      else query=query..value end
    end
    return
  elseif screen=='detail' then
    if key=='a' then selectedCard=1;navigate('confirm')
    elseif key=='x' then toggleFavorite(selectedGame)
    elseif key=='b' then back() end
    return
  elseif screen=='confirm' then
    if key=='left' or key=='right' or key=='x' then selectedCard=3-selectedCard
    elseif key=='a' then
      if external.download(selectedGame,selectedCard) then navigate('transferring')
      else notice=tr('download_failed');noticeTime=3 end
    elseif key=='b' then back() end
    return
  elseif screen=='downloads' or screen=='transferring' or screen=='success' then
    if key=='up' then downloadScroll=math.max(0,downloadScroll-1)
    elseif key=='down' then downloadScroll=math.min(math.max(0,#downloads-4),downloadScroll+1)
    elseif key=='a' then navigate('history')
    elseif key=='b' then if screen=='downloads' then mainRoute('home') else mainRoute('downloads') end end
    return
  elseif screen=='history' then
    if key=='up' then historyIndex=math.max(1,historyIndex-1)
    elseif key=='down' then historyIndex=math.min(#downloads,historyIndex+1)
    elseif key=='b' then back() end
    return
  elseif screen=='installed' then
    if key=='up' then installIndex=math.max(1,installIndex-1)
    elseif key=='down' then installIndex=math.min(#downloads,installIndex+1)
    elseif key=='b' then mainRoute('home') end
    return
  elseif screen=='favorites' then
    if key=='left' then favIndex=math.max(1,favIndex-1)
    elseif key=='right' then favIndex=math.min(#favorites,favIndex+1)
    elseif key=='up' then favIndex=math.max(1,favIndex-3)
    elseif key=='down' then favIndex=math.min(#favorites,favIndex+3)
    elseif key=='a' then enterGame(favorites[favIndex])
    elseif key=='x' then toggleFavorite(favorites[favIndex]);favIndex=math.max(1,math.min(favIndex,#favorites))
    elseif key=='b' then mainRoute('home') end
    return
  elseif screen=='settings' then
    if key=='up' then settingsIndex=math.max(1,settingsIndex-1)
    elseif key=='down' then settingsIndex=math.min(#suboptions,settingsIndex+1)
    elseif key=='a' then navigate(suboptions[settingsIndex])
    elseif key=='b' then mainRoute('home') end
    return
  elseif screen=='languages' then
    if key=='up' then languageIndex=math.max(1,languageIndex-1)
    elseif key=='down' then languageIndex=math.min(#i18n.languages,languageIndex+1)
    elseif key=='a' then changeLanguage()
    elseif key=='b' then back() end
    return
  elseif screen=='font_size' then
    if key=='up' then fontSizeIndex=math.max(1,fontSizeIndex-1)
    elseif key=='down' then fontSizeIndex=math.min(3,fontSizeIndex+1)
    elseif key=='a' then changeFontSize()
    elseif key=='b' then back() end
    return
  elseif screen=='themes' then
    if key=='left' then themeIndex=math.max(1,themeIndex-1)
    elseif key=='right' then themeIndex=math.min(#theme.options,themeIndex+1)
    elseif key=='up' then themeIndex=math.max(1,themeIndex-3)
    elseif key=='down' then themeIndex=math.min(#theme.options,themeIndex+3)
    elseif key=='a' then changeTheme()
    elseif key=='b' then back() end
    return
  elseif screen=='storage' then
    if key=='b' then back() end
    return
  elseif screen=='network' or screen=='offline' then
    if key=='a' or key=='y' then refreshCatalog()
    elseif key=='b' then back() end
    return
  elseif screen=='about' or screen=='help' then
    -- A nunca abre Ajuda automaticamente ao visitar Sobre.
    if key=='b' then back() end
    return
  elseif screen=='home' then
    -- D-pad escolhe item e regiao; somente A entra no item em foco.
    if focus=='sidebar' then
      if key=='up' then menuIndex=math.max(1,menuIndex-1)
      elseif key=='down' then menuIndex=math.min(#menuPages,menuIndex+1)
      elseif key=='right' then focus='content';homeFocus='explore'
      elseif key=='a' then
        local route=menuPages[menuIndex]
        if route=='home' then focus='content';homeFocus='explore'
        elseif route=='exit' then navigate('exit_confirm')
        elseif route then mainRoute(route) end
      elseif key=='y' then external.refresh() end
    else
      if key=='b' then focus='sidebar'
      elseif key=='up' then
        if homeFocus=='featured' then homeFocus='explore'
        elseif homeFocus=='overview' then homeOverviewIndex=math.max(1,homeOverviewIndex-1) end
      elseif key=='down' then
        if homeFocus=='explore' then homeFocus='featured'
        elseif homeFocus=='overview' then homeOverviewIndex=math.min(3,homeOverviewIndex+1) end
      elseif key=='left' then
        if homeFocus=='featured' then homeFocus='overview'
        elseif homeFocus=='explore' then focus='sidebar'
        elseif homeFocus=='overview' then focus='sidebar' end
      elseif key=='right' then
        if homeFocus=='overview' then homeFocus='featured'
        elseif homeFocus=='explore' then homeFocus='featured'
        elseif homeFocus=='featured' and #external.games>1 then
          homeSlideIndex=homeSlideIndex%#external.games+1;homeSlideClock=0
        end
      elseif key=='a' then
        if homeFocus=='featured' then
          enterGame(external.games[homeSlideIndex])
        elseif homeFocus=='overview' then
          local targets={'catalog','installed','favorites'}
          mainRoute(targets[homeOverviewIndex])
        else
          mainRoute('catalog')
        end
      elseif key=='y' then external.refresh() end
    end
    return
  end
  if key=='b' then back() end
end
function love.keypressed(key,scancode,isrepeat)
  if isrepeat then return end
  -- Teclado para testes no PC. No console, SDL2 envia gamepadpressed.
  local keys={['return']='a',kpenter='a',escape='b',backspace='b',
    up='up',down='down',left='left',right='right',
    pageup='l',pagedown='r',f5='y',y='y',x='x',tab='start'}
  handleKey(keys[key] or key)
end
function love.gamepadpressed(_,button)
  -- Mapeamento SDL2 unico: direcional, face buttons, L1/R1 e START.
  local keys={a='a',b='b',x='x',y='y',dpup='up',dpdown='down',dpleft='left',dpright='right',
    leftshoulder='l',rightshoulder='r',start='start'}
  if keys[button] then handleKey(keys[button]) end
end
function love.textinput(t)
  if screen=='search' and #query<60 and not t:find('[\r\n]') then query=query..t end
end
function love.mousepressed(x,y,button)
  if button~=1 then return end
  if screen=='exit_confirm' then
    if y>=275 and y<=320 then
      if x>=166 and x<310 then handleKey('a')
      elseif x>=334 and x<480 then handleKey('b') end
    end
    return
  end
  if x<158 and y>=121 and y<424 then
    if screen=='catalog' then
      local total=#external.categories
      local scroll=math.max(1,math.min(categoryIndex-4,total-7))
      local idx=scroll+math.floor((y-121)/37)
      if idx<scroll+8 and external.categories[idx] then categoryIndex=idx;chooseCategory() end
    else
      local idx=math.floor((y-121)/38)+1
      if menuPages[idx] then
        menuIndex=idx
        if menuPages[idx]=='exit' then navigate('exit_confirm')
        else mainRoute(menuPages[idx]) end
      end
    end
  elseif screen=='catalog' or screen=='search_results' then
    local isSearch=screen=='search_results'
    local list=isSearch and external.searchResults or external.games
    local selected=isSearch and searchResultIndex or gameIndex
    if x>=180 and x<=417 and y>=128 and y<410 then
      local row=math.floor((y-128)/47)
      local idx=math.floor((selected-1)/6)*6+row+1
      if list[idx] then
        if isSearch then searchResultIndex=idx else gameIndex=idx end
        focus='grid'
      end
    elseif x>=428 and x<=620 and y>=128 and y<=417 then
      enterGame(list[selected])
    elseif y>=56 and y<=85 and x>=578 and x<=619 then
      if isSearch then back() else navigate('search');searchIndex=1 end
    end
  elseif screen=='settings' then
    local idx=math.floor((y-108)/53)+1
    if y>=108 and suboptions[idx] then settingsIndex=idx;navigate(suboptions[idx]) end
  elseif screen=='font_size' then
    local idx=math.floor((y-146)/78)+1
    if y>=146 and fontSizes[idx] then fontSizeIndex=idx;changeFontSize() end
  elseif screen=='themes' then
    local col=math.floor((x-180)/149)
    local row=math.floor((y-126)/94)
    local idx=row*3+col+1
    if theme.options[idx] then themeIndex=idx;changeTheme() end
  elseif screen=='languages' then
    local idx=math.floor((y-123)/72)+1
    if i18n.languages[idx] then languageIndex=idx;changeLanguage() end
  elseif screen=='network' then
    if x>=202 and x<=598 and y>=320 and y<=365 then refreshCatalog() end
  elseif screen=='offline' then
    if x>=201 and x<=598 and y>=327 and y<=366 then refreshCatalog() end
  elseif screen=='home' then
    if x>=465 and x<=608 and y>=160 and y<=184 then
      focus='content';homeFocus='explore';mainRoute('catalog')
    elseif x>=418 and x<=603 and y>=208 and y<=428 then
      focus='content';homeFocus='featured';enterGame(external.games[homeSlideIndex])
    elseif x>=180 and x<=370 and y>=237 and y<=422 then
      local index=math.floor((y-237)/64)+1
      if index>=1 and index<=3 then
        homeFocus='overview';homeOverviewIndex=index
        local targets={'catalog','installed','favorites'};mainRoute(targets[index])
      end
    end
  elseif screen=='detail' then if y>=280 then handleKey('a') end
  elseif screen=='confirm' then
    if y>228 and y<332 then selectedCard=x<406 and 1 or 2
    elseif y>350 then handleKey('a') end
  end
end
