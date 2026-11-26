package.path='./src/?.lua;'..package.path
package.loaded['lib.i18n']={L=function(s)return s end}
local C=require('config')
local official = os.getenv('STORE_CHANNEL') == 'official'
assert(C.APP_NAME=='R36S ROM STORE' and C.EXPERIMENTAL_NO_OTA == (not official))
assert(C.OWN_CATALOG_URL:match('R36S%-ROM%-STORE%-UPDATES/catalogo%-estavel/'))
assert(C.UPDATE_URL:match('R36S%-ROM%-STORE%-UPDATES/main/ota/rom%-store/update%.json$'))
package.loaded['lib.util']={read_file=function() assert(official); return nil end}
package.loaded['core.fetcher']={}
local U=require('core.update')
if official then assert(U.source_url() == C.UPDATE_URL) else assert(U.source_url() == nil) end
print('PASS catalog and OTA channel')
