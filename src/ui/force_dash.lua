-- =============================================================================
-- FORCE NEXUS (Jedi/Sith) — reproducao do HTML V4 aprovado, em 640x480.
-- Referencia: NEON_GRID_JEDI/SITH_CONCEITO_V4_640x480.html
-- SEM vitrine "Em destaque": a tela possui somente carrossel vertical real,
-- Top 5 real, 6 atalhos e rodape. Nao altera nenhum outro layout.
-- =============================================================================
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local C=require("config")
local Catalog=require("core.catalog")
local Covers=require("core.covers")
local ForceFeed=require("core.force_feed")
local Icons=require("ui.icons")
local Clock=require("core.clock")
local lg=love.graphics
local M={}
local TEMPLATE={id=nil,image=nil,tiles=nil,quads=nil,stamp=nil}
local function draw_template()
  local Themes=require("core.themes")
  local id=Themes.current
  local theme=Themes.by_id and Themes.by_id[id]
  local path=theme and (theme.dir.."/background_v4.png") or nil
  local tilepath=theme and (theme.dir.."/selected_tiles_v4.png") or nil
  local info=path and love.filesystem.getInfo(path,"file") or nil
  local stamp=info and info.modtime or 0
  if id~=TEMPLATE.id or TEMPLATE.stamp~=stamp then
    if TEMPLATE.image and TEMPLATE.image.release then TEMPLATE.image:release() end
    if TEMPLATE.tiles and TEMPLATE.tiles.release then TEMPLATE.tiles:release() end
    TEMPLATE.id,TEMPLATE.stamp,TEMPLATE.image,TEMPLATE.tiles,TEMPLATE.quads=id,stamp,nil,nil,nil
    if info then
      local ok,img=pcall(lg.newImage,path)
      if ok and img then
        img:setFilter("linear","linear")
        TEMPLATE.image=img
      end
    end
    if tilepath and love.filesystem.getInfo(tilepath,"file") then
      local ok,img=pcall(lg.newImage,tilepath)
      if ok and img and img:getWidth()==405 and img:getHeight()==168 then
        img:setFilter("linear","linear")
        TEMPLATE.tiles=img
        TEMPLATE.quads={}
        for i=1,6 do
          TEMPLATE.quads[i]=lg.newQuad(((i-1)%3)*135,math.floor((i-1)/3)*84,
            135,84,405,168)
        end
      elseif ok and img and img.release then img:release() end
    end
  end
  if TEMPLATE.image then
    lg.setColor(1,1,1,1)
    lg.draw(TEMPLATE.image,0,0)
    return true
  end
  return false
end
local LINK={
  {id="esthemes",label=L("Temas do EmulationStation"),icon="roms_es_monitor"},
  {id="favorites",label=L("Favoritos"),icon="force_star"},
  {id="downloads",label=L("Downloads"),icon="download"},
}
local TILE={}
for _,it in ipairs(require("ui.menu_entries").items()) do
  if it.id~="esthemes" and it.id~="favorites" and it.id~="downloads" then
    TILE[#TILE+1]=it
  end
end

local function hex(s) return T.parse_hex(s) end
local function skin()
  if require("core.themes").current=="forcesith" then
    return {
      name="SITH", bg=hex("#090609"), header=hex("#0F090E"), side1=hex("#42101E"),
      side2=hex("#180810"), side3=hex("#340A1B"), sideedge=hex("#9F2841"),
      rank1=hex("#40101F"), rank2=hex("#160811"), rankedge=hex("#92263D"),
      tile1=hex("#3B1020"), tile2=hex("#1E0A13"), tileedge=hex("#8C2B41"),
      select1=hex("#F5002E"), select2=hex("#B80028"), selectline=hex("#FF6973"),
      glow=hex("#F5002E"), accent=hex("#FF1744"), label=hex("#FF6973"),
      yellow=hex("#FFE0A8"),
      text=hex("#FFF0F1"), subtle=hex("#C09AA4"), faint=hex("#906875"),
      footer=hex("#0D070B"), poster=hex("#230A15"),
      index=hex("#620D24"), shadow=hex("#000000")
    }
  end
  return {
    name="JEDI", bg=hex("#081522"), header=hex("#071827"), side1=hex("#1D3B55"),
    side2=hex("#0D1B2C"), side3=hex("#133049"), sideedge=hex("#386688"),
    rank1=hex("#1B3951"), rank2=hex("#0C1E30"), rankedge=hex("#376D92"),
    tile1=hex("#1C3951"), tile2=hex("#112439"), tileedge=hex("#365E7A"),
    select1=hex("#266DB5"), select2=hex("#214A84"), selectline=hex("#81DFFF"),
    glow=hex("#349FFF"), accent=hex("#5FD0FF"), label=hex("#B0E9FF"),
    yellow=hex("#FFE0A8"),
    text=hex("#F1F9FF"), subtle=hex("#A3C7D8"), faint=hex("#729CAD"),
    footer=hex("#071A2A"), poster=hex("#0C2134"),
    index=hex("#09354C"), shadow=hex("#000000")
  }
end
local FONTS={}
local function font(px,bold)
  local key=(bold and "b" or "r")..px
  if FONTS[key] then return FONTS[key] end
  local path=bold and "assets/fonts/Inter-SemiBold-Cyrillic.otf"
    or "assets/fonts/Inter-Regular-Cyrillic.otf"
  local ok,res=pcall(lg.newFont,path,px)
  if ok and res then
    res:setFilter("linear","linear")
    -- Fallback para glifos ausentes em fontes locais, inclusive PT-BR.
    pcall(function() res:setFallbacks(bold and T.f.bodyb or T.f.body) end)
    FONTS[key]=res
  else
    FONTS[key]=T.text_font(bold and "bodyb" or "body",px)
  end
  return FONTS[key]
end
local function color(c,alpha)
  if alpha then lg.setColor(c[1],c[2],c[3],alpha) else lg.setColor(c) end
end
local function mix(a,b,t)
  return {a[1]*(1-t)+b[1]*t,a[2]*(1-t)+b[2]*t,a[3]*(1-t)+b[3]*t,1}
end
local function gradient(x,y,w,h,one,two,steps)
  steps=steps or 18
  for i=0,steps-1 do
    local yy=y+math.floor(h*i/steps)
    local last=y+math.floor(h*(i+1)/steps)
    G.rect(x,yy,w,last-yy,mix(one,two,(i+.5)/steps))
  end
end
local function panel(x,y,w,h,a,b,edge,selected,P,rad)
  local rr=rad or 9
  G.rect(x+1,y+3,w,h,P.shadow,rr,.35)
  G.rect(x,y,w,h,b,rr)
  -- Gradiente CSS do HTML V4; moldura arredondada e contorno precisos.
  gradient(x+2,y+2,w-4,h-4,a,b,22)
  G.frame(x,y,w,h,selected and P.selectline or edge,rr,selected and 2 or 1)
  if selected then
    for i=3,1,-1 do G.frame(x-i,y-i,w+2*i,h+2*i,P.glow,rr+i,1,.05) end
  end
end
local function txt(s,x,y,px,c,bold,maxw)
  local f=font(px,bold)
  if maxw then G.text_fit(f,s,x,y,maxw,c)
  else G.text(f,s,x,y,c) end
end
local function background(P)
  G.rect(0,0,640,480,P.bg)
  -- Halo radial semelhante ao HTML; baixo custo e sem textura externa.
  for i=12,1,-1 do
    local k=i/12
    color(P.accent,.0065)
    lg.ellipse("fill",552,89,244*k,171*k,28)
    color(P.accent,.0048)
    lg.ellipse("fill",12,408,190*k,153*k,28)
  end
end
local function active_feed(self)
  local source=self.fn_feeds or {}
  return source[self.fn_tab or "novos"] or {}
end
local function choose_feed(self,tab)
  if tab~="novos" and tab~="breve" then return end
  if self.fn_tab~=tab then
    self.fn_tab=tab
    self.fn_i=1
    self.fn_elapsed=0
  end
end
local function recent_move(self,n)
  local items=active_feed(self)
  if #items==0 then return end
  self.fn_i=((self.fn_i or 1)-1+n)%#items+1
  self.fn_elapsed=0
end
function M.update(_,self,dt)
  local source=Catalog.catalog_source()
  if self.dash_dirty or not self.fn_feeds or self.fn_source~=source then
    self.fn_feeds=ForceFeed.build()
    self.fn_tab=self.fn_tab or "novos"
    self.fn_i=math.min(self.fn_i or 1,math.max(#active_feed(self),1))
    self.fn_source=source
    self.dash_dirty=false
    self.fn_elapsed=0
  end
  self.fn_zone=self.fn_zone or "tiles"
  self.fn_tile=self.fn_tile or 1
  self.fn_link=self.fn_link or 1
  self.fn_elapsed=(self.fn_elapsed or 0)+(dt or 0)
  if self.fn_elapsed>=5.5 and #active_feed(self)>1
      and (not App.animations or App.animations()) then
    recent_move(self,1)
  end
end
local function battery(x,y,P)
  local b=require("core.battery").get()
  local fraction=(b and b.ok and tonumber(b.pct)) and math.max(0,math.min(1,b.pct/100)) or .45
  G.frame(x,y,26,12,P.label,3,1)
  G.rect(x+26,y+4,2,4,P.label,1)
  G.rect(x+3,y+3,math.floor(20*fraction),6,P.accent,2)
  if b and b.charging then txt("+",x+7,y-3,10,P.text,true) end
end
local function head(S,self,P,templ)
  -- A logo dos fundos HTML fica gravada na imagem do tema. Refazemos SEMPRE
  -- o cabecalho usando os assets globais, inclusive quando existe template.
  -- Isso elimina o icone antigo dos temas Sith que ainda nao foram atualizados.
  G.rect(0,0,640,46,P.header)
  G.rect(0,45,640,1,P.sideedge)
  local lw=G.logo(14,2,"header",1)
  -- A marca horizontal 3,36:1 e desenhada inteira, incluindo BR/bandeira.
  -- O texto inicia somente apos o comprimento REAL calculado da imagem.
  local tx=math.max(196,14+(lw or 0)+32)
  txt("R36S ROMS STORE",tx,11,10,P.text,true,263)
  local Themes=require("core.themes")
  local def=Themes.by_id and Themes.by_id[Themes.current]
  local version=def and def.version or ""
  txt(P.name.." EDITION · v"..version,tx,27,9,P.label,true,225)
  local clock=Clock.time()
  txt(clock,519,16,11,P.text,true,50)
  local _,c,off=S.wifi_state()
  S.wifi_icon(568,13,c,off)
  battery(601,17,P)
end
local function feed_tabs(self,P)
  -- Exatamente duas abas, no lugar do antigo titulo PORTS RECENTES.
  -- Desenhadas tambem quando o fundo HTML esta ativo para refletir mudanca real.
  for i,it in ipairs({{"novos","NOVOS"},{"breve","EM BREVE"}}) do
    local x,y,w,h=26+(i-1)*83,68,77,18
    local active=self.fn_tab==it[1]
    G.rect(x,y,w,h,active and P.select2 or P.side2,4)
    G.frame(x,y,w,h,active and P.accent or P.sideedge,4,
      self.fn_zone=="tabs" and active and 2 or 1)
    txt(it[2],x+6,y+5,8,active and P.text or P.label,true,w-12)
  end
end
local function recent_slide(self,P)
  local x,y,w,h=26,93,160,200
  G.rect(x,y,w,h,P.poster,8)
  local feed=active_feed(self)
  local item=feed[self.fn_i]
  local p=item and item.port
  G.clip(x+1,y+1,w-2,h-2)
  if p then
    local img=Covers.get(p)
    if img then
      local iw,ih=img:getDimensions()
      local scale=math.max(w/iw,h/ih)
      color(hex("#FFFFFF"))
      lg.draw(img,x+(w-iw*scale)/2,y+(h-ih*scale)/2,0,scale,scale)
    else
      gradient(x,y,w,h,P.side1,P.poster)
      color(P.accent,.16)
      lg.circle("fill",x+w*.86,y+45,55)
      Icons.draw("games",x+55,y+64,P.label,46/24)
    end
    -- REGRA PERMANENTE: sem nome, data, selo 'adicionado ao catalogo' na vitrine.

  else
    gradient(x,y,w,h,P.side1,P.poster)
    if self.fn_tab=="breve" then
      txt("SEM ANÚNCIOS",x+12,y+83,14,P.text,true,139)
      txt("EM BREVE",x+12,y+102,14,P.text,true,139)
      txt("Quando houver ports",x+12,y+159,10,P.subtle,false,139)
      txt("anunciados, aparecerão aqui",x+12,y+173,9,P.subtle,false,139)
    else
      txt("SEM NOVOS",x+12,y+89,14,P.text,true,139)
      txt("Novos ports datados",x+12,y+159,10,P.subtle,false,139)
      txt("aparecerão aqui",x+12,y+173,10,P.subtle,false,139)
    end
  end
  G.unclip()
  G.frame(x,y,w,h,P.accent,8,self.fn_zone=="recent" and 2 or 1)
end
local function force_star(x,y,c)
  -- Estrela vazada sempre, mesmo ao mover o foco sobre Favoritos.
  local v={}
  for i=0,9 do
    local a=-math.pi/2+i*math.pi/5
    local r=(i%2==0) and 7 or 3.1
    v[#v+1]=x+7+math.cos(a)*r
    v[#v+1]=y+7+math.sin(a)*r
  end
  v[#v+1]=v[1];v[#v+1]=v[2]
  color(c)
  lg.setLineWidth(1.2)
  lg.line(v)
  lg.setLineWidth(1)
end
local function shortcuts(self,P,templ)
  -- V6: 9 px acima, espaçamento equilibrado; Downloads termina acima da borda.
  if not templ then txt(L("ATALHOS"),26,325,11,P.text,true) end
  for i,it in ipairs(LINK) do
    local x,y,w,h=26,346+(i-1)*27,160,23
    local on=self.fn_zone=="links" and self.fn_link==i
    if on then G.rect(x,y,w,h,P.rank1,5);G.frame(x,y,w,h,P.accent,5,1) end
    if on or not templ then
      if it.id=="favorites" then force_star(x+6,y+4,P.accent)
      else Icons.draw(it.icon,x+6,y+4,P.accent,15/24) end
      txt(it.label,x+32,y+5,10,on and P.text or P.subtle,true,123)
    end
  end
end
local function left(self,P,templ)
  if not templ then
    panel(14,54,182,382,P.side1,P.side2,P.sideedge,false,P,12)
  end
  feed_tabs(self,P)
  recent_slide(self,P)
  local len=#active_feed(self)
  local dots=math.min(6,len)
  if dots>0 then
    -- Indicadores centralizados, sem contador numerico; ativo mais comprido.
    local width=dots*10+12+(dots-1)*5
    local x=26+math.floor((160-width)/2)
    for i=1,dots do
      local active=i==self.fn_i
      local bar_w=active and 22 or 10
      G.rect(x,312,bar_w,4,active and P.accent or P.faint,3)
      x=x+bar_w+5
    end
  end
  -- Sem botoes laterais visuais; L1/R1 continua funcionando.
  shortcuts(self,P,templ)
end
local function wrap_text(text,font_,width,maxlines)
  local _,lines=font_:getWrap(tostring(text or ""),width)
  local out={}
  for i=1,math.min(maxlines,#lines) do out[i]=lines[i] end
  return out
end
local function cover(p,x,y,w,h,P)
  if not p then
    gradient(x,y,w,h,P.side1,P.poster)
    txt("—",x+27,y+28,20,P.faint,true)
    return
  end
  local image=Covers.get(p)
  if image then
    local iw,ih=image:getDimensions()
    local scale=math.max(w/iw,h/ih)
    G.clip(x,y,w,h)
    color(hex("#FFFFFF"))
    lg.draw(image,x+(w-iw*scale)/2,y+(h-ih*scale)/2,0,scale,scale)
    G.unclip()
  else
    gradient(x,y,w,h,P.side1,P.poster)
    Icons.draw("games",x+18,y+24,P.label,40/24)
  end
end
local function tiles(self,P,templ)
  local page=math.floor((math.max(1,self.fn_tile or 1)-1)/6)
  local first=page*6+1
  for i=first,math.min(#TILE,first+5) do
    local item=TILE[i]
    local slot=i-first
    local col=slot%3
    local row=math.floor(slot/3)
    local x,y=208+col*141,58+row*90
    local selected=self.fn_zone=="tiles" and self.fn_tile==i
    -- As imagens do template original tinham os seis menus antigos.
    -- Redesenhar somente os seis cartoes evita nomes duplicados no fundo.
    panel(x,y,135,84, selected and P.select1 or P.tile1,
      selected and P.select2 or P.tile2,P.tileedge,selected,P,8)
    Icons.draw(item.icon,x+11,y+12,selected and P.text or P.label,1)
    txt("↗",x+112,y+7,13,selected and P.label or P.faint,true,20)
    local upper=string.upper(tostring(item.label))
    local f=font(11,true)
    local rows=wrap_text(upper,f,108,2)
    for k=1,#rows do
      G.text_fit(f,rows[k],x+11,y+84-12*#rows-10+(k-1)*12,110,P.text)
    end
  end
  if #TILE>6 then
    txt(string.format("%d/%d",page+1,math.ceil(#TILE/6)),585,40,10,P.faint,true,45)
  end
end

local function footer(P,templ)
  if templ then return end
  G.rect(0,446,640,34,P.footer)
  G.rect(0,446,640,1,P.sideedge)
  local segments={
    {x=18,w=18,key="A",text=L("Selecionar")},
    {x=107,w=32,key="← →",text=L("Carrossel")},
    {x=204,w=34,key="L1/R1",text=L("Navegar")},
  }
  for _,b in ipairs(segments) do
    G.rect(b.x,457,b.w,17,P.accent,3)
    G.frame(b.x,457,b.w,17,P.label,3,1)
    txt(b.key,b.x+3,459,9,P.text,true,b.w-4)
    txt(b.text,b.x+b.w+6,460,10,P.subtle,false)
  end
  txt(P.name.." · R36S ROMS STORE",474,460,9,P.faint,false,160)
end
function M.draw(S,self)
  M.update(S,self,0)
  local P=skin()
  -- O PNG e construido diretamente do HTML V4 do usuario; nunca contem nomes,
  -- capas ou contadores ficticios. Dados reais sao desenhados por cima.
  local templ=draw_template()
  if not templ then background(P) end
  head(S,self,P,templ)
  left(self,P,templ)
  tiles(self,P,templ)
  footer(P,templ)
end
local function show_recent(self)
  local item=active_feed(self)[self.fn_i]
  if item and item.port then
    App.push("details",{port=item.port})
  else
    App.toast(self.fn_tab=="breve" and
      "Ainda não existem ports anunciados." or
      "Nenhum port novo com data cadastrada.", "info")
  end
end
function M.action(S,self,act)
  M.update(S,self,0)
  if act=="b" then
    if require("core.prefs").get("exit_mode")=="quit" and not C.OS_MODE then App.quit()
    else S.exit_dialog() end
    return
  elseif act=="select" and require("core.updnotice").pending() then App.push("update");return
  elseif act=="y" then App.push("search");return
  elseif act=="x" then
    choose_feed(self,self.fn_tab=="novos" and "breve" or "novos")
    self.fn_zone="tabs"
    return
  elseif act=="l1" or act=="r1" then
    -- L1/R1: deslocar itens do carrossel ativo (Novidades ou Em Breve).
    recent_move(self,act=="r1" and 1 or -1)
    self.fn_zone="recent"
    return
  end
  local z=self.fn_zone
  if act=="a" then
    if z=="tabs" then
      choose_feed(self,self.fn_tab=="novos" and "breve" or "novos")
    elseif z=="recent" then show_recent(self)
    elseif z=="links" then S.open(LINK[self.fn_link].id)
    else S.open(TILE[self.fn_tile].id) end
    return
  end
  if z=="tabs" then
    if act=="left" then choose_feed(self,"novos")
    elseif act=="right" then choose_feed(self,"breve")
    elseif act=="down" then self.fn_zone="recent"
    elseif act=="up" then self.fn_zone="tiles";self.fn_tile=1 end
  elseif z=="tiles" then
    local i=self.fn_tile
    local slot=(i-1)%6
    local col=slot%3
    local row=math.floor(slot/3)
    if act=="left" then
      if col>0 then self.fn_tile=i-1 else self.fn_zone="links" end
    elseif act=="right" then
      if col<2 and i<#TILE then self.fn_tile=i+1 end
    elseif act=="up" then
      if row==1 then self.fn_tile=i-3
      elseif i>6 then self.fn_tile=i-6 end
    elseif act=="down" then
      if i+3<=#TILE then self.fn_tile=i+3
      else self.fn_zone="links";self.fn_link=1 end
    end
  elseif z=="recent" then
    if act=="left" then recent_move(self,-1)
    elseif act=="right" then recent_move(self,1)
    elseif act=="down" then self.fn_zone="links"
    elseif act=="up" then self.fn_zone="tabs" end
  elseif z=="links" then
    if act=="up" then
      if self.fn_link>1 then self.fn_link=self.fn_link-1 else self.fn_zone="recent" end
    elseif act=="down" then self.fn_link=math.min(#LINK,self.fn_link+1)
    elseif act=="right" then self.fn_zone="tiles";self.fn_tile=4 end
  end
end
return M
