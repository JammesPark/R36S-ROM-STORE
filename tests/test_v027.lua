package.path='src/?.lua;'..package.path
local rendered={}
local font={
  getWidth=function(_,s) return #tostring(s)*6 end,
  getHeight=function() return 14 end,
  getWrap=function(_,s,width)
    local n=math.max(1,math.ceil(#tostring(s)*6/width))
    local lines={}
    for i=1,n do lines[i]='line' end
    return width,lines
  end,
}
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[k]=function() end
end
function gfx.getScissor() return nil end
function gfx.newFont() return font end
function gfx.newImage() return {getDimensions=function() return 740,542 end} end
function gfx.print(s) rendered[#rendered+1]=tostring(s) end
function gfx.printf(s) rendered[#rendered+1]=tostring(s) end
love={graphics=gfx,filesystem={newFileData=function(v,n) return v end},event={quit=function() error('Sair nao permitido no onboarding') end}}
require('main')
local index=tonumber(os.getenv('TEST_LANGUAGE_INDEX') or '2')
local code=({'pt','en','es','ru'})[index]
assert(code,'Índice de idioma do teste inválido')
local firstRun=os.getenv('TEST_FIRST_RUN')=='1'
local names={pt='Bem-vindo ao R36S ROMS STORE!',en='Welcome to R36S ROMS STORE!',
  es='¡Bienvenido a R36S ROMS STORE!',ru='Добро пожаловать в R36S ROMS STORE!'}
local function screen()
  for i=1,140 do
    local name,val=debug.getupvalue(love.draw,i)
    if name=='screen' then return val end
  end
end
local function redraw()
  rendered={}
  love.draw()
  return table.concat(rendered,' | ')
end
love.load()
assert(screen()=='startup','A primeira tela nao e carregamento')
love.gamepadpressed(nil,'a')
assert(screen()=='startup','A ignorou a tela de carregamento')
love.update(2)
if firstRun then
  assert(screen()=='first_language','Primeira execucao nao pediu idioma')
  local text=redraw()
  assert(text:find('Português',1,true) and text:find('Español',1,true) and text:find('Русский',1,true),
    'Tela inicial nao apresenta os quatro idiomas')
  love.gamepadpressed(nil,'b')
  assert(screen()=='first_language','B ignorou escolha inicial')
  for _=2,index do love.gamepadpressed(nil,'dpdown') end
  love.gamepadpressed(nil,'a')
  assert(screen()=='disclaimer','Escolha do idioma nao abriu o aviso')
  local p=io.open(os.getenv('R36S_STORE_HOME')..'/state/roms_settings.json','rb')
  assert(p,'Escolha do idioma nao foi persistida')
  local json=p:read('*a');p:close()
  assert(json:find('"language_chosen":true',1,true),'Flag de idioma ausente no estado')
  assert(json:find('"language":"'..code..'"',1,true),'Idioma persistido incorretamente')
else
  assert(screen()=='disclaimer','Reabertura deve ir diretamente para aviso')
end
local renderedNotice=redraw()
assert(renderedNotice:find(names[code],1,true),'Aviso nao esta no idioma escolhido')
assert(renderedNotice:find('R36S ROMS STORE',1,true),'Aviso sem identidade da loja')
love.gamepadpressed(nil,'b')
assert(screen()=='disclaimer','B ignorou aviso obrigatorio')
love.gamepadpressed(nil,'a')
assert(screen()=='home','A nao entrou na loja apos aviso')
-- A tela Sobre precisa conter os termos legais e permitir rolar.
for i=1,140 do
  local name=debug.getupvalue(love.draw,i)
  if name=='screen' then debug.setupvalue(love.draw,i,'about'); break end
end
local about=redraw()
assert(about:find('GNU GPL-3.0',1,true),'Sobre sem termo de licença GPL')
assert(about:find('LICENSE',1,true),'Sobre nao cita LICENSE')
assert(about:find('R36S ROMS STORE',1,true),'Sobre sem identidade')
love.gamepadpressed(nil,'dpdown')
redraw()
print('ONBOARDING '..code..' '..(firstRun and 'primeira vez' or 'nova abertura')..': OK')
