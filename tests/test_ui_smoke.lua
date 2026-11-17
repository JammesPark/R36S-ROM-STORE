package.path='src/?.lua;'..package.path
local drawn={}
local font={}
local gfx={}
for _,k in ipairs({'setDefaultFilter','setColor','rectangle','circle','polygon','line','setLineWidth','setFont','setScissor','draw'}) do
  gfx[k]=function(...) return nil end
end
function gfx.getScissor() return nil end
function gfx.newFont(...) return font end
function gfx.newImage(...) return {getDimensions=function() return 140,100 end} end
function gfx.print(s,...) drawn[#drawn+1]=tostring(s) end
function gfx.printf(s,...) drawn[#drawn+1]=tostring(s) end
love={graphics=gfx,filesystem={newFileData=function(v,n) return v end}}
require('main')
love.load()
love.draw()
love.update(2)
love.draw()
local ext=require('external')
ext.categories={{category='ALL',count=10},{category='psx',count=4},{category='snes',count=6}}
ext.games={{name='Teste ROM A',category='psx',game_path='https://example.org/game-a.zip'},
{name='Teste ROM B',category='snes',game_path='https://example.org/game-b.zip'},
{name='Teste ROM C',category='psx',game_path='https://example.org/game-c.zip'}}
ext.total=10
local function setRoute(r)
  for i=1,50 do
    local name=debug.getupvalue(love.draw,i)
    if not name then break end
    if name=='screen' then debug.setupvalue(love.draw,i,r);return end
  end
  error('Nenhuma variavel screen encontrada')
end
local screens={'home','catalog','search','detail','confirm','transferring','success',
 'downloads','history','installed','favorites','settings','languages','themes',
 'storage','network','about','help','offline','startup'}
for _,route in ipairs(screens) do
  drawn={}
  setRoute(route)
  local ok,err=pcall(love.draw)
  assert(ok,'Erro ao desenhar '..route..': '..tostring(err))
  assert(#drawn>2,'Nenhum texto desenhado na tela '..route)
end
setRoute('catalog')
love.keypressed('x') -- Favoritos
setRoute('favorites')
love.draw()
-- Testar quatro idiomas/temas sem acesso de rede.
setRoute('languages')
for _=1,3 do love.keypressed('down') end
love.keypressed('return')
love.draw()
setRoute('themes')
love.keypressed('right')
love.keypressed('return')
love.draw()
print('UI R36S ROMS STORE: '..#screens..' telas renderizadas, favoritos, idiomas e temas OK')
