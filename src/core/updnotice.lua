-- Aviso de versao nova do R36S ROM STORE (faixa no alto da tela inicial).
-- Ao abrir o hub, depois que a rede responde, consulta em segundo plano o
-- link oficial de atualizacao (le so o comeco do pacote). Se a versao do
-- link for maior que a instalada, a tela inicial mostra um texto deslizante
-- ate o hub ser atualizado. Nao baixa nem instala nada sozinho.
-- Liga/desliga: Configuracoes > Atualizacoes do hub > Avisar quando sair versao nova
local C = require("config")
local Prefs = require("core.prefs")
local L = require("lib.i18n").L

local N = { version = nil, label = nil, phase = "idle", popup_seen = false }  -- idle | waitnet | checking | done

local NET_WAIT = 25      -- segundos esperando a rede antes de desistir nesta abertura

function N.enabled() return Prefs.get("upd_notify") ~= "0" end

--- comeca a espera pela rede; a consulta sai em N.update()
function N.start()
  if not N.enabled() or N.phase ~= "idle" then return end
  N.version, N.label, N.popup_seen = nil, nil, false
  N.phase, N.wait = "waitnet", NET_WAIT
end

local function run_check()
  local Update = require("core.update")
  if not Update.source_url() then N.phase = "done"; return end
  N.phase = "checking"
  Update.check(function()
    N.phase = "done"
    local i = Update.info
    if Update.state == "available" and i and i.version then
      N.version, N.label = i.version, i.label
      require("lib.util").log("aviso de atualizacao: versao " .. tostring(i.version) .. " disponivel")
    end
  end)
end

function N.update(dt)
  if N.phase ~= "waitnet" or not N.enabled() then return end
  local st = require("core.net").current()
  if st and st.connected then
    -- nao disputa com uma verificacao aberta pelo usuario
    local Update = require("core.update")
    if Update.state == "checking" or Update.busy() then return end
    run_check()
    return
  end
  N.wait = N.wait - (dt or 0)
  if N.wait <= 0 then N.phase = "done" end
end

--- versao nova pendente? (some sozinho depois de atualizar e reiniciar)
function N.pending()
  if not N.enabled() or not N.version then return false end
  if require("core.updater.manager").restart_needed then return false end
  return require("core.update").compare(N.version, C.VERSION_NUM) > 0
end

-- Popup exibido uma vez por abertura, somente quando o servidor confirma nova versão.
function N.should_popup()
  return N.pending() and not N.popup_seen
end

function N.consume_popup()
  N.popup_seen = true
end

function N.popup_body()
  local newv = N.label or N.version or "?"
  local info = require("core.update").info
  local notes = info and tostring(info.notes or "") or ""
  -- Primeira novidade no popup; o resumo completo esta na tela de atualizacao.
  local first = notes:match("%- ([^\n]+)") or notes:match("^([^\n]+)") or ""
  first = require("lib.util").safe_utf8(first:sub(1, 125))
  local news = first ~= "" and (L("Novidade: ") .. first .. "\n\n") or ""
  return L("Existe uma nova versão do R36S ROM STORE disponível pela internet.\n\n")
    .. L("Versão instalada: ") .. tostring(C.VERSION_NUM or "?") .. "\n"
    .. L("Nova versão: ") .. tostring(newv) .. "\n\n"
    .. news .. L("Deseja baixar a atualização agora?")
end

function N.text()
  local v = N.label or N.version or ""
  return L("Nova versão do R36S ROM STORE disponível: ") .. v
    .. L("  •  Atualize agora: aperte SELECT ou vá em Configurações > Atualizações do hub > Atualização via rede.")
end

return N
