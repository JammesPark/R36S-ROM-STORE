package.path='src/?.lua;'..package.path
local json=require('json')
local yes={
  '{"ports":[]}', '{"a":1,"b":false,"c":null}', '["um","dois"]',
  '{"unicode":"\\u00e1"}', '{"emoji":"\\uD83D\\uDE00"}','-2.5e+4'
}
local no={'{"a":}', '{"a":1 trailing}', '{"x":"\\uD800"}',
          '{"x":01}', '{"x":"unfinished}', '{oops}'}
for _,s in ipairs(yes) do local v,e=json.decode(s);assert(v~=nil,e or s) end
for _,s in ipairs(no) do local v=json.decode(s);assert(v==nil,'Aceitou JSON invalido: '..s) end
print('JSON: '..#yes+#no..' casos')
