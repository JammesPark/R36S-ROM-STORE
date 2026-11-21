-- Configuracoes > Temas. Temas integrados e baixados, com rolagem segura.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local U=require("lib.util")
local Themes=require("core.themes")
local lg=love.graphics
local S={}
local RH, GAP, TOP, VISIBLE=58,6,50,5

function S:enter()
  Themes.scan()
  -- Edicao Experimental: apenas Neon e Padrao, sem acesso a catalogo de
  -- temas descontinuados. Os arquivos antigos do usuario nao sao apagados.
  self.items={}
  for _,th in ipairs(Themes.list) do self.items[#self.items+1]={theme=th} end
  self.sel=1
  self.scroll=0
  self.preview,self.preview_for=nil,nil
end
function S:resume() self:enter() end
function S:leave() self:release_preview() end
function S:release_preview()
  if self.preview and self.preview.release then self.preview:release() end
  self.preview,self.preview_for=nil,nil
end
function S:get_preview(th)
  if not th or not th.preview then return nil end
  if self.preview_for~=th.id then
    self:release_preview(); self.preview_for=th.id
    local ok,img=pcall(lg.newImage,th.preview)
    if ok and img then self.preview=img; img:setFilter("linear","linear") end
  end
  return self.preview
end
local function clamp_scroll(self)
  self.scroll=U.clamp(self.scroll or 0,0,math.max(0,#self.items-VISIBLE))
  if self.sel<=self.scroll then self.scroll=self.sel-1 end
  if self.sel>self.scroll+VISIBLE then self.scroll=self.sel-VISIBLE end
end
function S:draw()
  clamp_scroll(self)
  local cur=Themes.by_id and Themes.by_id[Themes.current]
  G.header(L("Temas"),L("Atual: ")..(cur and L(cur.name) or L("Tema Padrão")))
  local lx,lw=12,250
  for i=self.scroll+1,math.min(#self.items,self.scroll+VISIBLE) do
    local it=self.items[i]
    local y=TOP+(i-self.scroll-1)*(RH+GAP)
    local on=i==self.sel
    G.panel(lx,y,lw,RH,{bg=on and T.c.bg3 or T.c.bg1,border=on and T.c.accent or T.c.line,lw=on and 2 or 1})
    if on then G.rect(lx,y+8,4,RH-16,T.c.accent,2) end
    if it.theme then
      local th=it.theme
      for k,key in ipairs({"bg0","bg1","accent","accent2"}) do
        local c=th.colors[key]
        lg.setColor(c[1],c[2],c[3],1)
        lg.rectangle("fill",lx+14+(k-1)*9,y+14,8,30)
      end
      G.text_fit(T.f.bodyb,U.upper(th.name),lx+56,y+9,lw-70,on and T.c.text or T.c.dim)
      local sub=th.builtin and L("Incluso no app") or L("Instalado")
      if th.version~="" then sub=sub.."  •  v"..th.version end
      -- O selo EM USO ocupa a direita da segunda linha. Reservar a largura
      -- antes de escrever "Incluso/Instalado • versão" para impedir sobreposicao.
      local active=th.id==Themes.current
      local sub_w=active and lw-134 or lw-66
      G.text_fit(T.f.small,sub,lx+56,y+31,sub_w,T.c.faint)
      if active then G.tag(L("EM USO"),lx+lw-70,y+32,T.c.green,T.c.bg0,T.f.pix8) end
    else
      G.text_fit(T.f.bodyb,L("BAIXAR NOVOS TEMAS"),lx+16,y+10,lw-28,on and T.c.text or T.c.dim)
      G.text_fit(T.f.small,L("Catálogo online e atualização"),lx+16,y+32,lw-28,T.c.faint)
    end
  end
  local px,py,pw,ph=274,50,T.W-286,390
  G.panel(px,py,pw,ph,{bg=T.c.bg1})
  local it=self.items[self.sel]
  if it and it.theme then
    local th=it.theme
    local img=self:get_preview(th)
    local iw,ih=pw-24,math.floor((pw-24)*3/4)
    if img then
      lg.setColor(1,1,1,1);lg.draw(img,px+12,py+12,0,iw/img:getWidth(),ih/img:getHeight())
      G.frame(px+12,py+12,iw,ih,T.c.line,0)
    else
      G.rect(px+12,py+12,iw,ih,T.c.bg0,4)
      G.text(T.f.small,L("Sem pré-visualização"),px+12,py+12+ih/2-6,T.c.faint,"center",iw)
    end
    local y=py+24+ih
    G.text_fit(T.f.h3,L(th.name),px+14,y,pw-28,T.c.text)
    y=y+24
    -- Proteger o rodape do painel: tema ativo exibe TEMA EM USO,
    -- que nao pode receber texto da descricao por baixo.
    local active=th.id==Themes.current
    local desc_bottom=py+ph-(active and 42 or 16)
    local avail=math.max(0,desc_bottom-y)
    if avail>0 then
      local df,dl=G.fit_lines(T.f.small,L(th.description),pw-28,avail,true)
      G.clip(px+14,y,pw-28,avail)
      local step=G.step(df,15)
      for _,line in ipairs(dl) do
        if y+df:getHeight()>desc_bottom then break end
        G.text(df,line,px+14,y,T.c.dim)
        y=y+step
      end
      G.unclip()
    end
    if active then G.text(T.f.pix8,L("TEMA EM USO"),px+14,py+ph-22,T.c.green) end
  elseif it then
    G.text(T.f.pix16,L("NOVOS TEMAS"),px,py+105,T.c.accent2,"center",pw)
    G.text(T.f.body,L("Baixe, atualize ou remova temas visuais da STORE pelo catálogo oficial."),
      px+22,py+150,T.c.dim,"center",pw-44)
    G.text(T.f.small,L("Temas integrados são preservados."),px+22,py+270,T.c.green,"center",pw-44)
  end
  if #self.items>VISIBLE then
    G.text(T.f.small,string.format("%d/%d",self.sel,#self.items),lx+8,TOP+VISIBLE*(RH+GAP)+2,T.c.faint)
  end
  local hints={{"dpad",L("Escolher")}}
  if it and it.theme and it.theme.id~=Themes.current then hints[#hints+1]={"a",L("Aplicar tema")} end
  hints[#hints+1]={"b",L("Voltar")};G.hints(hints)
end
function S:action(act)
  local n=#self.items
  if n == 0 then if act == "b" then App.pop() end; return end
  if act=="up" then self.sel=(self.sel-2)%n+1
  elseif act=="down" then self.sel=self.sel%n+1
  elseif act=="b" then App.pop()
  elseif act=="a" then
    local it=self.items[self.sel]
     if it.theme.id==Themes.current then App.toast("Este tema já está em uso.","info");return end
    local ok,why=Themes.apply(it.theme.id,true)
    if ok then App.toast(it.theme.name.." aplicado.","ok")
    else App.toast("Não foi possível aplicar o tema: "..tostring(why),"error") end
  end
  clamp_scroll(self)
end
return S
