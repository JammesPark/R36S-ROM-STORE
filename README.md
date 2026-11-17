# R36S ROMS STORE — v0.2.5 (teste)

Loja de ROMs para consoles R36S, com interface Lua + LÖVE 11.5 na resolução **640×480**, catálogo único GameStoreBR (`r36swiki.com/getgames.php`) e arquivos baixados diretamente para SD1/SD2. **Nenhuma ROM, BIOS ou conteúdo comercial é distribuído com o aplicativo.**

## Identidade definitiva

- Nome apresentado, título do LÖVE, launcher, diretório, logs e pacotes: **R36S ROMS STORE**.
- Launcher: `R36S ROMS STORE.sh`
- Diretório do app: `/roms/ports/r36s-roms-store/`
- Arquivos de dados: `/roms/ports/r36s-roms-store/state/`
- Identidade LÖVE: `r36s-roms-store`
- O instalador legado de ports e seu validador de arquivos foram retirados. Os arquivos ROM são salvos **sem descompactação ou execução**.

## Interface

- Menu lateral; catálogo com categorias e grade 3×2 de capas; busca, detalhes, favoritos, histórico, downloads e configurações.
- Idiomas: português (Brasil), inglês, espanhol e russo.
- Temas: azul, roxo, verde, laranja, rosa, vermelho e gelo. Preferências mantidas em `state/roms_settings.json`.
- Favoritos salvos em `state/roms_favorites.json`, com indicador SD1, SD2, ambos ou não baixado.
- Histórico em `state/roms_downloads.json`. Cache de categorias e jogos: `state/gamestore_*.json`.
- Os arquivos baixados ficam em `/roms/<plataforma>/` ou `/roms2/<plataforma>/`, sem sobrescrever outros arquivos.

## Instalar ou atualizar no SD1

1. Baixe o ZIP instalável da execução mais recente do GitHub Actions.
2. Extraia na **raiz de `/roms/ports/`**, criando `R36S ROMS STORE.sh` e `r36s-roms-store/`.
3. Abra a loja em **Ports**. É necessário PortMaster com runtime LÖVE 11.5, Python 3 e acesso à rede para consultar o catálogo.
4. Na primeira execução, o launcher procura dados da versão anterior em uma pasta técnica legada e copia, **sem apagar nem sobrescrever arquivos**, idioma, tema, favoritos, histórico e cache de catálogo para a nova estrutura. Capas poderão ser baixadas novamente.
5. Após confirmar que favoritos e configurações estão presentes na nova versão, você pode remover **o launcher antigo e a pasta técnica legada** manualmente, se não precisar mais deles. Faça um backup antes. **Não apague sua pasta de ROMs** (`/roms/<plataforma>/` ou `/roms2/<plataforma>/`).

## Controles

- Cima/baixo: mover a seleção no menu inicial; esquerda/direita: alternar foco. Movimento do direcional **não abre** telas.
- A: confirmar opção; B: voltar; L1/R1: trocar entre áreas principais.
- Catálogo: START busca; Y atualiza lista; X favorita; esquerda na primeira coluna acessa categorias.
- Confirmação: X ou esquerda/direita alterna entre SD1 e SD2.

## Diagnóstico

Se o aplicativo fechar, envie `/roms/ports/r36s-roms-store/log.txt` ou `state/logs/startup.log`. O launcher usa `control.txt` e `runtimes/love_11.5/love.txt` do PortMaster, com fallback para o comando `love` do sistema. O funcionamento gráfico no console precisa ser confirmado com teste real.

## Testes

```sh
lua5.4 tests/test_json.lua
R36S_STORE_OFFLINE_TEST=1 lua5.4 tests/test_ui_smoke.lua
python3 tests/test_gamestore.py
python3 tests/test_single_catalog.py
python3 tests/test_brand_cleanup.py
bash tests/test_bootstrap.sh
bash tools/build.sh
```

A API GameStoreBR é de terceiros e sua disponibilidade depende do provedor. Os arquivos que ela disponibiliza estão sujeitos aos direitos dos respectivos titulares. A interface deste projeto é independente.

## v0.2.5 — Melhorias de interface solicitadas

- Tela de entrada redesenhada com **logo vetorial R36S ROMS STORE** integrada ao LÖVE e barra de progresso. O ZIP não inclui um logotipo PNG externo; caso exista uma arte oficial diferente, ela poderá substituir a marca vetorial.
- Total de ROMs na Home agora é a soma dos contadores de todas as plataformas, excluindo a categoria ALL para evitar duplicidade. Antes da sincronização, exibe um traço.
- Layout da Home compactado no topo, visão geral elevada e **capas dos destaques maiores**. Capas reais de ROMs agora usam enquadramento **contain**, sem corte. Cards do catálogo exibem somente título (sem nome da plataforma), com mais área para capa.
- Adicionado **Sair** no menu esquerdo, com diálogo **A confirmar / B cancelar** antes de encerrar. Navegação do direcional permanece sem abrir telas automaticamente.
- Quantidades de ROMs removidas das linhas de plataformas. **X abre pesquisa** no catálogo; favoritos continuam disponíveis nos detalhes do jogo.
- Tela de idiomas: bandeiras vetoriais de Brasil, EUA, Espanha e Rússia, sem depender de fontes de emoji.
- Armazenamento: exibe somente total e espaço disponível de SD1/SD2; alerta quando SD2 não está montado separadamente. A escolha entre SD1 e SD2 acontece **exclusivamente na confirmação do download**.
- Rede e catálogo: mostra somente luz de status e ação Atualizar catálogo, sem informar o provedor. Verde = resposta online confirmada, vermelho = erro de conexão, amarelo = verificando ou manutenção sinalizada pela API. O cache offline não é tratado como prova de conexão. Sobre não mostra mais o provedor.

**Observação:** esta versão depende de testes reais no R36S para confirmar desempenho da renderização, as capas e medição do espaço dos cartões.


## Atualização v0.2.5 — UI, downloads e controles

- **Downloads:** transferência ativa no painel superior e histórico de ROMs concluídas abaixo, com até 4 registros por página e rolagem pelo D-pad. A lista é lida do `state/roms_downloads.json`, não contém dados demonstrativos.
- **Status:** Wi-Fi (interface detectada), hora local e bateria (%) consultados no Linux. Sensores ausentes mostram `--%`; Wi-Fi detectado não garante acesso à internet.
- **Início:** 4 destaques em grade 2×2 e visão geral em coluna; o título da ROM aparece uma vez, abaixo da capa.
- **Fonte:** três tamanhos Pequena, Média e Grande em Configurações, gravados em `state/roms_settings.json` e aplicados na inicialização.
- **Controles:** o PortMaster continua fornecendo SDL_GAMECONTROLLERCONFIG; **GPTOKEYB foi desativado** para impedir eventos duplicados. D-pad navega, A confirma, B volta, X pesquisa no catálogo, Y atualiza, START pesquisa. L1/R1 paginam apenas dentro do catálogo. Não trocam telas na Home. Teclado PC usa Enter/Escape/setas/X/Y; apelidos antigos Z/Q/E/Space foram removidos.

O uso do Wi-Fi, da bateria e a aceitação do controle dependem do dispositivo e firmware, ainda sujeitos a teste no console físico.


## Atualizacao v0.2.5 — Interface, controles e navegacao

- Removido botao visual de retorno ao menu nas categorias (B ainda retorna).
- Barra superior Wi-Fi/hora/bateria alinhada e centralizada verticalmente.
- Pesquisa no catalogo exibida por icone de lupa; o atalho **X Buscar** fica no rodape.
- Tela Sobre totalmente redesenhada, com identidade propria, cartao do desenvolvedor James Park, dados tecnicos e aviso independente. O botao A nao abre Ajuda a partir da tela Sobre.
- Botao Atualizar catalogo na tela Rede funciona por toque/clique ou botao A; quando ja existe atualizacao pendente, mostra feedback em vez de enviar operacao duplicada.
- Inicio: a seta direita entra na area de conteudo, com foco entre Explorar, Visao geral e Destaques. A confirma o item destacado.
- Destaques em formato slide unico com imagem inteira, uma legenda, posicao e navegacao. Troca automatica quando nao estiver selecionado.
- Categorias do menu usam icones vetoriais contextualizados; nomes exibidos com inicial maiuscula e siglas preservadas.

A integracao grafica ainda depende de validacao no console real.


## v0.2.6 — logo oficial, catálogo em lista e busca real

- `src/assets/logo.png`: logo enviada e revisada pelo usuário, com fundo transparente. Incluída no `game.love`; aplicada na entrada, cabeçalho lateral e Sobre, com fallback se a imagem estiver danificada.
- Menu de plataformas com marcadores distintos (NES, SNES, PSX, GBA, N64, etc.).
- Início com espaçamento melhor e slide mais estreito, próximo ao formato retrato.
- Catálogo em lista de seis ROMs por bloco, com capa grande selecionada à direita, sem cortar imagem. **D-pad cima/baixo** seleciona, **A** abre detalhes e **L1/R1** troca páginas.
- **Busca remota completa:** usa a ação `search` da API, com paginação e cache separado; não limita resultados às ROMs da página atual. **X** abre teclado, **START** consulta, **B** volta para editar.
- Os dados reais e a disponibilidade dependem do servidor do catálogo e do dispositivo físico.
