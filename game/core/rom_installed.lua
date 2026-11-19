-- Registro persistente apenas de ROMs que esta loja instalou com sucesso.
-- Os caminhos sao verificados antes de listar para evitar falsos "Instalados".
local json=require("lib.json")
local U=require("lib.util")
local M={}
local FILE="roms_installed.json"

local function records()
  local ok,text=pcall(love.filesystem.read,FILE)
  if not ok or not text then return {} end
  local ok2,data=pcall(json.decode,text)
  return ok2 and type(data)=="table" and data or {}
end

local function safe_entry(name)
  return type(name)=="string" and name~="" and name~="." and name~=".."
    and not name:find("/") and not name:find("\\") and not name:find("%c")
end

local function is_present(rec)
  if type(rec.dest_dir)~="string" or type(rec.system)~="string"
      or type(rec.entries)~="table" or #rec.entries==0 then return false end
  local Storage=require("core.romstorage")
  local ok=Storage.validate(rec.dest_dir,rec.system)
  if not ok then return false end
  for _,entry in ipairs(rec.entries) do
    if not safe_entry(entry) or not U.exists(rec.dest_dir.."/"..entry) then return false end
  end
  return true
end

function M.record(p,opts,entries)
  if not p or p.builtin or p.section~="games" or not p.id or not opts
      or opts.mode~="rom" or not entries or #entries==0 then return false end
  local rec={id=p.id,name=p.name,system=p.category_id,category_id=p.category_id,category=p.category,
    cover=p.cover,download_url=p.download_url,description=p.description,short=p.short,
    size=p.size,size_label=p.size_label,date=os.date("%Y-%m-%d %H:%M"),
    dest_dir=opts.dest_dir,entries=entries,
    card=opts.dest_dir:sub(1,7)=="/roms2/" and "SD2" or "SD1"}
  if not is_present(rec) then return false end
  -- Inventario apenas dos arquivos colocados pela loja. Pastas de jogos podem
  -- receber saves depois: nunca apagar arquivos nao registrados.
  local files={}
  local function relative_ok(rel)
    return type(rel)=="string" and #rel>0 and #rel<=2048 and rel:sub(1,1)~="/"
      and not rel:find("\\") and not rel:find("%c")
      and not rel:find("//",1,true) and not rel:find("^%.%./")
      and not rel:find("/%.%./") and not rel:find("/%.%.$")
      and not rel:find("^%./") and rel~="." and rel~=".."
  end
  for _,entry in ipairs(entries) do
    if not safe_entry(entry) then return false end
    local full=rec.dest_dir.."/"..entry
    if U.exec_ok("test -L "..U.shq(full)) then return false end
    if U.is_dir(full) then
      -- find (sem -L) nao percorre symlinks; usar -print compativel com BusyBox.
      local output=U.capture("find "..U.shq(full).." -type f -print 2>/dev/null")
      if not output or U.exec_ok("find "..U.shq(full).." -type l -print | grep -q .") then return false end
      for name in output:gmatch("[^\n]+") do
        if name:sub(1,#full+1)~=full.."/" then return false end
        local rel=entry.."/"..name:sub(#full+2)
        if not relative_ok(rel) then return false end
        files[#files+1]=rel
        if #files>30000 then return false end
      end
    elseif U.exists(full) then
      files[#files+1]=entry
    else return false end
  end
  if #files==0 then return false end
  rec.files=files
  local data=records()
  data[tostring(p.id)]=rec
  local ok,written=pcall(love.filesystem.write,FILE,json.encode(data))
  return ok and written==true
end

function M.on_card(p, dest)
  local rec=records()[tostring(p.id)]
  return type(rec)=="table" and rec.dest_dir==dest and is_present(rec)
end

function M.list(catalog)
  local out={}
  for id,rec in pairs(records()) do
    if type(rec)=="table" and type(rec.name)=="string" and rec.name~="" and is_present(rec) then
      local base=catalog.by_id[id]
      local p={}
      if base then for k,v in pairs(base) do p[k]=v end end
      if not base then
        p={id=id,name=rec.name,slug=id,category_id=rec.category_id or "roms",
          category=rec.category or rec.category_id or "ROMs",section="games",
          cover=rec.cover or "",download_url=rec.download_url or "",
          description=rec.description or "",short=rec.short or "",
          size=rec.size,size_label=rec.size_label or "?",version=""}
      end
      p.rom_download_card=rec.card
      p.rom_download_date=rec.date
      p.rom_install_dir=rec.dest_dir
      out[#out+1]=p
    end
  end
  table.sort(out,function(a,b) return (a.rom_download_date or "")>(b.rom_download_date or "") end)
  return out
end

-- Um jogo pode estar instalado sem ter .sh; o registro de ROM e a fonte correta
-- para habilitar o botao de remover nas telas de detalhes e Instalados.
function M.get(p)
  local id=type(p)=="table" and p.id or p
  if id==nil then return nil end
  local rec=records()[tostring(id)]
  if type(rec)=="table" and is_present(rec) then return rec end
  return nil
end

local function rel_ok(rel)
  if type(rel)~="string" or #rel==0 or #rel>2048 or rel:sub(1,1)=="/"
      or rel:find("\\") or rel:find("%c") or rel:find("//",1,true) then return false end
  for part in rel:gmatch("[^/]+") do
    if part=="." or part==".." or part=="" then return false end
  end
  return true
end

-- Exclui SOMENTE arquivos registrados em roms_installed.json. Nao utiliza o
-- desinstalador de ports e nao executa 'rm -rf'. Diretorios sao removidos apenas
-- se ficarem vazios, preservando saves e qualquer arquivo adicionado depois.
function M.remove(p)
  local id=type(p)=="table" and p.id or p
  local data=records()
  local rec=id and data[tostring(id)]
  if type(rec)~="table" or not is_present(rec) then
    return false,"Instalacao da ROM nao encontrada neste cartao. Nada foi apagado."
  end
  local Storage=require("core.romstorage")
  local valid,info=Storage.validate(rec.dest_dir,rec.system)
  if not valid then return false,"Destino inseguro ou indisponivel: "..tostring(info) end
  local files=rec.files
  -- Registro antigo: arquivo unico pode ser removido; nao deduzir o conteudo
  -- de pastas antigas sem inventario de arquivos da instalacao.
  if type(files)~="table" or #files==0 then
    files={}
    for _,entry in ipairs(rec.entries) do
      if not safe_entry(entry) then return false,"Entrada invalida no registro." end
      if U.is_dir(rec.dest_dir.."/"..entry) then
        return false,"Instalacao antiga com varios arquivos sem inventario. Nenhum arquivo foi apagado."
      end
      files[#files+1]=entry
    end
  end
  if #files>30000 then return false,"Registro muito grande. Nada foi apagado." end
  local seen,dirs={},{}
  for _,rel in ipairs(files) do
    if not rel_ok(rel) or seen[rel] then return false,"Registro invalido. Nada foi apagado." end
    seen[rel]=true
    local base=rec.dest_dir
    local walk=""
    for part in rel:gmatch("[^/]+") do
      walk=walk.."/"..part
      local absolute=base..walk
      if U.exec_ok("test -L "..U.shq(absolute)) then
        return false,"Link simbolico encontrado. Nada foi apagado: "..rel
      end
    end
    local full=base.."/"..rel
    if not U.exec_ok("test -f "..U.shq(full)) then
      return false,"Arquivo nao localizado ou nao e arquivo comum: "..rel
    end
    local parent=rel:match("^(.*)/[^/]+$")
    while parent do
      dirs[parent]=true
      parent=parent:match("^(.*)/[^/]+$")
    end
  end
  -- Confirmar que nenhuma outra instalacao depende dos mesmos arquivos.
  for other_id,other in pairs(data) do
    if tostring(other_id)~=tostring(id) and type(other)=="table" and other.dest_dir==rec.dest_dir then
      for _,e in ipairs(other.entries or {}) do
        for _,rel in ipairs(files) do
          if rel==e or rel:sub(1,#e+1)==e.."/" then
            return false,"Arquivo compartilhado com outra ROM. Nada foi apagado."
          end
        end
      end
    end
  end
  -- Sem sobrescrita ou remocao recursiva: cada arquivo foi identificado acima.
  for _,rel in ipairs(files) do
    local ok,why=os.remove(rec.dest_dir.."/"..rel)
    if not ok then return false,"Falha ao remover "..rel..": "..tostring(why) end
  end
  local dirs_sorted={}
  for d in pairs(dirs) do dirs_sorted[#dirs_sorted+1]=d end
  table.sort(dirs_sorted,function(a,b) return #a>#b end)
  for _,d in ipairs(dirs_sorted) do os.remove(rec.dest_dir.."/"..d) end -- so vazias
  data[tostring(id)]=nil
  local ok,saved=pcall(love.filesystem.write,FILE,json.encode(data))
  if not ok or not saved then return false,"Arquivos removidos, mas falhou a atualizacao do registro." end
  return true,#files
end

return M
