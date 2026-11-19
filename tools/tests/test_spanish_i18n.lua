-- Teste do quarto idioma no runtime LuaJIT sem carregar LÖVE inteiro.
-- Implementacao de utf8.char apenas para os codigos usados pela tabela UP.
package.preload["utf8"] = function()
  return { char = function(cp)
    if cp < 0x80 then return string.char(cp) end
    if cp < 0x800 then
      return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
    end
    if cp < 0x10000 then
      return string.char(0xE0 + math.floor(cp / 4096),
        0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
    end
    error("codepoint not expected")
  end }
end
package.path = "game/?.lua;game/?/init.lua;" .. package.path
local I = require("lib.i18n")
assert(#I.LANGS == 4, "deve haver quatro idiomas")
assert(I.valid("pt-BR") and I.valid("en") and I.valid("es") and I.valid("ru"))
assert(not I.valid("fr"))
local es = require("i18n.es")
assert(type(es) == "table" and es["Configurações"] == "Configuración")
I.set("es")
assert(I.lang == "es")
assert(I.L("Configurações") == "Configuración")
assert(I.L("Sobre o projeto") == "Acerca del proyecto")
assert(I.L("AVISO IMPORTANTE") == "AVISO IMPORTANTE")
assert(I.tr("Sobre o projeto") == "Acerca del proyecto")
assert(I.tr("ABOUT THE PROJECT") ~= nil)  -- nenhum erro ao traduzir a entrada
assert(I.tr("VOLTAR") == "VOLVER")
assert(I.tr("Acerca del proyecto") == "Acerca del proyecto")
I.set("en")
assert(I.L("Configurações") == "Settings")
I.set("ru")
assert(I.L("Configurações") ~= "Configurações")
I.set("pt-BR")
assert(I.L("Configurações") == "Configurações")
I.set("es")
assert(I.L("Idioma alterado.") == "Idioma cambiado.")
print("Quarto idioma es: OK")
