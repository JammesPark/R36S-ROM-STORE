package.path='src/?.lua;'..package.path
local rendered={};local loadedLogo=false
local font={getWidth=function(_,s) return #tostring(s)*7 end}
local gfx={}
for _,name in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[name]=function() end
end
function gfx.newImage(path)
  if path=='assets/logo.png' then loadedLogo=true end
  return {getDimensions=function() return 740,542 end}
end
function gfx.getScissor() return nil end
function gfx.newFont() return font end
function gfx.print(s) rendered[#rendered+1]=tostring(s) end
function gfx.printf(s) rendered[#rendered+1]=tostring(s) end
love={graphics=gfx,filesystem={newFileData=function(v) return v end},event={quit=function() end}}
require('main');love.load();love.update(2)
assert(loadedLogo,'Logo oficial transparente nao foi carregada da pasta assets/')
local ext=require('external')
ext.categories={{category='ALL',count=50},{category='snes',count=20},{category='psx',count=30}}
ext.games={
 {name='ROM Um',category='snes',game_path='https://example.org/a.zip'},
 {name='ROM Dois',category='snes',game_path='https://example.org/b.zip'},
 {name='ROM Tres',category='psx',game_path='https://example.org/c.zip'}}
local function get(name)
  for i=1,110 do
    local n,v=debug.getupvalue(love.draw,i)
    if n==name then return v end
  end
  error('Variavel local ausente: '..name)
end
local function route(value)
  for i=1,110 do
    local n=debug.getupvalue(love.draw,i)
    if n=='screen' then debug.setupvalue(love.draw,i,value);return end
  end
  error('screen not found')
end
route('catalog');love.gamepadpressed(nil,'dpright');rendered={};love.draw()
local cat=table.concat(rendered,'|')
assert(cat:find('ROM Um',1,true) and cat:find('ROM Dois',1,true),'Catalogo nao exibe lista de ROMs')
love.gamepadpressed(nil,'dpdown')
rendered={};love.draw()
local selected=table.concat(rendered,'|')
local _,count=selected:gsub('ROM Dois','')
assert(count==1,'Preview nao deve repetir o nome da ROM selecionada')
-- A confirma a ROM em destaque mesmo com o preview composto apenas pela capa.
love.gamepadpressed(nil,'a')
assert(get('screen')=='detail','D-pad nao selecionou a ROM para abrir detalhes')
rendered={};love.draw()
assert(table.concat(rendered,'|'):find('ROM Dois',1,true),'A ROM selecionada nao corresponde a linha em foco')
local ui=require('ui')
for _,code in ipairs({'nes','snes','psx','gba','n64','dreamcast','mame','3do','ports'}) do
  ui.platformIcon(code,10,10,{1,1,1})
end
-- A busca deve chamar a API remota, independentemente de jogos carregados.
local calledQuery=nil;local calledPage=nil
local oldSearch=ext.search
ext.search=function(term,page) calledQuery=term;calledPage=page;return true end
route('search');love.textinput('METROID');love.keypressed('tab')
assert(calledQuery=='METROID' and calledPage==1,'START nao acionou pesquisa remota do catalogo')
assert(get('screen')=='search_results','A busca nao mostra a tela de resultados remotos')
ext.searchResults={{name='Metroid Remoto',category='gba',game_path='https://example.org/metroid.zip'}}
ext.searchQuery='METROID';ext.searchTotal=1;ext.searchPage=1;ext.searchTotalPages=1
rendered={};love.draw()
assert(table.concat(rendered,'|'):find('Metroid Remoto',1,true),'Resultado remoto nao foi mostrado')
love.gamepadpressed(nil,'a')
assert(get('screen')=='detail','A nao abre detalhes da ROM selecionada na busca')
ext.search=oldSearch
print('v0.2.6: logo, catalogo em lista, navegacao e busca remota OK')
