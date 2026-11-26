-- Catalogo online dos temas visuais da STORE (nao e o ThemeMaster).
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local U=require("lib.util")
local M=require("core.theme_store")
local Themes=require("core.themes")
local Fetcher=require("core.fetcher")
local C=require("config")
local lg=love.graphics
local S={}
-- Tela logica 640x480: header 0-41, subtitulo 46-60, lista e preview
-- 70-390, avisos 402-443 e dicas de botoes a partir de 448.
-- Essas zonas sao fixas em TODOS os temas (inclusive tamanho de texto grande).
local ROW_H,TOP,VIS=65,70,5
local CONTENT_BOTTOM=390
local STATUS_TOP=402

function S:enter()
  self.sel,self.scroll=1,0
  self.msg=nil
  self.preview,self.preview_id,self.preview_wait=nil,nil,nil
  M.refresh(function(ok,err)
    if not ok then self.msg=tostring(err or "Falha de rede; exibindo cache se existir") end
  end)
end
function S:leave()
  if self.preview and self.preview.release then self.preview:release() end
  self.preview=nil
end
function S:preview_image(item)
  if self.preview_id~=item.id then
    if self.preview and self.preview.release then self.preview:release() end
    self.preview,self.preview_id,self.preview_wait=nil,item.id,nil
  end
  if self.preview then return self.preview end
  local local_th=Themes.by_id and Themes.by_id[item.id]
  if local_th and local_th.preview then
    local ok,img=pcall(lg.newImage,local_th.preview)
    if ok and img then self.preview=img;img:setFilter("linear","linear") end
  end
  if not self.preview and item.preview_url and not self.preview_wait then
    self.preview_wait=item.id
    Fetcher.get("theme_preview",item.preview_url,C.TMP_DIR.."/theme_preview.png",function(ok,path)
      if self.preview_id~=item.id then if path then os.remove(path) end;return end
      local data=ok and path and U.read_file(path) or nil
      if path then os.remove(path) end
      if data and #data<=2097152 then
        local fine,fd=pcall(love.filesystem.newFileData,data,"theme_preview.png")
        if fine and fd then
          local loaded,img=pcall(lg.newImage,fd)
          if loaded and img then self.preview=img;img:setFilter("linear","linear") end
        end
      end
    end)
  end
  return self.preview
end
local function label(status)
  return ({included="INCLUSO",installed="INSTALADO",update="ATUALIZAR",available="DISPONÍVEL"})[status] or status
end
function S:draw()
  local items=M.items
  self.sel=U.clamp(self.sel,1,math.max(1,#items))
  self.scroll=U.clamp(self.scroll,0,math.max(0,#items-VIS))
  if self.sel<=self.scroll then self.scroll=self.sel-1 end
  if self.sel>self.scroll+VIS then self.scroll=self.sel-VIS end
  G.header("Baixar Temas",M.source=="online" and "CATÁLOGO ONLINE" or "CATÁLOGO EM CACHE")
  -- O subtitulo nao pode ficar em y=34: a faixa de cabecalho acaba em 40.
  G.text_fit(T.f.small,"Temas exclusivos da R36S ROM STORE",16,47,T.W-32,T.c.dim)
  local lx,lw=12,260
  if #items==0 then
    G.panel(lx,TOP,lw,CONTENT_BOTTOM-TOP,{bg=T.c.bg1})
    G.text(T.f.bodyb,M.state=="loading" and "Carregando catálogo..." or "Nenhum tema disponível",
      lx+16,TOP+120,T.c.dim,"center",lw-32)
  else
    for i=self.scroll+1,math.min(#items,self.scroll+VIS) do
      local p=items[i]
      local y=TOP+(i-self.scroll-1)*ROW_H
      local on=i==self.sel
      local st=M.status(p)
      G.panel(lx,y,lw,ROW_H-6,{bg=on and T.c.bg3 or T.c.bg1,
        border=on and T.c.accent or T.c.line,lw=on and 2 or 1})
      G.text_fit(T.f.bodyb,U.upper(p.name),lx+12,y+7,lw-24,on and T.c.text or T.c.dim)
      G.text_fit(T.f.small,"v"..p.version.."  •  "..label(st),lx+12,y+26,lw-24,
        st=="update" and T.c.yellow or st=="available" and T.c.accent2 or T.c.green)
      G.text_fit(T.f.small,p.author or "",lx+12,y+44,lw-24,T.c.faint)
    end
  end
  local px,py,pw,ph=284,TOP,T.W-296,CONTENT_BOTTOM-TOP
  G.panel(px,py,pw,ph,{bg=T.c.bg1})
  local item=items[self.sel]
  if item then
    local img=self:preview_image(item)
    -- Reduzir a previa a 280x210: o tamanho 320x240 ocupava quase todo
    -- o painel e empurrava nome/descricao para o rodape.
    local iw=math.min(pw-32,280)
    local ih=math.floor(iw*3/4)
    local ix=px+math.floor((pw-iw)/2)
    local iy=py+12
    if img then
      lg.setColor(1,1,1,1)
      lg.draw(img,ix,iy,0,iw/img:getWidth(),ih/img:getHeight())
    else
      G.rect(ix,iy,iw,ih,T.c.bg0,5)
      G.text(T.f.bodyb,"640 x 480",ix,iy+ih/2-8,T.c.accent,"center",iw)
    end
    local title_y=iy+ih+12
    G.text_fit(T.f.h3,item.name,px+12,title_y,pw-24,T.c.text)
    local desc_y=title_y+24
    local desc_bottom=py+ph-12
    local avail=math.max(0,desc_bottom-desc_y)
    if avail>0 then
      local f,ls=G.fit_lines(T.f.small,item.description or "",pw-24,avail,true)
      G.clip(px+12,desc_y,pw-24,avail)
      local step=G.step(f,15)
      for _,line in ipairs(ls) do
        if desc_y+f:getHeight()>desc_bottom then break end
        G.text(f,line,px+12,desc_y,T.c.dim)
        desc_y=desc_y+step
      end
      G.unclip()
    end
  end
  local j=M.job
  if j and not j.finished then
    G.panel(12,STATUS_TOP,T.W-24,41,{bg=T.c.bg2,border=T.c.accent})
    G.text_fit(T.f.small,"Tema: "..j.name.." • "..j.phase,24,STATUS_TOP+8,T.W-48,T.c.text)
    if j.phase=="download" and j.total>0 then
      G.progress(24,STATUS_TOP+29,T.W-48,6,math.min(1,j.done/j.total),T.c.accent)
    else G.progress_busy(24,STATUS_TOP+29,T.W-48,6,App.t,T.c.accent) end
  elseif j and j.finished and j.status=="error" then
    G.text_fit(T.f.small,"Erro: "..tostring(j.error),14,STATUS_TOP+8,T.W-28,T.c.red)
  elseif self.msg then
    G.text_fit(T.f.small,self.msg,14,STATUS_TOP+8,T.W-28,T.c.yellow)
  end
  -- Rodape de 640 px: labels curtos e nunca mais de cinco dicas.
  -- Em download a acao Cancelar substitui Remover, evitando textos fora da tela.
  local st=item and M.status(item) or nil
  local button=st=="available" and "Instalar"
    or st=="update" and "Atualizar" or (item and "Aplicar" or "Selecionar")
  local hints={{"dpad","Escolher"},{"a",button},{"y","Recarregar"},{"b","Voltar"}}
  if j and not j.finished then
    hints[#hints+1]={"select","Cancelar"}
  elseif st=="installed" then
    hints[#hints+1]={"x","Remover"}
  end
  G.hints(hints)
end
function S:action(act)
  local items=M.items
  if act=="up" and #items>0 then self.sel=(self.sel-2)%#items+1
  elseif act=="down" and #items>0 then self.sel=self.sel%#items+1
  elseif act=="b" then App.pop()
  elseif act=="y" then M.refresh(function(ok,err) self.msg=ok and nil or tostring(err) end)
  elseif act=="select" then M.cancel()
  elseif act=="a" and items[self.sel] then
    local item=items[self.sel];local st=M.status(item)
    if st=="available" or st=="update" then
      App.show_dialog({title=st=="update" and "Atualizar tema?" or "Baixar tema?",kind="info",
        body=item.name.." — v"..item.version.."\n\nO pacote será verificado pelo SHA-256. Temas originais não serão alterados.",
        buttons={{label=st=="update" and "ATUALIZAR" or "INSTALAR",fn=function()
          local ok,why=M.install(item);if not ok then App.toast(why,"error") end end},
          {label="CANCELAR"}},sel=2})
    else
      local th=Themes.by_id and Themes.by_id[item.id]
      if th and th.id~=Themes.current then
        local ok,why=Themes.apply(th.id,true)
        if ok then App.toast(item.name.." aplicado.","ok") else App.toast(why,"error") end
      else App.toast("Tema já instalado e em uso.","info") end
    end
  elseif act=="x" and items[self.sel] and M.status(items[self.sel])=="installed" then
    local item=items[self.sel]
    App.show_dialog({title="Remover tema?",kind="warn",body="Remover apenas o tema "..item.name..
      "? Temas incluídos no aplicativo não serão removidos.",buttons={
        {label="REMOVER",danger=true,fn=function()
          local ok,why=M.remove(item.id);App.toast(ok and "Tema removido" or why,ok and "ok" or "error")
        end},{label="VOLTAR"}},sel=2})
  end
end
return S
