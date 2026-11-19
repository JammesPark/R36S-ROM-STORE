-- Dados reais: Novidades ordenadas por inclusao, Em Breve sem download.
package.path = "game/?.lua;game/?/init.lua;" .. package.path
local Catalog = { ports = {}, news = {} }
package.loaded["core.catalog"] = Catalog
local Feed = require("core.force_feed")
local function port(id,added,url,section)
  return {id=id,name=id,added=added or "",download_url=url or "",
    section=section or "games",builtin=false}
end
Catalog.ports = {
  port("antigo","2026-11-01","https://cdn.example/a.zip"),
  port("amanha","2026-11-16",""),
  port("novissimo","2026-11-17","https://cdn.example/c.7z"),
  port("ferramenta","2026-11-17","https://cdn.example/d.zip","tools"),
  port("semdata","","https://cdn.example/e.zip"),
  port("velho","2026-11-10","https://cdn.example/f.zip"),
  port("outrobreve","2026-11-15",""),
  port("anuncio-sem-data","",""),
}
Catalog.news = { {id="semdata",type="new",date="2026-11-12",text="Anunciado"} }
local res=Feed.build()
assert(#res.novos==4,"Somente jogos com download + data confirmada em Novidades")
assert(res.novos[1].port.id=="novissimo","Mais recente primeiro")
assert(res.novos[2].port.id=="semdata","Suporte a noticias oficiais do catalogo")
assert(res.novos[3].port.id=="velho")
assert(res.novos[4].port.id=="antigo")
assert(#res.breve==3,"Somente jogos sem link em Em Breve")
assert(res.breve[1].port.id=="amanha")
assert(res.breve[2].port.id=="outrobreve")
assert(res.breve[3].port.id=="anuncio-sem-data")
for _,it in ipairs(res.breve) do
  assert(it.port.download_url=="","Em Breve nao pode apontar download")
end
-- Se o catalogo muda, a vitrine reflete apenas a nova fonte.
Catalog.ports = { port("catalogo-lira","2026-11-13","https://cdn.example/l.zip") }
Catalog.news={}
local changed=Feed.build()
assert(#changed.novos==1 and changed.novos[1].port.id=="catalogo-lira")
assert(#changed.breve==0)
print("Force Feed: Novidades/Em Breve reais, datas, filtragem e isolamento de catalogos OK")
