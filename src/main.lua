-- R36S ROMS STORE | Tema de 19 telas (conceito HTML 640x480) aplicado em Lua/LÖVE.
-- Catálogo real: GameStoreBR; nenhum jogo demonstrativo é distribuído.
local json=require('json')
local external=require('external')
local ui=require('ui')
local theme=require('theme')
local i18n=require('i18n')
local HOME=os.getenv('R36S_STORE_HOME') or '/roms/ports/r36s-store-kpm'
local STATE=HOME..'/state'
local mainPages={'home','catalog','downloads','installed','favorites','settings','about'}
local screen='startup'
local stack={}
local settings={language='pt',theme='ocean',card=1}
local favorites={}
local downloads={}
local manifests={}
local focus='grid'; local menuIndex=1;local categoryIndex=1;local gameIndex=1
local favIndex=1;local installIndex=1;local historyIndex=1;local settingsIndex=1
local languageIndex=1;local themeIndex=1;local searchIndex=1;local query=''
local selectedGame=nil
local lastStatus='';local lastManifest='';local coverImages={};local coverSeen={}
local clock=0;local startupTime=0;local notice='';local noticeTime=0
local selectedCard=1;local transferHandled=false
local suboptions={'languages','themes','storage','network','help'}
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
  write(STATE..'/roms_settings.json',string.format('{"language":%s,"theme":%s,"card":%d}',
    encodeString(settings.language),encodeString(settings.theme),settings.card))
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
    if c.card==1 or c.card==2 then settings.card=c.card end
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
end
local function reloadDownloads()
  local s=read(STATE..'/roms_downloads.json')
  if not s or s==lastManifest then return end
  local list=json.decode(s)
  if type(list)=='table' then downloads=list;lastManifest=s end
end
local function reloadInstalled()
  local proc=io.popen('find "'..STATE..'/installations" -maxdepth 1 -name "*.json" -type f 2>/dev/null')
  if not proc then return end
  local list={}
  for path in proc:lines() do
    local p=json.decode(read(path) or '')
    if type(p)=='table' and type(p.name)=='string' and
      (p.root=='/roms/ports' or p.root=='/roms2/ports') and
      type(p.id)=='string' then list[#list+1]=p end
  end
  proc:close();manifests=list
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
  if screen=='search' and query~='' then
    local out={}
    local needle=query:lower()
    for _,g in ipairs(external.games) do
      if tostring(g.name or ''):lower():find(needle,1,true) then out[#out+1]=g end
    end
    return out
  end
  return external.games
end
local function navigate(route)
  if screen~=route then stack[#stack+1]=screen end
  screen=route
end
local function mainRoute(route)
  screen=route;stack={};focus='grid'
  for i,k in ipairs(mainPages) do if k==route then menuIndex=i end end
  if route=='catalog' then external.enter() end
end
local function back()
  if #stack>0 then screen=table.remove(stack)
  elseif screen~='home' then mainRoute('home') end
end
local function selectedFromGames()
  local list=currentGames()
  return list[gameIndex]
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
local function mainNext(dx)
  local i=1;for k,v in ipairs(mainPages) do if v==screen then i=k end end
  i=(i-1+dx+#mainPages)%#mainPages+1
  mainRoute(mainPages[i])
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
  if img then ui.imageCrop(img,x,y,w,h) end
end
local function sideItem(name,y,active,index,count)
  if active then
    R(13,y,134,34,theme.panel2,8,theme.accent)
    R(13,y+7,3,20,theme.accent,1)
  end
  -- Marcador geométrico simples no lugar de ícones externos.
  R(27,y+12,12,12,active and theme.accent or theme.muted,3)
  R(30,y+15,6,6,theme.sidebar,2)
  txt(ui.ellipsize(name,17),47,y+9,11,active and theme.text or theme.muted,83)
  if count then txt(tostring(count),131,y+10,9,theme.accent,13) end
end
local function sidebar()
  local isCatalog=screen=='catalog'
  local isCategory=isCatalog
  ui.layout(isCatalog,focus)
  if isCategory then
    txt(tr('platforms'),27,89,10,theme.low)
    local top=121
    local total=#external.categories
    local scroll=math.max(1,math.min(categoryIndex-4,total-7))
    for idx=scroll,math.min(total,scroll+7) do
      local cat=external.categories[idx]
      local name=cat.category=='ALL' and tr('all') or (cat.category=='ports' and 'Homebrew' or cat.category)
      sideItem(name,top+(idx-scroll)*37,cat.category==external.category,idx,cat.count)
      if focus=='sidebar' and idx==categoryIndex then ui.stroke(16,top+(idx-scroll)*37+2,128,30,theme.accent,7,2) end
    end
    R(13,406,134,24,theme.panel2,7,theme.border)
    txt('◁ '..tr('main_menu'),24,411,10,theme.accent,114)
  else
    txt(tr('navigation'),27,89,10,theme.low)
    for i,route in ipairs(mainPages) do
      sideItem(tr(route),121+(i-1)*39,menuIndex==i and screen==route)
    end
    if screen~='home' and screen~='startup' then
      local index=1;for i,v in ipairs(mainPages) do if v==screen then index=i end end
      if index~=menuIndex then sideItem(tr(mainPages[menuIndex]),121+(menuIndex-1)*39,true) end
    end
  end
  txt('●',20,449,11,theme.green)
  txt('GAMESTORE BR',30,452,10,theme.muted)
  txt('640×480',106,452,9,theme.low)
end
local function header(eyebrow,title,right)
  ui.kicker(eyebrow,179,23)
  txt(title,179,42,24,theme.text,440)
  if right then ui.pill(right,548,15,78,false) end
end
local function footer(phrase)
  ui.footer(tr('select'),tr('back'),phrase or tr('tabs'))
  txt('v0.2.0',579,452,10,theme.accent)
end
local function card(game,x,y,w,h,idx,active,badge)
  panel(x,y,w,h,active)
  cover(game,x+2,y+2,w-4,86,idx)
  txt(ui.ellipsize(game.name or '?',17),x+8,y+92,11,theme.text,w-16)
  local category=tostring(game.category or ''):upper()
  txt(ui.ellipsize(category,20),x+8,y+110,9,theme.low,w-16)
  if badge then
    R(x+6,y+67,w-12,17,theme.sidebar,4,nil,.91)
    txt(badge,x+10,y+70,10,theme.accent,w-20)
  end
  if active then ui.stroke(x,y,w,h,theme.accent,9,2) end
end
local function centerEmpty(text,sub)
  panel(180,135,439,243)
  txt(text,201,213,15,theme.text,400,true)
  if sub then txt(sub,201,246,12,theme.muted,400,true) end
end
local function homePage()
  header(tr('welcome'),tr('title_home'),'R36S 640×480')
  panel(179,111,441,131,true)
  ui.kicker('R36S ROMS STORE',200,126)
  txt(tr('subtitle'),200,150,20,theme.text,390)
  txt(tr('intro'),200,181,11,theme.muted,390)
  R(468,205,133,26,theme.accent,7)
  txt(tr('explore'),476,213,10,theme.bg,126)
  txt(tr('overview'),180,253,13,theme.text)
  local stats={
    {tr('catalog_games'),tostring(external.total>0 and external.total or #external.games)},
    {tr('installed_games'),tostring(#downloads)},
    {tr('active_card'),'SD'..settings.card}}
  for i,v in ipairs(stats) do
    local x=180+(i-1)*149
    panel(x,274,140,70)
    txt(v[1],x+10,286,10,theme.muted,126)
    txt(v[2],x+10,306,19,theme.accent)
  end
  txt(tr('featured'),180,351,13,theme.text)
  txt(tr('see_all')..' ›',553,352,10,theme.accent)
  if #external.games==0 then
    panel(180,376,439,52)
    txt(tr('loading'),197,390,12,theme.muted,390)
  else
    for i=1,math.min(3,#external.games) do
      local g=external.games[i]
      local x=180+(i-1)*149
      panel(x,374,140,53)
      cover(g,x+1,375,138,33,i)
      R(x+1,405,138,21,theme.panel,0,nil,.96)
      txt(ui.ellipsize(g.name,16),x+6,408,10,theme.text,128)
    end
  end
  footer()
end
local function catalogPage()
  header(tr('library'),tr('title_catalog'))
  -- Busca dedicada: botão acima do grid.
  R(581,57,38,28,theme.panel,8,theme.border)
  txt('?',594,62,15,theme.accent)
  local active=external.category
  local catText=active=='ALL' and tr('all') or active:upper()
  txt(ui.ellipsize(catText,18),180,102,13,theme.muted,223)
  txt('• '..(external.total>0 and external.total or #external.games)..' '..tr('games'),360,103,11,theme.accent)
  local g=external.games
  if #g==0 then
    centerEmpty(external.error and tr('network_error') or tr('loading'),tr('press_sync'))
    footer(tr('page'));return
  end
  local first=math.floor((gameIndex-1)/6)*6+1
  local last=math.min(#g,first+5)
  for i=first,last do
    local slot=i-first;local col=slot%3;local row=math.floor(slot/3)
    local x=180+col*149;local y=132+row*143
    card(g[i],x,y,140,133,i,focus=='grid' and gameIndex==i)
  end
  txt(tr('page')..' '..external.page..'/'..external.totalPages,508,420,11,theme.muted,108)
  footer(tr('page'))
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
  local isDone=external.phase=='done' and not external.busy()
  header(tr('downloads'),route=='success' and tr('success') or tr('title_downloads'))
  panel(180,110,440,287)
  local phase=external.phase or 'idle'
  local caption=tr('download_ready')
  if external.busy() or route=='transferring' then caption=external.message or tr('download_progress')
  elseif external.error then caption=external.message or tr('download_failed')
  elseif isDone then caption=external.message or tr('download_completed') end
  txt(external.error and tr('download_failed') or (isDone and tr('done') or tr('progress')),200,134,20,external.error and theme.error or theme.accent,405)
  txt(ui.ellipsize(caption,83),200,184,13,theme.muted,405)
  R(200,245,400,13,theme.border,7)
  local progress=0
  if (external.expected or 0)>0 then progress=math.min(1,(external.downloaded or 0)/external.expected)
  elseif isDone then progress=1 end
  if progress>0 then R(200,245,400*progress,13,theme.accent,7) end
  txt((external.expected or 0)>0 and (math.floor(progress*100)..'%') or tr('status')..': '..phase,200,273,13,theme.accent)
  txt(tr('history')..': '..#downloads,200,329,12,theme.muted)
  txt(tr('see_all')..'  ›',520,362,12,theme.accent)
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
  if n==0 and #manifests==0 then centerEmpty(tr('no_installed'));footer();return end
  local list={}
  for _,d in ipairs(downloads) do list[#list+1]={name=d.name,subtitle=(d.card or ''):upper()..' / '..(d.category or '')} end
  for _,p in ipairs(manifests) do list[#list+1]={name=p.name,subtitle=(p.root=='/roms2/ports' and 'SD2' or 'SD1')..' / PORT'} end
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
  local values={tr('language'),tr('theme'),tr('storage'),tr('network'),tr('help')}
  local shown={i18n.languages[1].name, tr('theme_blue'),'SD1 / SD2','GameStoreBR', 'A / B / L / R'}
  for _,o in ipairs(i18n.languages) do if o.code==settings.language then shown[1]=o.name end end
  for _,o in ipairs(theme.options) do if o.key==settings.theme then shown[2]=tr(o.name) end end
  for i,label in ipairs(values) do
    local y=119+(i-1)*59
    panel(180,y,440,53,i==settingsIndex)
    txt(label,195,y+8,14,theme.text,310)
    txt(shown[i],195,y+29,10,theme.muted,385)
    txt('›',589,y+12,18,theme.accent)
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
    txt(({pt='BR',en='EN',es='ES',ru='RU'})[lang.code],202,y+22,13,theme.accent)
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
  txt(tr('card_info'),180,104,12,theme.muted,438)
  for i=1,2 do
    local y=149+(i-1)*116
    panel(180,y,440,100,settings.card==i)
    txt('SD'..i,200,y+13,23,settings.card==i and theme.accent or theme.text)
    txt(i==1 and '/roms/' or '/roms2/',200,y+48,13,theme.muted)
    if settings.card==i then txt('● '..tr('primary'),489,y+22,11,theme.accent,113) end
  end
  footer()
end
local function networkPage()
  header(tr('info'),tr('network'))
  panel(180,116,440,279)
  txt('GAMESTORE BR',201,146,20,theme.text)
  txt('r36swiki.com/getgames.php',201,183,12,theme.accent)
  txt(tr('network_note'),201,223,12,theme.muted,392)
  txt(external.error and tr('offline') or external.busy() and tr('loading') or tr('status')..': '..external.phase,201,268,12,external.error and theme.error or theme.green,396)
  R(202,325,397,40,theme.accent,8)
  txt(tr('refresh'),213,336,14,theme.bg,373,true)
  footer()
end
local function aboutPage()
  header(tr('info'),tr('title_about'))
  panel(180,118,440,276)
  ui.kicker('R36S ROMS STORE',200,144)
  txt('R36S ROMS',201,184,25,theme.text)
  txt('S T O R E',201,222,20,theme.accent)
  txt(tr('about_note'),201,277,12,theme.muted,389)
  txt(tr('about_source'),201,309,12,theme.muted,390)
  txt(tr('about_runtime'),201,342,11,theme.low,390)
  footer()
end
local function helpPage()
  header(tr('info'),tr('help'))
  panel(180,115,440,292)
  local pairs={
    {'A',tr('select')},{'B',tr('back')},{'L/R',tr('tabs')},
    {'X',tr('favorites')..' / SD'},{'Y',tr('sync')},
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
  ui.layout()
  txt('R36S ROMS',221,184,30,theme.text,390)
  txt('S T O R E',267,228,22,theme.accent)
  txt(tr('startup_note'),188,286,12,theme.muted,438,true)
  txt('Lua + LÖVE 11.5 · 640×480',220,335,11,theme.low,360,true)
end
function love.load()
  love.graphics.setDefaultFilter('linear','linear')
  ui.init();loadData()
  external.init(HOME,STATE)
  reloadDownloads();reloadInstalled()
  screen='startup'
  if os.getenv('R36S_STORE_OFFLINE_TEST')~='1' then external.enter() end
end
function love.update(dt)
  clock=clock+dt
  external.update(dt)
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
  if screen=='startup' then splashPage();return end
  sidebar()
  if screen=='home' then homePage()
  elseif screen=='catalog' then catalogPage()
  elseif screen=='search' then searchPage()
  elseif screen=='detail' then detailsPage()
  elseif screen=='confirm' then confirmPage()
  elseif screen=='downloads' or screen=='transferring' or screen=='success' then transfersPage(screen)
  elseif screen=='history' then historyPage()
  elseif screen=='installed' then installedPage()
  elseif screen=='favorites' then favoritesPage()
  elseif screen=='settings' then settingsPage()
  elseif screen=='languages' then languagesPage()
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
end
local function changeTheme()
  local o=theme.options[themeIndex];if not o then return end
  settings.theme=o.key;theme.set(o.key);saveSettings()
  notice=tr('theme')..': '..tr(o.name);noticeTime=2.0
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
local function handleKey(key)
  if screen=='startup' then if key=='a' or key=='b' then mainRoute('home') end;return end
  if key=='l' then mainNext(-1);return end
  if key=='r' then mainNext(1);return end
  if screen=='catalog' then
    if key=='start' then navigate('search');searchIndex=1;return end
    if key=='y' then external.refresh();return end
    if focus=='sidebar' then
      if key=='up' then categoryIndex=math.max(1,categoryIndex-1)
      elseif key=='down' then categoryIndex=math.min(#external.categories,categoryIndex+1)
      elseif key=='right' then focus='grid'
      elseif key=='a' then chooseCategory()
      elseif key=='b' then mainRoute('home') end
      return
    end
    if key=='left' then moveGrid(-1,0);return end
    if key=='right' then moveGrid(1,0);return end
    if key=='up' then moveGrid(0,-1);return end
    if key=='down' then moveGrid(0,1);return end
    if key=='x' then toggleFavorite(selectedFromGames());return end
    if key=='a' then enterGame(selectedFromGames());return end
    if key=='b' then mainRoute('home');return end
    if key=='pageup' or key=='pagedown' then
      if external.pageChange(key=='pagedown' and 1 or -1) then gameIndex=1 end
      return
    end
  elseif screen=='search' then
    if key=='b' then back();return end
    if key=='left' then searchIndex=math.max(1,searchIndex-1)
    elseif key=='right' then searchIndex=math.min(#keyboard,searchIndex+1)
    elseif key=='up' then searchIndex=math.max(1,searchIndex-10)
    elseif key=='down' then searchIndex=math.min(#keyboard,searchIndex+10)
    elseif key=='x' then query=query:sub(1,-2)
    elseif key=='y' then query=''
    elseif key=='start' then
      if query~='' then
        local current={}
        for _,g in ipairs(external.games) do
          if (g.name or ''):lower():find(query:lower(),1,true) then current[#current+1]=g end
        end
        if #current>0 then enterGame(current[1])
        else notice=tr('no_results');noticeTime=2 end
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
    if key=='a' then selectedCard=settings.card;navigate('confirm')
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
    if key=='a' then navigate('history')
    elseif key=='b' then if screen=='downloads' then mainRoute('home') else mainRoute('downloads') end end
    return
  elseif screen=='history' then
    if key=='up' then historyIndex=math.max(1,historyIndex-1)
    elseif key=='down' then historyIndex=math.min(#downloads,historyIndex+1)
    elseif key=='b' then back() end
    return
  elseif screen=='installed' then
    if key=='up' then installIndex=math.max(1,installIndex-1)
    elseif key=='down' then installIndex=math.min(#downloads+#manifests,installIndex+1)
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
  elseif screen=='themes' then
    if key=='left' then themeIndex=math.max(1,themeIndex-1)
    elseif key=='right' then themeIndex=math.min(#theme.options,themeIndex+1)
    elseif key=='up' then themeIndex=math.max(1,themeIndex-3)
    elseif key=='down' then themeIndex=math.min(#theme.options,themeIndex+3)
    elseif key=='a' then changeTheme()
    elseif key=='b' then back() end
    return
  elseif screen=='storage' then
    if key=='left' or key=='right' or key=='x' or key=='a' then
      settings.card=3-settings.card;saveSettings()
    elseif key=='b' then back() end
    return
  elseif screen=='network' or screen=='offline' then
    if key=='a' or key=='y' then external.refresh()
    elseif key=='b' then back() end
    return
  elseif screen=='about' or screen=='help' then
    if key=='a' and screen=='about' then navigate('help')
    elseif key=='b' then back() end
    return
  elseif screen=='home' then
    if key=='a' or key=='right' then mainRoute('catalog')
    elseif key=='down' then mainRoute('catalog')
    elseif key=='y' then external.refresh() end
    return
  end
  if key=='b' then back() end
end
function love.keypressed(key)
  local keys={['return']='a',kpenter='a',escape='b',backspace='b',z='a',
    up='up',down='down',left='left',right='right',
    q='l',e='r',pageup='pageup',pagedown='pagedown',
    f5='y',y='y',x='x',tab='start',space='a'}
  handleKey(keys[key] or key)
end
function love.gamepadpressed(_,button)
  local keys={a='a',b='b',x='x',y='y',dpup='up',dpdown='down',dpleft='left',dpright='right',
    leftshoulder='l',rightshoulder='r',start='start',lefttrigger='pageup',righttrigger='pagedown'}
  if keys[button] then handleKey(keys[button]) end
end
function love.textinput(t)
  if screen=='search' and #query<60 and not t:find('[\r\n]') then query=query..t end
end
function love.mousepressed(x,y,button)
  if button~=1 then return end
  if x<158 and y>=121 then
    if screen=='catalog' then
      local idx=math.floor((y-121)/37)+1
      if external.categories[idx] then categoryIndex=idx;chooseCategory() end
    else
      local idx=math.floor((y-121)/39)+1
      if mainPages[idx] then mainRoute(mainPages[idx]) end
    end
  elseif screen=='catalog' then
    if y>=132 and y<411 then
      local col=math.floor((x-180)/149)
      local row=math.floor((y-132)/143)
      local first=math.floor((gameIndex-1)/6)*6+1
      local idx=first+row*3+col
      if col>=0 and col<3 and row>=0 and row<2 and external.games[idx] then
        gameIndex=idx;focus='grid';enterGame(external.games[idx]) end
    elseif y<90 and x>=575 then navigate('search') end
  elseif screen=='settings' then
    local idx=math.floor((y-119)/59)+1
    if suboptions[idx] then settingsIndex=idx;navigate(suboptions[idx]) end
  elseif screen=='themes' then
    local col=math.floor((x-180)/149)
    local row=math.floor((y-126)/94)
    local idx=row*3+col+1
    if theme.options[idx] then themeIndex=idx;changeTheme() end
  elseif screen=='languages' then
    local idx=math.floor((y-123)/72)+1
    if i18n.languages[idx] then languageIndex=idx;changeLanguage() end
  elseif screen=='home' then mainRoute('catalog')
  elseif screen=='detail' then if y>=280 then handleKey('a') end
  elseif screen=='confirm' then
    if y>228 and y<332 then selectedCard=x<406 and 1 or 2
    elseif y>350 then handleKey('a') end
  end
end
