-- Regressão: cada item da navegação principal tem símbolo próprio, sem PNG.
package.path='src/?.lua;'..package.path
local events={}
local lastColor=nil
local function log(kind,...)
  local args={...}
  local out={kind}
  for _,v in ipairs(args) do
    if type(v)=='number' then out[#out+1]=string.format('%.2f',v)
    else out[#out+1]=tostring(v) end
  end
  events[#events+1]=table.concat(out,':')
end
love={graphics={
  setColor=function(r,g,b,a) lastColor={r,g,b,a} end,
  setLineWidth=function(w) log('width',w) end,
  line=function(...) log('line',...) end,
  circle=function(...) log('circle',...) end,
  rectangle=function(...) log('rectangle',...) end,
}}
local U=require('ui')
local cases={
  {'home','house'}, {'catalog','library-big'},
  {'downloads','download'}, {'installed','hard-drive'},
  {'favorites','heart'}, {'settings','settings'},
  {'about','info'}, {'exit','log-out'}
}
local shapes={}
local stroke={0.35,0.85,0.45}
for _,item in ipairs(cases) do
  events={}
  local returned=U.menuIcon(item[1],26,120,stroke)
  assert(returned==item[2],item[1]..' não tem o símbolo aprovado')
  assert(lastColor and lastColor[1]==stroke[1] and lastColor[2]==stroke[2],
    'A cor do tema não foi aplicada: '..item[1])
  local meaningful={}
  for _,e in ipairs(events) do
    if not e:match('^width:') then meaningful[#meaningful+1]=e end
  end
  assert(#meaningful>=2,'Ícone ausente/simplificado: '..item[1])
  local signature=table.concat(meaningful,'|')
  assert(not shapes[signature],
    'Ícones indistinguíveis: '..shapes[signature]..' e '..item[1])
  shapes[signature]=item[1]
end
local n=0
for _ in pairs(shapes) do n=n+1 end
assert(n==8,'Devem existir oito desenhos diferentes')
print('MENU INICIAL: 8 ícones únicos, sem PNG e cor do tema preservada: OK')
