-- Pure catalog presentation rules, independent of UI and OS detection.
local M={}
function M.key(th)
  local url=type(th.project_url)=="string" and th.project_url or ""
  local a,b=url:match("^https://github%.com/([%w_.%-]+)/([%w_.%-]+)")
  return a and (a.."/"..b:gsub("%.git$","")):lower() or tostring(th.id)
end
function M.status(th,os,size)
  local r=(th.res or {})[size]
  local st=(th.compat or {})[os or ""]
  if r=="no" or st=="incompativel" or st=="incompatible" or st=="no" then return "incompatible" end
  if st=="testado" or st=="compativel" then
    return r=="yes" and st or "experimental"
  end
  return st=="experimental" and "experimental" or "unknown"
end
function M.can_install(th,os,size)
  local st=(th.compat or {})[os or ""]
  local link=th.download_audit
  if link and link.url==th.download_url and (link.status=="missing" or link.status=="not_zip") then return false end
  if not os or type(th.download_url)~="string" or not th.download_url:match("^https?://") then return false end
  if M.status(th,os,size)=="incompatible" then return false end
  return st==nil or st=="unknown" or st=="untested" or st=="testado" or st=="compativel" or st=="experimental"
end
function M.needs_confirmation(th,os,size)
  return M.status(th,os,size)=="unknown"
end
function M.merge_extra(list,extra)
  local keys,ids={},{}
  for _,th in ipairs(list) do keys[M.key(th)]=th; ids[th.id]=true end
  for _,g in ipairs(extra or {}) do
    local key=M.key(g)
    local th=keys[key]
    if th then
      if type(g.previews)=="table" and #g.previews>0 then
        th.previews=g.previews
        th.cover=g.previews[1]
        th.preview=g.previews[1]
      end
      th.gallery_size=g.size_label
      th.gallery_category=g.category
      th.gallery_source=true
    elseif key and key:match("^[%w_.%-]+/[%w_.%-]+$") then
      local id="tg-"..key:gsub("/","--")
      if not ids[id] then
        th={id=id,slug="estheme-"..id,name=g.name,author=g.author,project_url=g.project_url,
          download_url=g.download_url,folder=g.folder,compat={},res={},cover=(g.previews or {})[1] or "",
          preview=(g.previews or {})[1],previews=g.previews,src="themegallery",
          gallery_size=g.size_label,gallery_category=g.category,gallery_source=true,
          description="ThemeGallery — "..g.category..". Compatibilidade não verificada."}
        list[#list+1]=th;keys[key]=th;ids[id]=true
      end
    end
  end
  return list
end
-- Preserve local ThemeGallery screenshots; verified upstream URLs for other sources.
function M.apply_previews(themes,index)
  for _,th in ipairs(themes) do
    local p=index[M.key(th)]
    if p and type(p.url)=="string" and p.url:match("^https://") and not th.gallery_source then
      th.cover=p.url;th.preview=p.url;th.previews=p.previews
    end
    if p and type(p.download)=="table" then
      th.download_audit=p.download
    end
  end
end
function M.select(themes,opts)
  local out={}
  local q=(opts.query or ""):lower()
  for _,th in ipairs(themes) do
    local st=M.status(th,opts.os,opts.size)
    local mode=opts.mode
    local include=mode=="all" or mode=="compat" and (st=="testado" or st=="compativel")
      or mode=="recent" and type(th.updated)=="string" and th.updated~=""
      or mode=="favorites" and opts.favorites[M.key(th)]
      or mode=="installed" and opts.installed(th)
      or mode=="updates" and opts.has_update and opts.has_update(th)
    local f=opts.secondary or "all"
    local secondary=f=="all" or f=="experimental" and st=="experimental"
      or f=="unknown" and st=="unknown" or f=="incompatible" and st=="incompatible"
      or f=="collections" and th.collection or f=="popular" and tonumber(th.popularity)
      or f=="light" and th.weight=="leve" or f=="full" and th.weight=="completo"
    if include and secondary and (q=="" or th.name:lower():find(q,1,true)) then out[#out+1]=th end
  end
  table.sort(out,function(a,b)
    if opts.mode=="recent" and a.updated~=b.updated then return a.updated>b.updated end
    if opts.secondary=="popular" and a.popularity~=b.popularity then return tonumber(a.popularity)>tonumber(b.popularity) end
    if opts.sort=="za" then return a.name:lower()>b.name:lower() end
    return a.name:lower()<b.name:lower()
  end)
  return out
end
return M
