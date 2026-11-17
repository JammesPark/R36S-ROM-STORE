-- Renderer da identidade visual R36S ROMS STORE, adaptado do conceito HTML 640x480.
local theme=require('theme')
local U={}
local fonts={}
local fallbackFont=nil
local fontData=nil
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
function U.font(size) return fonts[size] or fallbackFont end
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
function U.poster(x,y,w,h,name,index)
  local p=coverPalettes[(index-1)%#coverPalettes+1]
  U.rect(x,y,w,h,p[1],7)
  U.color(p[2],.93)
  love.graphics.polygon('fill',x,y+h,x+w*.44,y+h*.15,x+w,y+h)
  U.color(p[3],.34)
  love.graphics.circle('fill',x+w*.76,y+h*.16,w*.27)
  U.color({.01,.04,.13},.58)
  love.graphics.polygon('fill',x,y+h*.95,x+w*.25,y+h*.46,x+w*.46,y+h*.82,x+w*.78,y+h*.26,x+w,y+h)
  U.rect(x+8,y+8,27,3,p[3],1)
  local name1=tostring(name or '?'):upper()
  local n=U.ellipsize(name1,16)
  U.rect(x,y+h-31,w,31,{.015,.030,.075},0,nil,.75)
  U.text(n,x+8,y+h-26,12,theme.text,w-16)
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
