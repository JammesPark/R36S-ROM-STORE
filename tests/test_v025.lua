package.path='src/?.lua;'..package.path
local drawn={}
local font={getWidth=function(_,s) return #tostring(s)*7 end}
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[k]=function(...) end
end
function gfx.getScissor() return nil end
function gfx.newFont(...) return font end
function gfx.newImage() return {getDimensions=function() return 100,180 end} end
function gfx.printf(s) drawn[#drawn+1]=tostring(s) end
function gfx.print(s) drawn[#drawn+1]=tostring(s) end
love={graphics=gfx,filesystem={newFileData=function(v) return v end},event={quit=function() end}}
require('main')
love.load();love.update(2)
local ext=require('external')
local ui=require('ui')
ext.categories={{category='ALL',count=90},{category='snes',count=10},{category='gbc',count=30}}
ext.games={
  {name='Game One',game_path='https://example.org/1.zip',category='snes'},
  {name='Game Two',game_path='https://example.org/2.zip',category='gbc'},
  {name='Game Three',game_path='https://example.org/3.zip',category='gbc'}
}
local function route(newRoute)
  for i=1,100 do
    local name=debug.getupvalue(love.draw,i)
    if not name then break end
    if name=='screen' then debug.setupvalue(love.draw,i,newRoute);return end
  end
  error('screen nao encontrado')
end
local function screen()
  for i=1,100 do
    local name,v=debug.getupvalue(love.draw,i)
    if name=='screen' then return v end
  end
end
local function render(newRoute)
  drawn={};route(newRoute);love.draw();return table.concat(drawn,' | ')
end
local cat=render('catalog')
assert(cat:find('SNES',1,true),'Sigla de plataforma deve ficar em maiusculo')
assert(not cat:find('MENU PRINCIPAL',1,true),'Botao de retorno ainda aparece no catalogo')
assert(cat:find('X',1,true) and cat:find('Buscar',1,true),'Rodape nao mostra X Buscar')
route('catalog');love.mousepressed(604,70,1)
assert(screen()=='search','Clique na lupa nao abre pesquisa')
local author=render('about')
assert(author:find('@r36sportsbr',1,true),'Tela Sobre sem canal da comunidade')
assert(author:find('SOBRE O PROJETO',1,true),'Sobre sem secao de descricao')
route('about');love.gamepadpressed(nil,'a')
assert(screen()=='about','A abriu ajuda ao selecionar Sobre')
-- A agora abre o QR do canal; B fecha antes de testar a Rede.
love.gamepadpressed(nil,'b')
local callCount=0
local oldRefresh=ext.refresh
local oldBusy=ext.busy
ext.busy=function() return false end
ext.refresh=function() callCount=callCount+1;return true end
route('network');love.mousepressed(333,342,1)
assert(callCount==1,'Clique em Atualizar catalogo nao executa refresh')
love.gamepadpressed(nil,'a')
assert(callCount==2,'Botao A em Rede nao executa refresh')
ext.refresh=oldRefresh;ext.busy=oldBusy
-- O teste usa uma Home limpa, sem pilha de navegacao artificial.
route('home')
love.gamepadpressed(nil,'dpleft')
love.gamepadpressed(nil,'dpright')
assert(screen()=='home','Direita deveria apenas mudar o foco da Home')
love.gamepadpressed(nil,'dpdown')
assert(screen()=='home','Baixo no painel direito abriu outra tela')
love.gamepadpressed(nil,'a')
assert(screen()=='detail','A no slide destacado nao abriu detalhes da ROM')
local home=render('home')
assert(home:find('Game One',1,true),'Slide nao mostra o nome da ROM')
assert(not home:find('Game Two',1,true),'Slide deve exibir somente uma ROM por vez')
ui.menuIcon('exit',10,10,{1,1,1})
ui.platformIcon('snes',10,10,{1,1,1})
ui.searchIcon(10,10,{1,1,1})
ui.statusBar({wifi=true,time='14:30',battery=68})
print('v0.2.5: sidebar, lupa, A sobre, rede clicavel, slide e home OK')
