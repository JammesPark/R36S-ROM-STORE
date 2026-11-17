# R36S PORTS BR STORE KPM

Aplicativo independente para R36S, com interface Lua/LÖVE 11.5 (640×480), integração à API GameStoreBR e downloads em SD1/SD2. Não inclui jogos, ROMs, BIOS ou conteúdo do aplicativo GameStoreBR.

## Catálogo único: GameStoreBR

A aba **CATÁLOGO** abre diretamente GameStoreBR. O catálogo anterior KPM (JSON remoto manual) foi removido, junto com `src/catalog.json` e `config/catalog_url.txt`. Os downloads são consultados sob demanda na API `r36swiki.com/getgames.php`, via adaptador próprio `bin/gamestore_source.py`. Não é necessário configurar URL para abrir o catálogo, mas é necessário acesso à internet e à API do provedor.

A listagem não está embutida no aplicativo: o adaptador tenta HTTPS e, se não houver suporte, usa HTTP para esse provedor. **A disponibilidade real da API não foi confirmada no console.** HTTPS é preferível: metadados e links recebidos por HTTP não possuem proteção contra adulteração em trânsito.

### Controles

- **A:** abrir catálogo, selecionar plataforma ou confirmar download.
- **B:** voltar e cancelar.
- **L/R:** mudar as abas da interface.
- **START:** escolher a plataforma GameStoreBR.
- **Direcional esquerda/direita:** mudar de página no catálogo.
- **Y:** atualizar categorias/listas.
- **X na confirmação do download:** alternar SD1 e SD2.
- **X em Ajustes:** escolher cartão padrão para download.
- **X em Instalados:** remover somente instalações antigas gerenciadas pela loja (após confirmação).

Arquivos GameStoreBR são salvos **sem extração ou execução**, como ROMs/ZIPs em `/roms/<plataforma>/` (SD1) ou `/roms2/<plataforma>/` (SD2). A loja não sobrescreve automaticamente arquivos existentes. Quando a API não fornece SHA-256, a origem não tem validação criptográfica; o hash calculado localmente não substitui um hash publicado pelo fornecedor.

A aba **INSTALADOS** mantém os manifestos de ports instalados em versões anteriores do aplicativo. Removê-los é opcional e exige confirmação. Nenhum arquivo já presente no console é apagado pela atualização do repositório.

## Instalação de teste

No GitHub, acesse **Actions → Validar e empacotar R36S KPM → execução mais recente → Artifacts**. Baixe `R36S-PORTS-BR-STORE-KPM`, que contém:

- `R36S_PORTS_BR_STORE_KPM_INSTALAR.zip`
- `R36S_PORTS_BR_STORE_KPM_FONTE.zip`

Extraia o conteúdo do ZIP instalável na pasta `/roms/ports/` do SD1. A interface é iniciada pelo script `R36S PORTS BR STORE KPM.sh`. O console precisa de um runtime LÖVE compatível com a versão 11.5, Bash, Python 3 e `findmnt` para validar o SD2. O aplicativo não embute o runtime.

Os testes de CI verificam sintaxe, navegação estática, segurança básica do download e empacotamento; **não substituem testes com hardware real**.

## Para quem mantém o projeto

```sh
lua5.4 tests/test_json.lua
python3 tests/test_archives.py
python3 tests/test_gamestore.py
python3 tests/test_single_catalog.py
bash tests/test_backend.sh
bash tools/build.sh
```

O backend histórico `worker.sh` conserva as funções de remoção/registro de ports gerenciados, para compatibilidade. Não existe mais ação de catálogo KPM nem URL manual para a fonte anterior.

## Correção para fechamento sem imagem — v0.1.1 (teste)

O launcher usa agora o `control.txt` e o runtime `runtimes/love_11.5/love.txt` do PortMaster. Como alternativa, usa `love` instalado no sistema. O pacote ZIP preserva os bits de execução dos scripts `.sh`.

**Log após falha de boot:** `/roms/ports/r36s-store-kpm/log.txt` e `/roms/ports/r36s-store-kpm/state/logs/startup.log`. O log registra o runtime selecionado e o motivo do encerramento do LÖVE.

Copie o novo ZIP instalável para `/roms/ports/`, substituindo os arquivos antigos. Não é necessário remover os jogos. A inicialização foi simulada no GitHub Actions, mas o funcionamento gráfico ainda depende de teste no dispositivo.
