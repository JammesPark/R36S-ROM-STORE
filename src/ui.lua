-- Renderer da identidade visual R36S ROMS STORE, adaptado do conceito HTML 640x480.
local theme=require('theme')
local U={}
local fonts={}
local fallbackFont=nil
local fontData=nil
local fontScale=1
local sizeOptions={small=0.91,medium=1.0,large=1.18}
function U.setFontSize(key)
  fontScale=sizeOptions[key] or 1
end
local function loadSystemFont()
  for _,path in ipairs({
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/TTF/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
    '/usr/share/fonts/opentype/noto/NotoSans-Regular.ttf'
  }) do
    local file=io.open(path,'rb')
    if file then
      local bytes=file:read('*a');file:close()
      if bytes and #bytes<4*1024*1024 then
        local ok,data=pcall(love.filesystem.newFileData,bytes,'ui-system.ttf')
        if ok then return data end
      end
    end
  end
end
function U.init()
  fontData=loadSystemFont()
  for _,size in ipairs({9,10,11,12,13,14,15,16,17,18,19,20,22,24,26,27,28}) do
    local ok,font=pcall(function()
      return fontData and love.graphics.newFont(fontData,size) or love.graphics.newFont(size)
    end)
    if ok then fonts[size]=font
    else fonts[size]=love.graphics.newFont(size) end
  end
  fallbackFont=fonts[12]
end
function U.font(size)
  local value=math.max(8,math.min(32,math.floor((size or 12)*fontScale+0.5)))
  if not fonts[value] then
    local ok,resource=pcall(function()
      return fontData and love.graphics.newFont(fontData,value) or love.graphics.newFont(value)
    end)
    fonts[value]=(ok and resource) or fallbackFont
  end
  return fonts[value] or fallbackFont
end
function U.color(c,alpha)
  love.graphics.setColor(c[1],c[2],c[3],alpha or c[4] or 1)
end
function U.rect(x,y,w,h,c,r,stroke,alpha)
  if w<=0 or h<=0 then return end
  U.color(c,alpha)
  love.graphics.rectangle('fill',x,y,w,h,r or 0,r or 0)
  if stroke then U.color(stroke);love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,r or 0,r or 0) end
end
function U.stroke(x,y,w,h,c,r,width)
  U.color(c);love.graphics.setLineWidth(width or 1)
  love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,r or 0,r or 0)
  love.graphics.setLineWidth(1)
end
function U.text(s,x,y,size,color,maxwidth,center)
  s=tostring(s or '')
  if color then U.color(color) else U.color(theme.text) end
  local f=U.font(size or 12);love.graphics.setFont(f)
  if maxwidth then
    -- Evita que fonte Grande quebre titulos/cartoes em uma segunda linha.
    if type(f.getWidth)=='function' and f:getWidth(s)>maxwidth then
      local original=s
      local n=#original
      repeat
        n=n-1
        s=U.ellipsize(original,n)
      until n<=1 or f:getWidth(s)<=maxwidth
    end
    love.graphics.printf(s,x,y,maxwidth,center and 'center' or 'left')
  else
    love.graphics.print(s,x,y)
  end
end
function U.ellipsize(s,n)
  s=tostring(s or '')
  if #s<=n then return s end
  -- nao quebra codepoints UTF-8 ao cortar nomes de ROMs
  local i=1;local count=0;local last=1
  while i<=#s and count<n do
    local b=s:byte(i)
    local step=b<128 and 1 or b<224 and 2 or b<240 and 3 or 4
    last=i+step-1;i=i+step;count=count+1
  end
  if i>#s then return s end
  return s:sub(1,last)..'…'
end
function U.shadow(x,y,w,h)
  U.rect(x+2,y+4,w,h,{0,0,0},10,nil,.21)
end
function U.panel(x,y,w,h,chosen)
  U.rect(x,y,w,h,chosen and theme.panel2 or theme.panel,9,chosen and theme.accent or theme.border)
end
function U.layout(leftMode,selection)
  U.rect(0,0,640,480,theme.bg)
  U.rect(0,0,158,480,theme.sidebar)
  U.rect(157,0,1,480,theme.border)
  -- sombreado geometrico suave de cantos como no HTML
  U.color(theme.accent,.045)
  love.graphics.circle('fill',615,10,138)
  U.color(theme.accent,.022)
  love.graphics.circle('fill',525,57,105)
  U.rect(158,436,482,44,{.035,.080,.13})
  U.rect(158,435,482,1,theme.border)
  U.rect(13,29,34,34,theme.panel2,9,theme.accent)
  -- gamepad: desenho vetorial simplificado, sem usar logo externa
  U.stroke(21,40,18,13,theme.accent,5,2)
  U.rect(25,45,8,2,theme.accent,1)
  U.rect(28,42,2,8,theme.accent,1)
  U.color(theme.accent);love.graphics.circle('fill',36,44,1.4)
  U.color(theme.accent);love.graphics.circle('fill',39,47,1.4)
  U.text('R36S ROMS',58,29,14,theme.text)
  U.text('S T O R E',58,48,10,theme.accent)
  -- bottom sidebar
  U.rect(12,442,134,1,theme.border)
  U.color(theme.green);love.graphics.circle('fill',20,460,3)
end
function U.pill(text,x,y,w,active)
  U.rect(x,y,w,24,active and theme.panel2 or theme.panel,7,active and theme.accent or theme.border)
  U.text(text,x+9,y+5,10,active and theme.accent or theme.muted,w-18)
end
function U.kicker(text,x,y)
  U.color(theme.accent);love.graphics.circle('fill',x+3,y+7,2.6)
  U.text(string.upper(text),x+13,y,11,theme.accent,400)
end
function U.footer(a,b,c)
  local x=177
  local function key(t,description)
    local wid=math.max(20,#t*7+8)
    U.rect(x,449,wid,18,theme.panel2,5,theme.border)
    U.text(t,x+4,452,10,theme.accent)
    U.text(description,x+wid+5,453,10,theme.muted)
    x=x+wid+10+math.min(110,(#description*6.6)+5)
  end
  key('A',a or 'OK');key('B',b or 'VOLTAR');
  if c then key('L/R',c) end
end
local coverPalettes={
  {{.08,.10,.35},{.42,.17,.55},{1,.68,.48}},
  {{.13,.05,.24},{.53,.22,.30},{1,.72,.55}},
  {{.02,.26,.42},{.07,.48,.57},{.97,.92,.47}},
  {{.08,.14,.38},{.16,.45,.78},{.62,.90,.98}},
  {{.32,.13,.29},{.66,.36,.28},{1,.87,.56}},
  {{.06,.19,.22},{.16,.42,.48},{.60,.98,.79}},
  {{.29,.13,.20},{.65,.31,.22},{1,.86,.60}}
}
function U.poster(x,y,w,h,name,index,showName)
  local p=coverPalettes[(index-1)%#coverPalettes+1]
  U.rect(x,y,w,h,p[1],7)
  U.color(p[2],.93)
  love.graphics.polygon('fill',x,y+h,x+w*.44,y+h*.15,x+w,y+h)
  U.color(p[3],.34)
  love.graphics.circle('fill',x+w*.76,y+h*.16,w*.27)
  U.color({.01,.04,.13},.58)
  love.graphics.polygon('fill',x,y+h*.95,x+w*.25,y+h*.46,x+w*.46,y+h*.82,x+w*.78,y+h*.26,x+w,y+h)
  U.rect(x+8,y+8,27,3,p[3],1)
  if showName then
    local name1=tostring(name or '?'):upper()
    local n=U.ellipsize(name1,16)
    U.rect(x,y+h-31,w,31,{.015,.030,.075},0,nil,.75)
    U.text(n,x+8,y+h-26,12,theme.text,w-16)
  end
end
-- Mantém a capa inteira dentro do espaço, sem recortar as extremidades.
function U.imageContain(image,x,y,w,h)
  local iw,ih=image:getDimensions()
  if iw<=0 or ih<=0 then return end
  local factor=math.min(w/iw,h/ih)
  local fw,fh=iw*factor,ih*factor
  U.color({1,1,1})
  love.graphics.draw(image,x+(w-fw)/2,y+(h-fh)/2,0,factor,factor)
end

-- Logo vetorial integrada ao app, sem depender de PNG ou internet.
-- Indicadores visuais; dados são consultados localmente em sysfs/proc.
function U.statusBar(data)
  data=data or {}
  -- Alinhamento comum dos centros em y=18: Wi-Fi | hora | bateria.
  U.rect(437,5,191,26,theme.sidebar,7,theme.border,.96)
  U.rect(478,10,1,16,theme.border,0)
  U.rect(541,10,1,16,theme.border,0)
  local wifi=data.wifi and theme.green or theme.low
  U.color(wifi)
  love.graphics.setLineWidth(1.9)
  love.graphics.line(449,16,456,11,463,16)
  love.graphics.line(452,19,456,16,460,19)
  love.graphics.circle('fill',456,22,1.6)
  love.graphics.setLineWidth(1)
  U.text(data.time or '--:--',483,11,11,theme.text,55,true)
  local p=tonumber(data.battery)
  local fill=p and (p<=15 and theme.error or theme.green) or theme.low
  U.rect(552,12,24,12,theme.panel,2,theme.muted)
  U.rect(576,16,2,4,theme.muted,1)
  if p then
    U.rect(555,15,math.max(0,18*math.min(100,math.max(0,p))/100),6,fill,1)
  end
  U.text(p and (tostring(math.floor(p+0.5))..'%') or '--%',582,11,10,theme.text,42,true)
end
-- Icones vetoriais de 17x17 para preservar legibilidade em 640x480.
function U.searchIcon(x,y,c)
  U.color(c);love.graphics.setLineWidth(2)
  love.graphics.circle('line',x+7,y+7,5)
  love.graphics.line(x+11,y+11,x+16,y+16)
  love.graphics.setLineWidth(1)
end
function U.menuIcon(kind,x,y,c)
  U.color(c);love.graphics.setLineWidth(1.7)
  if kind=='home' then
    love.graphics.line(x+1,y+8,x+9,y+1,x+17,y+8)
    love.graphics.rectangle('line',x+4,y+8,11,9,2,2)
    love.graphics.rectangle('line',x+8,y+11,3,6)
  elseif kind=='catalog' then
    for i=0,1 do for j=0,1 do love.graphics.rectangle('line',x+2+j*9,y+2+i*9,6,6,1,1) end end
  elseif kind=='downloads' then
    love.graphics.line(x+9,y+1,x+9,y+12,x+5,y+8)
    love.graphics.line(x+9,y+12,x+13,y+8)
    love.graphics.line(x+2,y+14,x+2,y+17,x+16,y+17,x+16,y+14)
  elseif kind=='installed' then
    love.graphics.rectangle('line',x+2,y+3,14,13,3,3)
    love.graphics.line(x+5,y+10,x+8,y+13,x+14,y+6)
  elseif kind=='favorites' then
    love.graphics.polygon('line',x+9,y+1,x+11,y+6,x+17,y+7,x+13,y+11,x+14,y+17,x+9,y+14,x+4,y+17,x+5,y+11,x+1,y+7,x+7,y+6)
  elseif kind=='settings' then
    love.graphics.circle('line',x+9,y+9,6)
    love.graphics.circle('line',x+9,y+9,2)
    love.graphics.line(x+9,y,x+9,y+3,x+9,y+15,x+9,y+18,x,y+9,x+3,y+9,x+15,y+9,x+18,y+9)
  elseif kind=='about' then
    love.graphics.circle('line',x+9,y+9,8)
    love.graphics.line(x+9,y+8,x+9,y+13)
    love.graphics.circle('fill',x+9,y+5,1)
  elseif kind=='exit' then
    love.graphics.circle('line',x+9,y+10,7)
    love.graphics.line(x+9,y+1,x+9,y+11)
  else
    love.graphics.rectangle('line',x+2,y+2,14,14,2,2)
  end
  love.graphics.setLineWidth(1)
end
function U.platformIcon(category,x,y,c)
  local id=tostring(category or 'ALL'):lower()
  U.color(c);love.graphics.setLineWidth(1.5)
  if id=='all' then
    for row=0,1 do for col=0,1 do love.graphics.rectangle('line',x+2+col*9,y+2+row*9,6,6,1,1) end end
  elseif id:find('arcade') or id=='mame' or id:find('cps') then
    love.graphics.rectangle('line',x+2,y+11,14,6,2,2)
    love.graphics.line(x+8,y+11,x+8,y+5)
    love.graphics.circle('fill',x+8,y+4,2)
    love.graphics.circle('fill',x+13,y+13,1.6)
  elseif id:find('ps') or id:find('dreamcast') or id:find('saturn') or id:find('cd') then
    love.graphics.circle('line',x+9,y+9,8)
    love.graphics.circle('line',x+9,y+9,2.1)
    love.graphics.line(x+2,y+9,x+5,y+9)
  elseif id:find('gb') or id:find('nds') or id:find('3ds') or id:find('psp') then
    love.graphics.rectangle('line',x+4,y+1,10,17,2,2)
    love.graphics.rectangle('line',x+6,y+4,6,7,1,1)
    love.graphics.line(x+7,y+14,x+11,y+14)
  elseif id:find('nes') or id:find('snes') or id:find('gba') or id:find('genesis') or id:find('mega') or id:find('n64') then
    love.graphics.rectangle('line',x+3,y+3,12,13,2,2)
    love.graphics.line(x+6,y+8,x+11,y+8)
    love.graphics.line(x+6,y+11,x+11,y+11)
  elseif id=='ports' or id:find('homebrew') then
    love.graphics.line(x+4,y+15,x+12,y+6)
    love.graphics.circle('line',x+13,y+5,4)
    love.graphics.circle('fill',x+3,y+16,2)
  else
    love.graphics.rectangle('line',x+1,y+5,16,10,5,5)
    love.graphics.line(x+5,y+9,x+9,y+9,x+7,y+7,x+7,y+11)
    love.graphics.circle('fill',x+13,y+9,1.3)
  end
  love.graphics.setLineWidth(1)
end
function U.catalogFooter(selectText,backText,searchText,pageText)
  U.rect(158,436,482,44,{.035,.080,.13})
  U.rect(158,435,482,1,theme.border)
  local function key(x,keyName,label)
    local w=keyName=='L/R' and 34 or 20
    U.rect(x,449,w,18,theme.panel2,5,theme.border)
    U.text(keyName,x+3,452,10,theme.accent,w-6,true)
    U.text(label,x+w+4,453,10,theme.muted,76)
  end
  key(177,'A',selectText)
  key(270,'B',backText)
  key(351,'X',searchText)
  key(469,'L/R',pageText)
end
function U.brandLogo(x,y,scale)
  scale=scale or 1
  local function p(v) return v*scale end
  U.rect(x,y,p(86),p(76),theme.panel2,p(17),theme.accent)
  U.color(theme.accent,.12)
  love.graphics.circle('fill',x+p(43),y+p(38),p(34))
  -- Silhueta de portátil com visor e controles.
  U.rect(x+p(13),y+p(16),p(60),p(44),theme.sidebar,p(9),theme.accent)
  U.rect(x+p(21),y+p(22),p(44),p(22),theme.panel,p(4),theme.border)
  U.rect(x+p(25),y+p(26),p(36),p(14),theme.accent,p(2),nil,.17)
  U.rect(x+p(25),y+p(49),p(15),p(3),theme.accent,p(1))
  U.rect(x+p(31),y+p(43),p(3),p(16),theme.accent,p(1))
  U.color(theme.green)
  love.graphics.circle('fill',x+p(60),y+p(49),p(3))
  U.color(theme.accent)
  love.graphics.circle('fill',x+p(54),y+p(54),p(2.5))
end
function U.brandLockup(x,y)
  U.brandLogo(x,y,1)
  U.text('R36S',x+102,y+1,28,theme.text)
  U.rect(x+102,y+38,183,2,theme.accent,1)
  U.text('ROMS STORE',x+102,y+45,20,theme.accent)
end
function U.flag(code,x,y,w,h)
  local white={.98,.98,.98};local red={.86,.15,.22};local blue={.09,.21,.52}
  U.rect(x-1,y-1,w+2,h+2,theme.border,3)
  if code=='pt' then
    U.rect(x,y,w,h,{.09,.55,.27},2)
    U.color({.98,.84,.10});love.graphics.polygon('fill',x+w*.5,y+h*.10,x+w*.92,y+h*.5,x+w*.5,y+h*.9,x+w*.08,y+h*.5)
    U.color(blue);love.graphics.circle('fill',x+w*.5,y+h*.5,h*.23)
    U.rect(x+w*.32,y+h*.48,w*.36,1,white,1)
  elseif code=='en' then
    U.rect(x,y,w,h,white,2)
    for i=0,6 do U.rect(x,y+i*h/7,w,h/14,red,0) end
    U.rect(x,y,w*.45,h*.55,blue,0)
    U.color(white)
    for i=0,2 do for j=0,2 do love.graphics.circle('fill',x+4+j*w*.105,y+3+i*h*.13,1) end end
  elseif code=='es' then
    U.rect(x,y,w,h,{.97,.77,.15},2)
    U.rect(x,y,w,h*.25,red,1)
    U.rect(x,y+h*.75,w,h*.25,red,1)
    U.rect(x+w*.29,y+h*.39,w*.08,h*.22,red,1)
  elseif code=='ru' then
    U.rect(x,y,w,h,white,2)
    U.rect(x,y+h/3,w,h/3,{.11,.34,.74},0)
    U.rect(x,y+h*2/3,w,h/3,{.78,.15,.22},0)
  end
  U.stroke(x-1,y-1,w+2,h+2,theme.border,2,1)
end

function U.imageCrop(image,x,y,w,h)
  local iw,ih=image:getDimensions()
  if iw<=0 or ih<=0 then return end
  local scale=math.max(w/iw,h/ih)
  local drawX=x+(w-iw*scale)/2
  local drawY=y+(h-ih*scale)/2
  local sx,sy,sw,sh=love.graphics.getScissor()
  love.graphics.setScissor(x,y,w,h)
  U.color({1,1,1})
  love.graphics.draw(image,drawX,drawY,0,scale,scale)
  if sx then love.graphics.setScissor(sx,sy,sw,sh) else love.graphics.setScissor() end
end
return U
