-- Icones exclusivos da Central de Conteudo (640x480).
-- Vetores LÖVE2D: espessura e cores consistentes, sem depender de arquivos
-- antigos nem alterar icones dos outros menus ou de temas opcionais.
-- Temas determinam a cor; simbolos representam as acoes reais.
local lg=love.graphics
local M={}
local IDS={games=true,bios=true,tools=true,search=true,favs=true,
           news=true,downloads=true}

local function ink(c,a)
  if type(c)=="table" then
    lg.setColor(c[1] or 1,c[2] or 1,c[3] or 1,(c[4] or 1)*(a or 1))
  else
    lg.setColor(1,1,1,a or 1)
  end
end
local function ln(...) lg.line(...) end
local function frame(x,y,w,h,r) lg.rectangle("line",x,y,w,h,r or 0,r or 0) end
local function fill(x,y,w,h,r) lg.rectangle("fill",x,y,w,h,r or 0,r or 0) end
local function dot(x,y,r) lg.circle("fill",x,y,r) end

-- Moldura sutil de vidro fosco e duas micro-luzes no topo.
local function base(c)
  ink(c,0.10); fill(1,1,46,46,12)
  ink(c,0.38); lg.setLineWidth(1.35); frame(1.8,1.8,44.4,44.4,11)
  ink(c,0.20); lg.setLineWidth(1); ln(8,8,22,8)
  ink(c,0.70); dot(37.0,8.5,1.25)
  ink(c,0.32); dot(41,8.5,1.25)
end
local function gamepad(c)
  -- Silhueta arredondada e simbolos D-pad + A/B. Nao confundir com ROMs.
  ink(c,0.15); fill(7,17,34,21,10)
  ink(c,1);lg.setLineWidth(2.6);frame(7,17,34,21,10)
  lg.setLineWidth(2.5);ln(16,22,16,32);ln(11,27,21,27)
  ink(c,1);dot(32.5,23.5,2.2);dot(36.2,29.2,2.2)
  ink(c,0.7);lg.setLineWidth(1.7);ln(21,16,21,13,27,13,27,16)
end
local function microchip(c)
  ink(c,1);lg.setLineWidth(2.25)
  frame(13,13,22,22,4)
  for i=0,2 do
    local p=17+i*7
    ln(p,9,p,13);ln(p,35,p,39)
    ln(9,p,13,p);ln(35,p,39,p)
  end
  ink(c,0.23);fill(18,18,12,12,3)
  ink(c,1);lg.setLineWidth(1.9);frame(18,18,12,12,3)
  ink(c,0.95);ln(21,24,27,24);dot(24,21,1.1);dot(24,27,1.1)
end
local function toolbox(c)
  -- Caixa de ferramentas: alca, corpo e divisoria, visual limpo.
  ink(c,0.15);fill(9,21,30,19,4)
  ink(c,1);lg.setLineWidth(2.5);frame(9,21,30,19,4)
  lg.setLineWidth(2.4);ln(17,21,17,15,31,15,31,21)
  lg.setLineWidth(1.9);ln(10,27,38,27)
  ink(c,1);fill(21,24.8,6,5,1.5)
  ink(c,0.50);lg.setLineWidth(1.7);ln(14,33,20,33);ln(29,33,34,33)
end
local function search(c)
  ink(c,0.14);lg.circle("fill",21,20,10.5)
  ink(c,1);lg.setLineWidth(3);lg.circle("line",21,20,10.5)
  ln(29,28,38,37)
  ink(c,0.48);lg.setLineWidth(1.7);lg.arc("line","open",21,20,6,3.4,4.9)
end
local function favorites(c)
  -- Coracao com contorno proprio e brilho interno.
  -- Preenchimento por formas convexas (evita triangulacao concava na Mali).
  ink(c,0.14)
  lg.circle("fill",17,20,8)
  lg.circle("fill",31,20,8)
  lg.polygon("fill",10,23,38,23,24,38)
  ink(c,1);lg.setLineWidth(2.6)
  ln(24,37,11,25,9,21,9,17,13,13,18,13,24,18,
     30,13,35,13,39,17,39,21,37,25,24,37)
  ink(c,0.55);lg.setLineWidth(1.8);ln(16,19,19,19)
end
local function newspaper(c)
  ink(c,0.12);fill(9,10,30,29,4)
  ink(c,1);lg.setLineWidth(2.4);frame(9,10,30,29,4)
  ink(c,0.86);fill(14,16,9,8,2)
  ink(c,1);lg.setLineWidth(2.1);ln(27,17,34,17);ln(27,22,34,22)
  ink(c,0.74);lg.setLineWidth(1.8);ln(14,29,34,29);ln(14,34,30,34)
end
local function download(c)
  ink(c,1);lg.setLineWidth(3);ln(24,10,24,30)
  ln(16,23,24,31,32,23)
  lg.setLineWidth(2.8);ln(11,34,11,38,37,38,37,34)
  ink(c,0.45);lg.setLineWidth(1.8);ln(14,16,14,13,18,13)
end
local function trophy(c)
  ink(c,0.18);fill(17,13,14,15,4)
  ink(c,1);lg.setLineWidth(2.5);frame(17,13,14,15,3)
  ln(17,16,12,16,12,21,16,24,18,24)
  ln(31,16,36,16,36,21,32,24,30,24)
  ln(24,28,24,35);ln(17,37,31,37)
  ink(c,0.85);dot(24,20,2.6)
end
local RENDER={
  games=gamepad,bios=microchip,tools=toolbox,search=search,
  favs=favorites,news=newspaper,downloads=download,
}

function M.has(id) return IDS[id]==true end
function M.draw(id,x,y,size,color)
  local fn=RENDER[id]
  if not fn then return false end
  local z=(size or 48)/48
  lg.push("all")
  lg.translate(x,y)
  lg.scale(z,z)
  base(color)
  fn(color)
  lg.pop()
  return true
end
return M
