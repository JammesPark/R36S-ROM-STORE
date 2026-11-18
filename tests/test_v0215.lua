-- v0.2.15: testes da tela inicial e dos oito ícones na sidebar real.
package.path='src/?.lua;'..package.path
local rows,rects,nav={},{},{}
local currentColor={1,1,1,1}
local font={}
function font:getWidth(s) return #tostring(s)*6 end
function font:getHeight() return 13 end
function font:getWrap(s,w) return w,{tostring(s)} end
local gfx={}
for _,k in ipairs({'setDefaultFilter','line','polygon','setLineWidth','setFont','setScissor','draw'}) do gfx[k]=function(...)end end
function gfx.getScissor() return nil end
function gfx.setColor(r,g,b,a)currentColor={r,g,b,a or 1}end
function gfx.newFont(...)return font end
function gfx.newImage(...)return {getDimensions=function()return 120,160 end}end
function gfx.rectangle(mode,x,y,w,h)
  rects[#rects+1]={mode=mode,x=x,y=y,w=w,h=h,color={table.unpack(currentColor)}}
end
function gfx.circle()end
function gfx.print(s,x,y)rows[#rows+1]={text=tostring(s),x=x,y=y}end
function gfx.printf(s,x,y,w)rows[#rows+1]={text=tostring(s),x=x,y=y,w=w}end
love={graphics=gfx,filesystem={newFileData=function(v)return v end},event={quit=function()end}}
require('main');love.load()
local ext=require('external')
local ui=require('ui')
local original=ui.menuIcon
ui.menuIcon=function(kind,x,y,c)
  nav[#nav+1]={kind=kind,x=x,y=y,color=c}
  return original(kind,x,y,c)
end
local function up(name)
  for i=1,90 do
    local a,b=debug.getupvalue(love.draw,i)
    if not a then break end
    if a==name then return i,b end
  end
  error('Variável '..name..' ausente')
end
local function set(name,value) local i=up(name);debug.setupvalue(love.draw,i,value)end
local function get(name) local _,v=up(name);return v end
local function reset()rows={};rects={};nav={}end
local function has(s)
  for _,v in ipairs(rows) do if v.text:find(s,1,true) then return true end end
  return false
end
set('screen','home');reset();ext.activeDownload=nil;ext.pending=nil
love.draw()
local keys={'home','catalog','downloads','installed','favorites','settings','about','exit'}
assert(#nav==8,'Barra lateral não chamou oito ícones: '..#nav)
for i,n in ipairs(keys) do
  assert(nav[i].kind==n,'Ícone da sidebar incorreto: '..i..' '..tostring(nav[i].kind))
  assert(nav[i].x==26 and nav[i].y==130+(i-1)*38,'Ícone desalinhado: '..n)
end
assert(has('DOWNLOAD ATUAL'),'Tela inicial sem título DOWNLOAD ATUAL')
assert(has('Nenhuma transferência em andamento.'),'Estado sem download não apareceu')
assert(has('VER DOWNLOADS'),'Botão de downloads não apareceu')
assert(not has('Um universo de jogos no seu console.'),'Mensagem antiga permaneceu')
assert(not has('EXPLORAR CATÁLOGO'),'Botão antigo ainda na home')
local emptyBar=false
for _,r in ipairs(rects) do
  if r.mode=='fill' and r.x==194 and r.y==155 and r.w==258 then emptyBar=true end
end
assert(not emptyBar,'Barra de progresso exibida sem download')
-- Teste de transferência real, não de dados demonstrativos.
reset();ext.activeDownload={name='Jogo Em Transferência',card=2}
ext.pending='download';ext.phase='downloading';ext.expected=80;ext.downloaded=20
love.draw()
assert(has('Jogo Em Transferência'),'Nome do download não apareceu')
assert(has('SD2'),'Cartão correto não apareceu')
assert(has('25%'),'Progresso deve mostrar 25%')
assert(not has('Nenhuma transferência em andamento.'),'Estado vazio permaneceu durante download')
local filled=false
for _,r in ipairs(rects) do
  if r.mode=='fill' and r.x==194 and r.y==155 and math.abs(r.w-64.5)<0.01 then filled=true end
end
assert(filled,'Barra não refletiu bytes reais de download')
-- Não inventar porcentagem antes do backend informar o tamanho.
reset();ext.expected=0;ext.downloaded=0;love.draw()
assert(not has('25%') and has('—'),'Tamanho desconhecido deveria mostrar um traço')
-- Clique e botão A do painel superior abrem Download, não Catálogo.
set('screen','home');ext.pending=nil
love.mousepressed(550,163,1)
assert(get('screen')=='downloads','Clique no painel não abriu Downloads')
set('screen','home');set('focus','content');set('homeFocus','explore')
love.gamepadpressed(nil,'a')
assert(get('screen')=='downloads','A no painel não abriu Downloads')
print('v0.2.15: 8 ícones da sidebar, home vazia, download real e atalhos A/clique: OK')
