package.path='./game/?.lua;./game/?/init.lua;'..package.path
package.loaded['lib.i18n']={L=function(s)return s end}
package.loaded['lib.util']={
 is_dir=function(p) return p=='/roms' or p=='/roms2' or p=='/roms/gba' or p=='/roms2/snes' end,
 exec_ok=function(cmd) return cmd:find('test %-w')~=nil end,
 capture=function(cmd) return '/dev/test 100 0 100 0% /roms' end,
 shq=function(s)return "'"..s.."'" end,
}
package.loaded['core.portstorage']={get=function(card)
  return {available=true,label=card=='sd1' and 'SD1' or 'SD2',root=card=='sd1' and '/roms' or '/roms2',free=123456789}
end}
local r=require('core.romstorage')
assert(r.get('sd1','gba').path=='/roms/gba')
assert(r.get('sd2','snes').path=='/roms2/snes')
assert(r.get('sd1','invalid').available==false)
assert(r.filename({download_url='https://archive.org/download/test/Game%20Name%20%28USA%29.zip'})=='Game Name (USA).zip')
assert(r.filename({download_url='https://a.example/test/%2E%2E%2Fbad.gba'})=='.._bad.gba')
assert(#r.FOLDERS==0) -- mapa, nao array
local c=0 for _ in pairs(r.FOLDERS) do c=c+1 end
assert(c==20, 'expected 20 systems, got '..c)
print('ROM STORAGE PATHS: OK',c,'systems')
