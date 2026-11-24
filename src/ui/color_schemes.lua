-- Paletas de interface independentes do layout. Nao alteram cores de estado.
local M={}
M.LIST={
 {id="original",label="Original"},
 {id="blue",label="Azul",accent="#60A5FA",accent2="#67E8F9",bg0="#080F1D",bg1="#111E33",bg2="#1B2C48",bg3="#243D60",line="#36557B"},
 {id="green",label="Verde",accent="#4ADE80",accent2="#BEF264",bg0="#08150E",bg1="#12251A",bg2="#203C29",bg3="#294C32",line="#385E42"},
 {id="red",label="Vermelho",accent="#FB7185",accent2="#FDBA74",bg0="#180B12",bg1="#2B1520",bg2="#43202C",bg3="#592B39",line="#743D4C"},
 {id="purple",label="Roxo",accent="#C4A7FF",accent2="#E9A8FF",bg0="#100B1D",bg1="#211635",bg2="#33244B",bg3="#463260",line="#5B4780"},
 {id="orange",label="Laranja",accent="#FDBA74",accent2="#FDE68A",bg0="#170F08",bg1="#2B1F13",bg2="#43301C",bg3="#594123",line="#745631"},
 {id="pink",label="Rosa",accent="#F472B6",accent2="#F0ABFC",bg0="#180C19",bg1="#2B172D",bg2="#40223F",bg3="#562D51",line="#74436D"},
 {id="cyan",label="Ciano",accent="#67E8F9",accent2="#99F6E4",bg0="#07151A",bg1="#102730",bg2="#1A3841",bg3="#254D54",line="#35646B"},
}
local function find(id)
 for i,p in ipairs(M.LIST) do if p.id==id then return p,i end end
 return M.LIST[1],1
end
function M.valid(id) return find(id).id==id end
function M.label(id) return find(id).label end
function M.step(id,dir,wrap)
 local _,i=find(id);local n=#M.LIST;i=i+dir
 if wrap then i=(i-1)%n+1 else i=math.max(1,math.min(n,i)) end
 return M.LIST[i].id
end
local function copy(t)
 local out={};for k,v in pairs(t or {}) do out[k]=type(v)=="table" and copy(v) or v end;return out
end
function M.resolve(colors,style,id)
 local c,s=copy(colors),copy(style)
 local p=find(id)
 if p.id=="original" then return c,s end
 local T=require("ui.theme")
 for _,k in ipairs({"bg0","bg1","bg2","bg3","line","accent","accent2"}) do c[k]=T.hex(p[k]) end
 c.text=T.hex("#F1F5F9");c.dim=T.hex("#BAC7D6");c.faint=T.hex("#8999AC")
 s.glow=copy(c.accent);s.focus=copy(c.accent)
 if s.card then
   s.card.fill=copy(c.bg2);s.card.line=copy(c.line);s.card.text=copy(c.text)
   s.card.dim=copy(c.dim);s.card.faint=copy(c.faint);s.card.icon=copy(c.text)
 end
 return c,s
end
return M
