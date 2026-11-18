# R36S ROMS STORE

**Versão atual:** consulte [VERSION](VERSION), fonte oficial para o aplicativo e os pacotes do GitHub Actions. **Canal:** beta; a versão estável 1.0.0 dependerá de validação no console físico. Leia a [política de versões](VERSIONING.md) e o [histórico de atualizações](CHANGELOG.md).

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


## v0.2.7 — logo oficial, catálogo em lista e busca real

- `src/assets/logo.png`: logo enviada e revisada pelo usuário, com fundo transparente. Incluída no `game.love`; aplicada na entrada, cabeçalho lateral e Sobre, com fallback se a imagem estiver danificada.
- Menu de plataformas com marcadores distintos (NES, SNES, PSX, GBA, N64, etc.).
- Início com espaçamento melhor e slide mais estreito, próximo ao formato retrato.
- Catálogo em lista de seis ROMs por bloco, com capa grande selecionada à direita, sem cortar imagem. **D-pad cima/baixo** seleciona, **A** abre detalhes e **L1/R1** troca páginas.
- **Busca remota completa:** usa a ação `search` da API, com paginação e cache separado; não limita resultados às ROMs da página atual. **X** abre teclado, **START** consulta, **B** volta para editar.
- Os dados reais e a disponibilidade dependem do servidor do catálogo e do dispositivo físico.


## v0.2.7 — idioma inicial, aviso obrigatório e Sobre

Ao iniciar pela primeira vez, após o carregamento, o usuário escolhe um dos quatro idiomas disponíveis: português do Brasil, inglês, espanhol ou russo. A escolha é persistida em `state/roms_settings.json` por `language_chosen: true`; nas aberturas seguintes, a seleção de idioma não será exibida novamente, mas poderá ser alterada em Configurações → Idioma. Uma atualização sobre uma versão antiga que não contém a chave `language_chosen` mostra a seleção inicial apenas uma vez.

**O aviso de responsabilidade aparece em toda inicialização**, após o carregamento e, quando necessário, após a escolha de idioma. O botão A confirma a leitura e permite entrar na loja. O botão B não ignora o aviso. Os textos do aviso e da tela Sobre foram revisados e traduzidos para quatro idiomas em `src/legal_text.lua`. O texto da tela Sobre dispõe de rolagem pelo direcional cima/baixo e inclui a indicação da licença e os avisos autorais.

**Licenciamento:** o código original do aplicativo é distribuído sob GNU GPL-3.0 (`LICENSE`). Também incluímos `THIRD_PARTY_NOTICES.txt`. A licença do código não se estende automaticamente a ROMs, jogos, capas, marcas nem runtimes de terceiros. As licenças e os créditos dos componentes de terceiros devem ser respeitados e preservados. O aplicativo não é afiliado oficialmente a fabricantes ou desenvolvedores de jogos.


## Versão 0.2.8 — Ajustes visuais, música e QR Code

- Aviso inicial: redação sem menção a ports de terceiros e parágrafos justificados nos 4 idiomas.
- Idiomas: bandeiras em PNG rasterizadas do conjunto Noto Color Emoji.
- Início: capa do slide redimensionada para preencher todo o espaço (esticamento autorizado) e faixa opaca sobreposta com o título legível.
- Menu: ícones externos Lucide (ISC), diferentes por função e com símbolos associados às plataformas, incluindo pequenos identificadores de hardware.
- Voltar no catálogo: do jogo para a lista; da lista para as categorias; das categorias para Início.
- Sobre: logo da loja menor à esquerda, logo James Park à direita e canal Telegram central. **A** abre QR do canal e **START** abre QR do LivePix (imagens originais fornecidas). **B** fecha o QR. O cabeçalho permanece fixo durante a rolagem do texto legal.
- Trilha sonora local: `tema_principal.ogg` no Início, `tema_navegacao.ogg` nas demais telas e `tema_download.ogg` na área de downloads. LÖVE usa stream OGG (volume reduzido); se um áudio não abrir, a loja continua funcionando.
- A apresentação HTML offline acompanha o instalador em um ZIP à parte; não contém catálogo remoto real.

### Licenças e permissões

O código da loja está sob GPL-3.0. Os ícones Lucide seguem licença ISC e as bandeiras usam imagem de emoji colorido. Os três áudios e os QR codes foram enviados para integração pelo usuário, mas a distribuição pública das faixas depende de seus respectivos direitos; os arquivos não são licenciados automaticamente pela GPL. Para distribuir os arquivos, confirme que há autorização dos titulares.


## Atualização v0.2.9: catálogo em rolagem e gestão de ROMs

- Tela Sobre alinhada à esquerda, marcas laterais ajustadas e modal de Telegram/LivePix conforme as fotografias de referência. **A** abre QR de Telegram, **START** abre QR do LivePix, **A** amplia, **B** fecha ou retorna ao modal.
- Ícones distintos por seção, ícones de plataformas sem letras sobrepostas e legendas dos botões na tela Sobre.
- Catálogo em **lista contínua**: a navegação pelas setas carrega e acrescenta automaticamente as páginas seguintes em memória. A busca também carrega mais resultados ao avançar. Não há alternância manual de páginas.
- **Instalados → X** permite solicitar exclusão, mas somente dos arquivos de ROM salvos e registrados pela loja; arquivos alterados, links simbólicos, saves e pastas não são removidos. Confirmação A/B obrigatória.
- **Baixar:** antes de iniciar, verifica se o arquivo já existe no SD escolhido. Se existir, pergunta se deseja sobrescrever. O novo arquivo é baixado e validado antes de substituir o antigo; o processo não extrai pacotes.
- A confirmação de sobrescrita, a exclusão e os avisos estão traduzidos em português, inglês, espanhol e russo.

Atenção: a loja só reconhece como excluíveis ROMs presentes no seu próprio histórico; isso não autoriza apagar jogos que foram copiados manualmente. A sobrescrita de um arquivo existente requer confirmação, mesmo que não conste no histórico.


## v0.2.10 — checklist de correções da interface (640×480)

- [x] **Etapa 1 — Sobre:** ícones visuais dos botões A e START no cartão da comunidade.
- [x] **Etapa 1 — QR codes:** textos Telegram e LivePix quebrados em linhas, dentro do modal; A amplia, B fecha, com retorno ao modal ao reduzir a ampliação.
- [x] **Etapa 1 — Sobre:** texto alinhado à esquerda; aviso inicial continua justificado.
- [x] **Etapa 1 — Logo do desenvolvedor:** removidas margens transparentes do PNG e ampliada a área visível.
- [x] **Etapa 2 — Configurações:** ícones distintos para Idiomas, Temas, Fonte, Armazenamento, Rede e Ajuda.
- [x] **Etapa 3 — Destaques:** nome da ROM em uma faixa opaca por cima da capa e sem contador cobrindo o texto.
- [x] **Validação local:** regressão de interface em Lua, testes Python do backend, QR codes, onboarding e montagem dos arquivos ZIP.
- [ ] **Teste no R36S físico:** verificar leitura real em tela 640×480 com fontes pequena, média e grande e confirmar legibilidade no console.

### Instalação

Extraia `R36S_ROMS_STORE_v0.2.10_TESTE.zip` em `/roms/ports/`, substituindo os arquivos do aplicativo. **Não apague** `r36s-roms-store/state/` nem suas ROMs em SD1/SD2.

Observação: os três áudios `.ogg` e os QR codes continuam idênticos aos da v0.2.9. O instalador inclui a versão recortada da logo `logo_dev.png`, além dos novos ícones, dentro de `game.love`.


## Ajustes v0.2.11 — alinhamento visual em 640×480

- Removidas as indicações redundantes de resolução da interface (o display do console permanece 640×480).
- Cartão de comunidade da tela **Sobre** centralizado; ícones A e START, legendas e botão de voltar com espaçamento consistente.
- Rodapés revisados para não sobrepor os controles com a versão do aplicativo.
- Bolinhas do carrossel centralizadas matematicamente dentro do slide; cartão reduzido para deixar o título **Em destaque** totalmente visível.
- No **Catálogo**, X é a única tecla para abrir a pesquisa. START não abre mais a tela de busca; a busca já aberta pode ser confirmada pelo teclado virtual.
- Preview do jogo selecionado ocupa toda a área da capa sem títulos ou comandos sobrepostos, com modo esticado.
- Adicionado teste automatizado para os novos posicionamentos e atalhos.

## v0.2.12 — Correção de alinhamento e botão START

- O título **Em destaque** está alinhado horizontalmente à esquerda do slide e na mesma altura do título Visão geral. O slide foi realinhado à altura dos cartões da visão geral sem interferir no nome da ROM.
- O botão **START** agora é um botão amarelo sólido de 56 × 20 pixels, com texto escuro centralizado e sem cortes, inclusive com fonte Grande.
- Na tela Sobre, A / Canal e START / LivePix possuem posições calculadas dentro do cartão central, sem invadir o limite direito.
- Testes automatizados verificam a posição dos títulos, do slide e dos dois botões START (cartão e legenda do rodapé).

Os ajustes precisam de validação final no console físico.


## v0.2.13 — Destaques sem nomes e START verde

- O texto **EM DESTAQUE** tem centro horizontal calculado a partir da caixa do slide, e permanece alinhado verticalmente ao título da Visão geral.
- Os **nomes dos jogos foram removidos do slide**. O espaço ficou reservado para a capa completa e os indicadores centralizados.
- As teclas **START** na tela Sobre (cartão e legenda inferior) passaram a ser exibidas em um botão sólido **verde**, com largura ampliada para não cortar a palavra.
- O teste de regressão confere o alinhamento do título, a ausência dos nomes dos jogos e os dois botões verdes.


## v0.2.14 — Ícones da navegação principal

A navegação lateral agora desenha oito ícones independentes de arquivos PNG, evitando a falha anterior que mostrava o mesmo quadrado quando a imagem não carregava: **Início/casa; Catálogo/livros; Downloads/seta; Instalados/cartão SD marcado; Favoritos/coração; Configurações/engrenagem; Sobre/informação; Sair/porta com seta.** Os oito têm a mesma caixa de 18×18 pixels, cor inativa discreta e cor de destaque quando selecionados. Os ícones das plataformas e das opções de configurações não foram alterados. Um teste automatizado verifica que os oito desenhos são distintos.


## v0.2.15 — Download atual na tela inicial e ícones verificados

O antigo texto promocional da tela Início foi substituído por um painel **DOWNLOAD ATUAL** que acompanha a transferência real, indicando nome da ROM, SD1/SD2, barra e porcentagem quando o tamanho esperado estiver disponível. Sem transferência mostra uma mensagem neutra, nunca um progresso demonstrativo. O botão **VER DOWNLOADS** abre a página Downloads por A ou clique. A navegação principal continua com oito desenhos diferentes, gerados diretamente pelo LÖVE e independentes de imagens. O novo teste automatizado valida os ícones na renderização da barra lateral real e os estados com e sem transferência; verifique `v0.2.15` no canto inferior esquerdo do console para confirmar que esta atualização foi instalada.


## Organização de versões

A partir de **0.2.16-beta**, a numeração é centralizada no arquivo raiz `VERSION`. O build copia essa informação para `game.love`, o diretório instalado e o nome dos ZIPs. O GitHub Actions verifica a correspondência. As versões anteriores permanecem documentadas sem renumeração retroativa. `0.3.0-beta` fica reservado para um marco funcional relevante; `1.0.0`, somente após testes físicos completos.


## Atualizações automáticas da loja

A partir de **0.3.0-beta**, a loja verifica atualizações automaticamente. Em **Configurações → Atualizações**, o usuário pode confirmar download, instalação e reinicialização com backup e rollback. Não são alterados ROMs, configurações nem favoritos. O canal público é isolado daquele do R36SPORTSBR STORE HUB. A publicação inicial requer configurar o secret **ROMS_UPDATES_TOKEN**. Leia [o manual de atualização](docs/ATUALIZACAO_ROM_STORE.md).
