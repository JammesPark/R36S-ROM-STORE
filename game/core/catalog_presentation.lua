-- Apresentacao do catalogo: nao altera URLs, IDs nem arquivos originais.
local P = {}
local extensions = {mgw=true, rom=true, mx2=true, unf=true, pak=true, sc=true, sap=true,
  zip=true, ["7z"]=true, rar=true, nes=true, gba=true, gbc=true, gb=true,
  sfc=true, smc=true, bin=true, iso=true, chd=true, cue=true, cso=true, pbp=true,
  a26=true, a52=true, lnx=true, lha=true, nds=true, n64=true, z64=true,
  v64=true, pce=true, wsc=true, ws=true, ngp=true, ngc=true, gg=true,
  sms=true, md=true, gen=true, col=true, dsk=true, cas=true}
function P.title(name, url)
  if type(name) ~= "string" or type(url) ~= "string" then return name end
  local stem, ext = name:match("^(.-)%.([%w]+)$")
  if not stem or stem == "" or not extensions[ext:lower()] then return name end
  local path = url:match("^[^?#]+") or ""
  local actual = path:match("%.([%w]+)$")
  if actual and actual:lower() == ext:lower() then
    return (stem:gsub("%s+$", ""))
  end
  return name
end
function P.less(a,b)
  local function key(c)
    local id = tostring(c.id or ""):lower()
    if id == "cps1" or id == "cps2" or id == "cps3" then return id end
    return tostring(c.name or id):lower()
  end
  local an,bn = key(a),key(b)
  if an == bn then return tostring(a.id or "") < tostring(b.id or "") end
  return an < bn
end
function P.systems(categories)
  local list={}
  for _,c in ipairs(categories or {}) do
    if c.section == "games" then list[#list+1]=c end
  end
  table.sort(list,P.less)
  return list
end
return P
