-- Avaliação offline de ports: setas vazadas sem fundo e contadores locais.
-- Uma escolha por port/console e por catálogo (r36sbr ou lira).
-- Não exibe números globais enquanto não existir serviço remoto de votos.
local L=require("lib.i18n").L
local T=require("ui.theme")
local G=require("ui.gfx")
local Catalog=require("core.catalog")
local Ratings=require("core.ratings")
local lg=love.graphics
local S={}
S.fixed_text=true

function S:enter(params)
 self.port=params.port
 self.source=Catalog.catalog_source()
 self.sel=Ratings.get(self.port,self.source)=="down" and 2 or 1
end

local function triangle(x,y,down,color)
 -- Triângulo translúcido/vazado: sem polígono preenchido.
 -- Coordenadas inteiras e largura constante, também na Mali-G31.
 G.color(color)
 lg.setLineWidth(2)
 if down then
  lg.line(x+5,y+7,x+47,y+7,x+26,y+44,x+5,y+7)
 else
  lg.line(x+26,y+7,x+47,y+44,x+5,y+44,x+26,y+7)
 end
 lg.setLineWidth(1)
end

function S:draw()
 local p=self.port or {}
 G.header(L("Avaliar port"))
 G.panel(16,65,608,352,{bg=T.c.bg1})
 G.text_fit(T.f.h2,p.name or "",36,85,567,T.c.text)
 G.text(T.f.body,L("Escolha uma avaliação"),36,131,T.c.dim)
 local counts=Ratings.counts(self.port,self.source)
 local vote=Ratings.get(self.port,self.source)
 for i=1,2 do
  local x,y,w,h=36+(i-1)*286,179,268,122
  local on=self.sel==i
  local positive=i==1
  local c=positive and T.c.green or T.c.red
  local option=positive and "up" or "down"
  -- Superfície transparente, com moldura de foco.
  if on then G.rect(x,y,w,h,T.c.bg2,10,.15) end
  G.frame(x,y,w,h,on and c or T.c.line,10,on and 2 or 1)
  triangle(x+16,y+30,not positive,c)
  G.text(T.f.h2,tostring(counts[option]),x+103,y+30,T.c.text)
  G.text(T.f.bodyb,positive and L("POSITIVO") or L("NEGATIVO"),x+103,y+63,c)
  if vote==option then G.text(T.f.small,L("SEU VOTO"),x+103,y+88,T.c.dim) end
 end
 G.text(T.f.small,L("Contagem local: apenas os votos deste console."),36,326,T.c.dim)
 G.text(T.f.small,L("Um voto por port. Pode mudar ou remover. Sem placar global."),36,350,T.c.faint)
 G.hints({{"dpad",L("Escolher")},{"a",L("Votar")},{"x",L("Remover voto")},{"b",L("Voltar")}})
end

function S:action(act)
 if act=="left" or act=="up" then self.sel=1
 elseif act=="right" or act=="down" then self.sel=2
 elseif act=="b" then App.pop()
 elseif act=="a" or act=="x" then
  local choice=act=="x" and nil or (self.sel==1 and "up" or "down")
  local ok,now=Ratings.set(self.port,choice,self.source)
  if not ok then App.toast(L("Falha ao salvar avaliação."),"warn");return end
  App.toast(now and L("Avaliação salva neste console.") or L("Avaliação removida."),"info")
 end
end
return S
