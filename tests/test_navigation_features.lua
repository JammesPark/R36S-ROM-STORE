package.path='src/?.lua;'..package.path
local drawn={}; local quitted=0
local font={}; local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do gfx[k]=function(...) end end
function gfx.getScissor() return nil end
function gfx.newFont(...) return font end
function gfx.newImage(...) return {getDimensions=function() return 100,180 end} end
function gfx.print(s) drawn[#drawn+1]=tostring(s) end
function gfx.printf(s) drawn[#drawn+1]=tostring(s) end
love={graphics=gfx,filesystem={newFileData=function(v,n) return v end},event={quit=function() quitted=quitted+1 end}}
require('main');love.load();love.update(2)
local ext=require('external')
local function mockRoute(route)
  for i=1,70 do
    local name=debug.getupvalue(love.draw,i)
    if not name then break end
    if name=='screen' then debug.setupvalue(love.draw,i,route);return end
  end
  error('screen nao encontrado')
end
local function currentRoute()
  for i=1,70 do
    local name,value=debug.getupvalue(love.draw,i)
    if name=='screen' then return value end
  end
  return nil
end
local function render(route)
  drawn={};mockRoute(route);love.draw();return table.concat(drawn,' | ')
end
ext.categories={{category='ALL',count=999},{category='nes',count=17},{category='snes',count=23},{category='psx',count=7}}
assert(ext.totalCatalog()==47,'Soma deve ignorar ALL e total de pagina')
ext.games={{name='Super Mario All-Stars',category='snes',game_path='https://example.org/a.zip',cover_id=''}, {name='Sonic',category='genesis',game_path='https://example.org/b.zip',cover_id=''}}
local home=render('home')
assert(home:find('47',1,true),'Home nao apresenta total de categorias')
assert(not home:find('999',1,true),'Home mostrou ALL em vez da soma')
local catalog=render('catalog')
assert(catalog:find('X ',1,true),'Catalogo sem atalho de busca X')
mockRoute('catalog')
love.keypressed('x')
assert(currentRoute()=='search','X nao abriu busca')
local langs=render('languages')
assert(langs:find('English',1,true),'Idiomas ausentes')
mockRoute('home')
-- Seleção inicia em HOME; baixo repetido vai para SAIR, sem abrir telas.
for _=1,7 do love.gamepadpressed(nil,'dpdown') end
assert(currentRoute()=='home','D-pad saiu da Home sem confirmar')
love.gamepadpressed(nil,'a')
assert(currentRoute()=='exit_confirm','A nao abriu confirmacao de SAIR')
local confirmation=render('exit_confirm')
assert(confirmation:find('SAIR',1,true) or confirmation:find('EXIT',1,true),'Janela de saida nao desenhada')
love.gamepadpressed(nil,'b')
assert(currentRoute()=='home','B nao cancelou saida')
love.gamepadpressed(nil,'a')
love.gamepadpressed(nil,'a')
assert(quitted==1,'A nao chamou love.event.quit na confirmacao')
local network=render('network')
assert(not network:find('GAMESTORE',1,true) and not network:find('r36swiki',1,true),'Fonte aparece na tela de rede')
local about=render('about')
assert(not about:find('GAMESTORE',1,true) and not about:find('r36swiki',1,true),'Fonte aparece em Sobre')
assert(ext.networkState()=='syncing','Status inicial deve aguardar verificacao')
ext.connected=true;assert(ext.networkState()=='online','Status verde nao disponivel')
ext.connected=false;assert(ext.networkState()=='offline','Status vermelho nao disponivel')
ext.maintenance=true;assert(ext.networkState()=='maintenance','Status amarelo nao disponivel')
assert(render('storage'):find('SD1',1,true),'Sem SD1 em armazenamento')
assert(render('storage'):find('SD2',1,true),'Sem SD2 em armazenamento')
print('NAV/UI v0.2.3: home, total, X busca, status, SDs, saida confirmada OK')
