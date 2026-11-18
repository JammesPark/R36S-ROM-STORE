-- Funcionalidades da v0.4.0-beta: favoritos Y, confirmação de saída,
-- popup de atualização e BIOS independente (sem acesso real ao SD).
package.path='src/?.lua;'..package.path
local output={}
local fg={}
function fg:getWidth(s) return #tostring(s)*6 end
function fg:getHeight()return 13 end
function fg:getWrap(s,w)return w,{tostring(s)}end
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','line','circle','polygon',
                     'setLineWidth','setFont','setScissor','draw'}) do gfx[k]=function()end end
function gfx.getScissor()return nil end
function gfx.newFont()return fg end
function gfx.newImage()return {getDimensions=function()return 120,160 end}end
function gfx.print(s) output[#output+1]=tostring(s)end
function gfx.printf(s) output[#output+1]=tostring(s)end
local quit=false
love={graphics=gfx,filesystem={newFileData=function(x)return x end,read=function()return '0.4.0-beta\n'end},
  event={quit=function()quit=true end}}
require('main');love.load()
local ext=require('external')
local bios=require('bios_manager')
local upd=require('store_update')
local function getup(name)
 local work={love.draw,love.update,love.gamepadpressed,love.mousepressed}
 local seen={}
 for count=1,1200 do
  local fn=table.remove(work,1)
  if not fn then break end
  if not seen[fn] then
   seen[fn]=true
   for i=1,180 do
    local k,v=debug.getupvalue(fn,i)
    if not k then break end
    if k==name then return fn,i,v end
    if type(v)=='function' then work[#work+1]=v end
   end
  end
 end
 error('Não encontrei estado: '..name)
end
local function set(name,value)
 local fn,i=getup(name);debug.setupvalue(fn,i,value)
end
local function get(name)
 local _,_,v=getup(name);return v
end
local function press(key)love.gamepadpressed(nil,key)end
local function has(x)
 for _,v in ipairs(output) do if v:find(x,1,true) then return true end end
 return false
end
local function draw()output={};love.draw()end
-- Y alterna o favorito da ROM selecionada; não força refresh do catálogo.
ext.games={{name='Minha ROM',category='psx',game_path='psx/minha_rom.zip',cover_id='fake'}}
ext.categories={{category='ALL',count=1},{category='psx',count=1}}
local refreshes=0
local originalRefresh=ext.refresh
ext.refresh=function()refreshes=refreshes+1;return true end
set('favorites',{})
set('screen','catalog');set('gameIndex',1);set('focus','grid')
press('y')
assert(#get('favorites')==1,'Y deve adicionar ROM aos favoritos')
assert(refreshes==0,'Y não pode atualizar o catálogo')
press('y')
assert(#get('favorites')==0,'Y deve remover ROM dos favoritos')
set('screen','search_results');set('searchResultIndex',1)
ext.searchResults=ext.games
press('y')
assert(#get('favorites')==1,'Y na pesquisa deve adicionar favorito')
ext.refresh=originalRefresh
-- B no menu inicial abre modal, não apenas altera foco; Não é padrão.
set('screen','home');set('focus','content');set('stack',{})
press('b')
assert(get('screen')=='exit_confirm' and get('exitChoice')==2,'B abre confirmação com NÃO selecionado')
draw();assert(has('Fechar a loja?') or has('Deseja sair') or has('SAIR'), 'Modal de saída ausente')
press('a')
assert(not quit and get('screen')=='home','A em NÃO deve cancelar sem encerrar')
press('b')
press('dpleft')
assert(get('exitChoice')==1,'Esquerda deve selecionar SIM')
press('dpright')
assert(get('exitChoice')==2,'Direita deve selecionar NÃO')
press('dpleft');press('a')
assert(quit,'A em SIM deve sair')
quit=false
set('screen','home');set('stack',{})
press('b');press('b')
assert(get('screen')=='home' and not quit,'B dentro do modal cancela')
-- Popup: deve mostrar versão instalada, nova versão, novidades e botões.
set('screen','home');upd.status={phase='available',version='0.4.1-beta',notes='Correção da instalação.\nMenu melhorado.'};upd.offered=false
love.update(.1)
assert(get('storeUpdateModal')==true,'Versão nova deve apresentar popup')
draw()
assert(has('v0.4.0-beta') and has('v0.4.1-beta'),'Popup não mostra versões atual/nova')
assert(has('Correção'),'Popup não mostra novidades')
press('b');assert(get('storeUpdateModal')==false,'B deve dispensar popup')
-- Configurações: BIOS tem item próprio; teste sem subprocesso de BIOS.
local action=nil
local origRun=bios.run
bios.run=function(op)action=op;return true end
bios.status={phase='done',directory='/roms/bios',systems={{name='PlayStation',status='partial',found=1,expected=3},
 {name='Game Boy Advance',status='missing',found=0,expected=1}}}
set('screen','settings');set('settingsIndex',6)
press('a')
assert(get('screen')=='bios','Configurações não abriu BIOS do Sistema')
draw()
assert(has('BIOS do sistema'),'A tela de BIOS não tem título')
assert(has('PlayStation'),'A lista de BIOS não aparece')
press('a');assert(action=='scan','A deve verificar BIOS')
press('x');assert(get('biosActionModal')=='import','X exige confirmação para importar BIOS')
press('dpleft');press('a');assert(action=='import','SIM deve importar BIOS após confirmação')
press('y');assert(get('biosActionModal')=='restore','Y exige confirmação para restaurar BIOS')
press('b');assert(get('biosActionModal')==nil,'B cancela restauração')
bios.run=origRun
print('v0.4.0-beta: favorito Y, modal de saída selecionável, popup com novidades e BIOS UI: OK')
