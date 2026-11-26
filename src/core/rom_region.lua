-- Region metadata only; never infer language from the title itself.
local R={}
R.alias={
 JP="JP",JAPAN="JP",JAPANESE="JP",J="JP",CN="CN",CH="CN",CHINA="CN",CHINESE="CN",TW="TW",TAIWAN="TW",HK="HK",["HONG KONG"]="HK",
 US="US",USA="US",["UNITED STATES"]="US",U="US",EU="EU",EUROPE="EU",E="EU",BR="BR",BRAZIL="BR",BRASIL="BR",
 KR="KR",KOREA="KR",K="KR",WORLD="WW",WW="WW",W="WW",ASIA="AS",AS="AS",AU="AU",AUSTRALIA="AU",CA="CA",CANADA="CA",
 UK="UK",["UNITED KINGDOM"]="UK",GB="UK",FR="FR",FRANCE="FR",DE="DE",GERMANY="DE",ES="ES",SPAIN="ES",
 IT="IT",ITALY="IT",PT="PT",PORTUGAL="PT",RU="RU",RUSSIA="RU",NL="NL",NETHERLANDS="NL",SE="SE",SWEDEN="SE",MX="MX",MEXICO="MX",
}
function R.token(s)
 if type(s)~="string" then return nil end
 s=s:upper():match("^%s*(.-)%s*$")
 return R.alias[s]
end
function R.metadata(s)
 if type(s)~="string" then return nil end
 for _,pat in ipairs({"%(([^()]*)%)","%[([^%[%]]*)%]"}) do
  for group in s:gmatch(pat) do
   local code=R.token(group)
   if code then return code end
   local codes,seen={},{}
   for part in group:gmatch("[^,]+") do
    local c=R.token(part);if not c then codes={};break end
    if not seen[c] then codes[#codes+1]=c;seen[c]=true end
   end
   if #codes>1 then return "WW" end
  end
 end
end
function R.detect(p)
 local explicit=R.token(p.region_tag) or R.token(p.region) or R.token(p.regiao)
 if explicit then return explicit end
 for _,s in ipairs({p.original_name or "",p.name or "",p.filename or ""}) do
  local c=R.metadata(s);if c then return c end
 end
 local url=p.download_url
 if type(url)=="string" then
  local clean=url:match("^[^?#]*") or ""
  local file=clean:match("/([^/]+)$") or ""
  file=file:gsub("%%(%x%x)",function(h)return string.char(tonumber(h,16))end)
  return R.metadata(file)
 end
end
return R
