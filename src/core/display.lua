-- Ajusta a STORE ao painel real, mesmo quando SDL2/KMSDRM apresenta
-- framebuffer 640x480 que o firmware estica para um painel 720x720.
-- Renderiza sempre o layout logico 640x480, sem alterar o modo do sistema.
local M = {
  logical_w = 640, logical_h = 480,
  width = 640, height = 480, -- superficie SDL em coordenadas LÖVE
  physical_w = 640, physical_h = 480, -- painel (Linux framebuffer/DRM)
  scale = 1, scale_x = 1, scale_y = 1,
  x = 0, y = 0, source = "fallback", detected = false,
  physical_source = "unknown",
}

local function valid(w, h)
  return type(w) == "number" and type(h) == "number"
    and w == w and h == h and w >= 160 and h >= 120
    and w <= 8192 and h <= 8192
end

local function pair(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok,w,h = pcall(fn, ...)
  if ok and valid(w,h) then return math.floor(w), math.floor(h) end
end

local function parse_mode(s)
  if type(s) ~= "string" then return nil end
  local w,h = s:match("(%d+)%s*x%s*(%d+)")
  w,h = tonumber(w),tonumber(h)
  if valid(w,h) then return w,h end
end

local function read_file(path)
  local f = io.open(path,"rb")
  if not f then return nil end
  local data = f:read(512)
  f:close()
  return data
end

local function drm_connectors()
  local ok, process = pcall(io.popen, "ls -1d /sys/class/drm/card*-* 2>/dev/null")
  if not ok or not process then return {} end
  local paths = {}
  for line in process:lines() do
    if line:match("^/sys/class/drm/card[%w%-]+$") then paths[#paths+1]=line end
  end
  process:close()
  return paths
end

-- O Linux permite obter a resolucao do painel sem depender da janela SDL.
-- Preferir fb0/mode (modo atual) a /modes (lista de suportados).
-- Se houver apenas /modes, selecionar conector DRM conectado, nao qualquer
-- saida HDMI desconectada. virtual_size e usado somente como ultimo recurso.
function M.probe_physical(read, list)
  read = read or read_file
  list = list or drm_connectors
  local fw,fh=parse_mode(read("/sys/class/graphics/fb0/mode"))
  local dw,dh,dp
  local ok, connectors = pcall(list)
  if ok and type(connectors)=="table" then
    table.sort(connectors)
    for _,base in ipairs(connectors) do
      if type(base)=="string" and base:match("^/sys/class/drm/card[%w%-]+$") then
        local status=(read(base.."/status") or ""):match("^%s*(%S+)")
        if status=="connected" then
          dw,dh=parse_mode(read(base.."/modes"))
          if dw then dp=base.."/modes"; break end
        end
      end
    end
  end
  -- Modo fb0 pode refletir framebuffer LOGICO 640x480, escalado pelo
  -- KMS para um painel 720x720. Quando as proporcoes divergem, a saida
  -- DRM conectada representa melhor a resolucao FISICA do painel.
  if dw and fw and math.abs(dw/dh-fw/fh)>0.04 then return dw,dh,dp end
  if fw then return fw,fh,"/sys/class/graphics/fb0/mode" end
  if dw then return dw,dh,dp end
  local mw,mh=parse_mode(read("/sys/class/graphics/fb0/modes"))
  if mw then return mw,mh,"/sys/class/graphics/fb0/modes" end
  local fbs = read("/sys/class/graphics/fb0/virtual_size")
  if type(fbs)=="string" then
    local w,h=fbs:match("(%d+)%s*,%s*(%d+)")
    w,h=tonumber(w),tonumber(h)
    if valid(w,h) then return w,h,"/sys/class/graphics/fb0/virtual_size" end
  end
  return nil
end

function M.fit(w,h,lw,lh)
  lw,lh=lw or M.logical_w,lh or M.logical_h
  if not valid(w,h) or not valid(lw,lh) then w,h,lw,lh=640,480,640,480 end
  local sc=math.min(w/lw,h/lh)
  return sc,math.floor((w-lw*sc)/2+0.0001),math.floor((h-lh*sc)/2+0.0001)
end

-- O desenho acontece nas unidades de coordenada da janela LÖVE, mas pode
-- ser esticado pelo firmware quando o painel fisico tem outra proporcao.
-- Por isso os fatores X e Y podem ser DIFERENTES nas coordenadas SDL:
-- depois da conversao do firmware, a imagem fica corretamente em 4:3.
function M.detect(graphics,window,resize_w,resize_h,read,list)
  local w,h,source
  if valid(resize_w,resize_h) then
    w,h,source=math.floor(resize_w),math.floor(resize_h),"resize"
  else
    w,h=pair(graphics and graphics.getDimensions)
    if w then source="love.graphics"
    else
      w,h=pair(window and window.getMode)
      if w then source="love.window"
      else
        w,h=pair(window and window.getDesktopDimensions)
        if w then source="desktop"
        else w,h,source=640,480,"fallback" end
      end
    end
  end
  local pw,ph,p_source=M.probe_physical(read,list)
  if not pw then pw,ph,p_source=w,h,source end
  local changed=(w~=M.width or h~=M.height or pw~=M.physical_w
    or ph~=M.physical_h or source~=M.source or p_source~=M.physical_source)
  M.width,M.height,M.source=w,h,source
  M.physical_w,M.physical_h,M.physical_source=pw,ph,p_source
  M.detected = source~="fallback" or p_source~="fallback"
  M.scale,M.physical_x,M.physical_y=M.fit(pw,ph)
  M.scale_x=M.scale*w/pw
  M.scale_y=M.scale*h/ph
  M.x=M.physical_x*w/pw
  M.y=M.physical_y*h/ph
  return changed
end

function M.needs_canvas()
  return math.abs(M.scale_x-1)>0.0001 or math.abs(M.scale_y-1)>0.0001
    or math.abs(M.x)>0.0001 or math.abs(M.y)>0.0001
end
function M.dimensions() return M.physical_w,M.physical_h end
function M.label() return string.format("%dx%d",M.physical_w,M.physical_h) end
function M.to_logical(px,py)
  if type(px)~="number" or type(py)~="number"
      or M.scale_x<=0 or M.scale_y<=0 then return nil end
  local x,y=(px-M.x)/M.scale_x,(py-M.y)/M.scale_y
  if x<0 or y<0 or x>=M.logical_w or y>=M.logical_h then return nil end
  return x,y
end
return M
