-- Regressao: um toque em A nao pode abrir "Sobre" e acionar "Siga o canal".
-- Executar: luajit tests/test_input.lua
local now = 0
_G.love = { timer = { getTime = function() return now end } }
local Input = dofile("game/core/input.lua")
local calls = {}
Input.handler = function(act)
  calls[act] = (calls[act] or 0) + 1
  if act == "a" then Input.reset() end -- simula App.push / App.show_dialog
end
local function count(act) return calls[act] or 0 end
local function tick(t) assert(t >= now); now = t end

-- SDL entra em Sobre; a tecla virtual chega depois da mudanca de tela.
tick(1.00); Input.gamepadpressed(nil, "a")
assert(count("a") == 1, "SDL nao confirmou")
tick(1.14); Input.keypressed("return", nil, false)
assert(count("a") == 1, "SDL+gptokeyb confirmou segunda vez")
tick(1.18); Input.gamepadreleased(nil, "a")
tick(1.22); Input.keyreleased("return")
assert(not Input.is_held("a"), "botao A ficou preso")

-- Soltar e apertar novamente deve permitir confirmar na tela Sobre.
tick(1.50); Input.gamepadpressed(nil, "a")
assert(count("a") == 2, "segundo toque real foi perdido")
tick(1.52); Input.gamepadreleased(nil, "a")

-- Caso inverso: gptokeyb chega antes do SDL, inclusive com reset no handler.
tick(2.00); Input.keypressed("return", nil, false)
assert(count("a") == 3)
tick(2.10); Input.gamepadpressed(nil, "a")
assert(count("a") == 3, "gptokeyb+SDL confirmou segunda vez")
tick(2.15); Input.keyreleased("return")
tick(2.20); Input.gamepadreleased(nil, "a")

-- Mesmo controle emitindo varios 'pressed' sem 'released'.
tick(3.00); Input.gamepadpressed(nil, "a")
assert(count("a") == 4)
tick(3.50); Input.gamepadpressed(nil, "a")
assert(count("a") == 4, "pressionamento sustentado gerou outro clique")
tick(3.60); Input.gamepadreleased(nil, "a")

-- Ecos atrasados logo depois de released nao devem atravessar telas.
tick(4.00); Input.gamepadpressed(nil, "a")
assert(count("a") == 5)
tick(4.02); Input.gamepadreleased(nil, "a")
tick(4.12); Input.keypressed("return", nil, false)
assert(count("a") == 5, "eco atrasado abriu segunda tela")
tick(4.14); Input.keyreleased("return")

-- Entrada somente por teclado nao pode ficar desabilitada.
tick(4.50); Input.keypressed("return", nil, false)
assert(count("a") == 6, "teclado isolado nao confirmou")
tick(4.52); Input.keyreleased("return")

-- B: um clique para voltar, sem reentrada via segunda origem.
tick(5.00); Input.keypressed("space", nil, false)
assert(count("b") == 1)
tick(5.11); Input.gamepadpressed(nil, "b")
assert(count("b") == 1, "B duplo")
tick(5.12); Input.keyreleased("space")
tick(5.14); Input.gamepadreleased(nil, "b")

-- Navegacao segue com auto-repeat, mas sem segundo keydown fantasma.
tick(6.00); Input.gamepadpressed(nil, "dpdown")
assert(count("down") == 1)
tick(6.10); Input.keypressed("down", nil, false)
assert(count("down") == 1, "duplicidade na navegacao")
tick(6.36); Input.update(0.36)
assert(count("down") == 2, "auto-repeat de navegacao nao funciona")
tick(6.40); Input.gamepadreleased(nil, "dpdown")
tick(6.42); Input.keyreleased("down")
tick(6.80); Input.update(0.40)
assert(count("down") == 2, "auto-repeat continuou apos soltura")

print("INPUT: OK - confirmacao unica, troca de tela, SDL+teclado e navegacao")
