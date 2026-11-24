-- Avaliacao local por port e por catalogo; sem inventar votos online.
local json=require("lib.json")
local R={loaded=false,votes={lira={},r36sbr={}}}
local FILE="ratings.json"
local function catalog(c)
 if c=="lira" or c=="r36sbr" then return c end
 return require("core.catalog").catalog_source()
end
local function good(p)return type(p)=="table" and type(p.id)=="string"
 and #p.id>0 and #p.id<=120 and not p.builtin end
function R.load()
 R.loaded=true;R.votes={lira={},r36sbr={}}
 local ok,s=pcall(love.filesystem.read,FILE)
 if not ok or type(s)~="string" then return end
 local decoded,data=pcall(json.decode,s)
 if not decoded or type(data)~="table" then return end
 for _,cat in ipairs({"lira","r36sbr"}) do
  for id,v in pairs(type(data[cat])=="table" and data[cat] or {}) do
   if type(id)=="string" and #id<=120 and (v=="up" or v=="down") then
    R.votes[cat][id]=v
   end
  end
 end
end
function R.get(p,cat)
 if not R.loaded then R.load() end
 if not good(p) then return nil end
 return R.votes[catalog(cat)][p.id]
end
local function persist()
 local data=json.encode(R.votes)
 local ok,done=pcall(love.filesystem.write,FILE..".new",data)
 if not ok or not done then return false end
 local dir=love.filesystem.getSaveDirectory()
 if os.rename(dir.."/"..FILE..".new",dir.."/"..FILE) then return true end
 local fallback,saved=pcall(love.filesystem.write,FILE,data)
 return fallback and saved and true or false
end
-- Um unico usuario local pode ter no maximo um voto; contagens globais
-- so existirao apos habilitar API remota com deduplicacao de usuarios.
function R.counts(p,cat)
 local vote=R.get(p,cat)
 return {up=vote=="up" and 1 or 0, down=vote=="down" and 1 or 0}
end
function R.set(p,v,cat)
 if not good(p) or (v~=nil and v~="up" and v~="down") then return false,nil end
 if not R.loaded then R.load() end
 local data=R.votes[catalog(cat)]
 local prev=data[p.id]
 if prev==v then v=nil end
 data[p.id]=v
 if not persist() then data[p.id]=prev;return false,prev end
 return true,v
end
return R
