# Histórico de versões

## [0.7.0-beta] - 2026-11-24

- Novo marco oficial do R36S ROM HUB STORE: consolidação das melhorias da versão Experimental aprovada e da distribuição 0.6.8-beta.
- Pulse Edition e Matrix Edition com cores independentes, azul original do Pulse, novas logos e identidade visual revisada.
- Matrix com cabeçalho reorganizado, informações do catálogo e atalhos Downloads, Favoritos e Instalados.
- Pulse com logo centralizada; tela Sobre e título do Telegram ampliados; abertura com o nome R36S ROM HUB STORE.
- Catálogo próprio online com validação e recuperação offline, modos Lista, Grade e Vitrine e identificação regional.
- Configurações, Utilitários, Temas Store e gerenciamento de ROMs revisados.
- Mantidos os créditos a Lag do Lira, a licença GPL-3.0 e as rotinas SD1/SD2 e OTA.
- A análise de compatibilidade de tela em outros consoles e firmwares permanece pendente; nenhuma correção nova de resolução integra esta entrega.

## [0.6.8-beta] - 2026-11-24

- Nova identidade visual R36S ROM HUB STORE, com logos PNG atualizadas e título de abertura corrigido.
- Pulse Edition e Matrix Edition: dois temas integrados, créditos a Lag do Lira, cores personalizadas independentes e azul como paleta original do Pulse.
- Matrix: painel de catálogo, menu 3×3, atalhos Downloads, Favoritos e Instalados, logo ampliada à direita e indicadores à esquerda.
- Pulse: logo centralizada com o menu. Sobre: logo e textos do Telegram ampliados.
- Catálogo próprio remoto com validação e cópia local de segurança; modos Lista, Grade e Vitrine nos dois temas, seleção L2/R2 e etiquetas regionais.
- Configurações e Utilitários em painel lateral; Temas Store, detalhes de ROM e instalados pela loja.
- Preservados SD1/SD2, controles testados, licenças e créditos; atualização automática pelo canal oficial reativada.

## [0.6.7-beta] - 2026-11-19

- Consulta automática do canal público de atualizações ao abrir a loja, com aviso no menu e instalação confirmada pelo usuário.

## [0.6.6-beta] - 2026-11-18

- Restaurados integralmente os ícones originais da Central de Conteúdo da versão 0.6.3-beta, conforme preferência do usuário, revertendo o redesenho simplificado de 0.6.4-beta que piorou o visual.
- Mantida a interface de avaliação com triângulos vazados e contadores locais, sem alterar funcionalidades de instalação, catálogos e temas.
- Protótipo HTML interativo adicionado ao código-fonte em design/ para comparação de grades 3×3, 4×4, lista, e capas retrato (2:3) e paisagem (16:9). Essas opções ainda são apenas demonstração HTML.
- Preservados os dois Force integrados, temas opcionais do Lira, créditos GPL-3.0, SD1/SD2 e atualização automática.

## [0.6.5-beta] - 2026-11-18

- A tela Avaliar Port usa triângulos de contorno transparente para positivo ▲ e negativo ▼, substituindo as silhuetas de mãos.
- Contadores individuais de avaliação local em cada seta: 0 ou 1 por port/console, recalculados ao trocar ou remover o voto; sem fingir placar global.
- Mantida persistência offline, um voto por port e isolamento dos catálogos R36S ROMS STORE e Lira.
- Protótipo HTML separado oferece os três modos de catálogo: grid 3×3, grid 4×4 com capas em retrato e lista vertical rolável em 640×480. Não altera a grade padrão do console.
- Preservados os temas Force de fábrica, os quatro temas opcionais do Lira, atualizador, SD1/SD2 e licença GPL-3.0.

## [0.6.4-beta] - 2026-11-18

- Force Nexus Jedi/Sith: abas NOVOS e EM BREVE em tamanho compacto 8px sem sobreposição com textos do PNG de fundo.
- Ícones da Central refeitos para evitar artefatos de contornos e arcos no OpenGL ES, nos tamanhos 28 e 56px e em todas as paletas.
- Avaliação de port via X em Detalhes: 👍 Gostei / 👎 Não gostei, uma escolha editável por port e por catálogo, salva offline no console.
- A votação desta entrega é local; placar público depende de serviço de avaliação online e não exibe números fictícios.
- HTML de demonstração separado para comparar grid 3x3 e 4x3; a grade original da loja não foi alterada.
- Preservados temas do Lira opcionais, Force integrados, SD1/SD2, dados, autoria e GPL-3.0.

## [0.6.3-beta] - 2026-11-18

- Temas de fabrica: Force Nexus — Jedi e Force Nexus — Sith, ambos incluidos no game.love e disponiveis sem internet.
- Temas da base original Lag do Lira: Tema Padrao, Neon Grid, Wii Blue e Pastel Pop passam a ser opcionais e instalaveis pela Loja de Temas online, preservando nomes, autoria e licenca GPL-3.0.
- Atualizacao da 0.6.2-beta: se um tema legado estiver selecionado em theme.txt, sua preferencia e visual serao migrados automaticamente para user_themes com os assets de compatibilidade do pacote, sem conexao de rede. Nao instala outros temas sem escolha previa.
- Temas opcionais ja instalados continuam a receber arquivos atualizados nas atualizacoes gerais, sem sobrescrever personalizacoes desconhecidas nem rebaixar versoes superiores.
- Publicacao de ZIPs individuais com SHA256/tamanho comprovado, previews e catalogo online separado. Force Nexus sempre Jedi seguido de Sith na lista.
- Migracao feita somente no empacotamento: os arquivos originais e creditos permanecem no repositorio. Foram mantidos os catalogos de ports, BIOS, ferramentas, SD1/SD2, logos e a identidade visual oficial.
- Novos testes de distribuicao, preservacao seletiva offline, exclusao de temas legados da lista de fabrica, integridade de pacotes opcionais e cabecalhos 640x480.

## [0.6.2-beta] - 2026-11-18

- Force Nexus — Sith agora aparece imediatamente abaixo de Force Nexus — Jedi na lista de temas, mesmo quando o Sith e opcional; sem alterar a ordem dos demais temas nem aplicar ou reinstalar tema automaticamente.
- Central de Conteudo: nova familia visual de icones vetoriais premium, consistentes e coloridos pela paleta ativa de todos os temas, sem dependencias de PNGs e sem mudar os icones de outras telas.
- Simbolos desenhados para Ports de Jogos (controle), BIOS do Sistema (chip), Ports Utilitarios e Ferramentas (caixa de ferramentas), Pesquisa, Favoritos, Novidades, Downloads e Top Downloads.
- Escalas de 56px nos paineis principais e 28px nos atalhos, calibradas para a resolucao 640x480 com desenhos leves para GPU Mali do R36S.
- Testes automatizados via LuaJIT: renderizacao dos 8 tipos de icones nos dois tamanhos, pilha de desenho equilibrada e ordenacao Jedi/Sith opcional.
- Preservados temas, logos, catálogos, firmware SD1/SD2, avisos, creditores e licenca GPL-3.0 do projeto original Lag do Lira.

## [0.6.1-beta] - 2026-11-18

- Ajustado o alinhamento dos textos de Configuracoes > Temas > Baixar Novos Temas em 640x480, em todos os temas visuais do Hub.
- Cabecalho e subtitulo separados da lista; cinco cartoes com altura adequada e sem invadir avisos de download.
- Redimensionada a pre-visualizacao de capas de temas para reservar area propria de nome e descricao, com recorte para evitar sobreposicao com o rodape.
- Download, erros de rede e progresso de instalacao possuem zona exclusiva acima das dicas de controles.
- Corrigido Configuracoes > Temas: selo EM USO nao cobre o texto da versao, e selo TEMA EM USO nao fica sob a descricao longa.
- Testes automatizados de geometria para fontes normais e grandes, painel de detalhes, status e selos; preservados todos os temas, catálogos, SD1 e SD2.
- Mantidos os creditos e avisos GPL-3.0 do projeto de origem, por Lag do Lira.

## [0.6.0-beta] - 2026-11-17

- Nova etapa da R36S ROMS STORE HUB, migrando a numeracao propria de 0.0.33-beta diretamente para 0.6.0-beta, sem depender da numeracao do projeto de origem.
- Arquivos compactados protegidos por senha: tenta abrir sem senha, depois as senhas de grupos de ports e as do senhas.txt, com teclado para tentativa manual e salvamento opcional.
- Senhas enviadas ao 7-Zip pelo terminal PTY com segredo temporario privado, sem aparecer na linha de comando ou nos registros; senha no teclado fica mascarada.
- Arquivos TAR, TAR.GZ, TAR.XZ e TAR.BZ2 reconhecidos no Gerenciador de Arquivos, com verificacao de caminhos e bloqueio de links perigosos.
- Arquivos divididos RAR, 7Z e ZIP (inclusive ZIP + .z01) reconhecidos, associados a primeira parte, com deteccao de volumes intermediarios ausentes e opcao de exclusao conjunta apos confirmacao ou instalacao bem-sucedida.
- Meus Ports mostra arquivos compactados prontos para instalar nos dois cartoes separadamente (SD1/SD2), com Instalar e Instalar todos usando a Central de Downloads.
- Listagens de ports ganham modo Recem adicionados por data added, alternado entre Padrao, A-Z e Recentes pelo botao X.
- Botao FN permanece disponivel no teste de controles existente, sem alterar os controles do console.
- Mantidos temas e logos, os dois catalogos de ports independentes, as BIOS, o suporte a 4 idiomas e a atualizacao online cumulativa.
- Recursos adaptados do R36S PORT HUB v0.5.4, por Lag do Lira, sob GPL-3.0. Creditos do projeto original preservados.
- Testes de regressao em LuaJIT e Python para TAR, senhas, volumes incompletos, filas SD1/SD2, seguranca do helper PTY e migracao de versao.

## [0.0.33-beta] - 2026-11-17

- Corrigida detecção automática em telas quadradas 720x720: o Hub compara a resolução física do painel Linux (DRM ou fb0) com a superfície lógica informada pelo LÖVE/SDL2.
- Caso o firmware esteja esticando uma superfície 640x480 para um painel 720x720, o renderizador compensa a distorção com escalas X/Y independentes, preservando o aspecto 4:3 e centralizando a interface.
- O modo físico do painel é solicitado ainda na inicialização quando detectado com segurança; caso o SDL mantenha outro tamanho, o ajuste de viewport atua sem precisar alterar manualmente a resolução do console.
- Informações do console priorizam o painel real; log do Hub registra fonte da detecção, tamanho físico, tamanho SDL e escalas aplicadas.
- Testes simulam framebuffer 640x480 em painel 720x720, DRM conectado, fb0, ausência de dados, múltiplas proporções e atualização dinâmica.
- Mantidos os temas, quatro idiomas, catálogos separados, atualização online entre versões, SD1 e SD2 e créditos originais.

## [0.0.32-beta] - 2026-11-17

- Implementada detecção automática da resolução física da tela ao abrir o Hub, pela janela LÖVE/SDL2, com leitura de modo alternativo e fallback seguro 640x480.
- A interface mantém o layout lógico 640x480 e adapta a escala proporcionalmente para telas 4:3, quadradas, widescreen e outras proporções, com centralização sem cortes ou distorções.
- Mudanças de resolução durante a execução são identificadas, inclusive em firmwares que não emitem o evento de redimensionamento.
- Se a GPU não aceitar canvas interno, o renderizador usa escala direta para continuar exibindo a interface no centro da tela.
- Em Informações do console, a resolução física exibida passa a priorizar o framebuffer ativo, não apenas a lista de modos disponíveis do kernel.
- Testes de 640x480, 720x720, 1280x720, 800x480, 1024x600, fallback e mudança dinâmica; sem modificar modo de vídeo, jogos, PortMaster ou catálogos.

## [0.0.31-beta] - 2026-11-17

- A opcao BAIXAR NOVOS TEMAS (catalogo online/atualizador de temas) passa a ocupar sempre a primeira posicao na lista de Configuracoes > Temas.
- Ao entrar ou retornar da loja de temas, o foco inicia na primeira opcao, evitando que ela fique oculta abaixo dos temas instalados.
- Mantida a ordem dos temas instalados e todas as funcionalidades existentes de atualizacao online, instalacao, aplicacao de temas, idiomas, SD1/SD2 e catalogos.
- Incluido teste LuaJIT de regressao para listas de 0, 1, 5 e 9 temas e validacao da abertura do catalogo pelo botao A.

## [0.0.30-beta] - 2026-11-17

- Corrigida falha ao atualizar pulando versoes: novo pacote completo de atualizacao UPDATE_FULL, com somente arquivos instalaveis e manifesto numerico compatível, permitindo saltos sem baixar etapas intermediarias.
- Feed online publica o pacote completo de fallback com SHA-256 validado e conserva o ZIP completo do instalador e o incremental separados.
- Corrigida confirmacao da nova versao apos reiniciar: 0.0.30 e 0.0.30-beta sao a mesma versao, evitando rollback por falso desencontro.
- Validador aceita manifesto numerico e beta, preservando compatibilidade anterior e verificacoes de seguranca do ZIP.
- Testes automatizados verificam saltos de 0.0.4-beta ate 0.0.29-beta, hashes, integridade, arquivos extras, backup e confirmacao apos boot.
- Quatro idiomas, catalogos independentes, atualizacao de temas Jedi/Sith e licencas mantidos.

## [0.0.29-beta] - 2026-11-17

- Corrigida regressao visual nos temas Jedi e Sith: vitrine de jogos mostra somente a capa, sem nome, data ou selo de inclusao no catalogo.
- Top 5 Downloads mostra capas, posicoes e quantidade de downloads, sem nome dos jogos sobre as imagens.
- Sobre > Licencas abre uma tela dedicada somente leitura, com todas as licencas e avisos, retornando por B a pagina anterior.
- PNGs dos temas gerados sem metadados de jogos; prototipos HTML e screenshots usam a mesma regra.
- Valida os arquivos dentro do game.love e dos ZIPs FULL/UPDATE antes de liberar a versao para o console.
- O atualizador so confirma a instalacao quando a versao realmente iniciada coincide com a versao que o pacote declara, mantendo a restauracao de seguranca.

## [0.0.28-beta] - 2026-11-17

- Adicionado idioma Espanhol (Español) como quarta escolha no primeiro acesso e nas configuracoes, com bandeira da Espanha e persistencia em settings.txt.
- Incluidas mais de 1200 traducoes para telas principais, menus, downloads, atualizacoes, temas, rede, backups e avisos; mensagens ainda nao traduzidas em espanhol usam texto ingles como alternativa.
- Catalogos agora aceitam description_es e short_es sem misturar os dois catalogos existentes; PT-BR, EN e RU permanecem ativos.
- Testes automatizados de idioma e de traducao adicionados ao CI; expectativas antigas de posicionamento da logo corrigidas nos testes, sem alterar o layout.
- Corrigido espaco do cabecalho e separacao entre logo com bandeira e textos em todos os layouts e temas, mantendo 640x480.
- Tema Force Jedi/Sith: slide de Novos/Em Breve exibe apenas capa, sem nome do jogo, data ou selo Adicionado ao catalogo.
- Tema Force Jedi/Sith: Top 5 Downloads exibe capas, posicoes e contagens, sem nomes dos jogos sobre as capas.
- Sobre > Licencas abre lista informativa somente leitura (GPL-3.0, LÖVE, 7-Zip, LuaQRCode, fontes e NOTICE), com B retornando ao menu Sobre.
- Atualizacao geral incorpora temas oficiais e os temas opcionais ja instalados, preservando configuracoes, catalogos separados, SD1/SD2, autoria e licencas.

## [0.0.27-beta] - 2026-11-17

- Atualizacao conjunta dos seis temas da R36S ROMS STORE em uma unica atualizacao geral (issue #25).
- Temas internos: Padrao 1.0.1, Neon Grid 4.0.1, Wii Blue 1.0.1, Pastel 1.0.1, Jedi 1.0.12.
- Temas opcionais em theme_packages incluidos automaticamente no mesmo pacote, mas atualizados somente se ja instalados no console; Sith 1.0.12.
- Compatibilidade, ausencia de downgrades e preservacao de temas personalizados verificadas por teste Lua com love.filesystem simulado.
- QA da logo completa com bandeira, geometria 640x480 para os seis cabecalhos e capturas reais HTML Jedi/Sith disponiveis como artifact no GitHub Actions.
- Central de Conteudo, catalogos independentes, configuracoes SD1/SD2, licencas e creditos preservados.

## [0.0.26-beta] - 2026-11-17

- Arquivo-fonte da logo substituido pela arte aprovada: BR prateado e pequena bandeira brasileira, sem utilizar a antiga versao verde/amarela.
- Header agora apresenta a marca COMPLETA em 140x40, com proporcao original 3,36:1 da arte 1000x298; a versao anterior cortava 71% da imagem e exibia so o console.
- Titulos posicionados a partir da largura real da logo: Jedi/Sith x>=180, demais cabecalhos x>=168/170, sem sobreposicao.
- Assets do menu, Sobre e splash regenerados da fonte correta com alfa transparente e sem distorcao.
- Jedi/Sith 1.0.11 com HTMLs, backgrounds e previews atualizadas; demais temas integrados recompilados no game.love.
- Atualizacao geral sincroniza automaticamente Sith ja instalado atraves do pacote interno, sem instalar temas opcionais nao selecionados e sem rebaixar versoes mais novas.
- Preservados todos os creditos e licencas, catalogos separados, Top 5, Cloudflare, SD1/SD2 e configuracoes.

## [0.0.25-beta] - 2026-11-17

- Corrigida sobreposicao do nome do aplicativo/tema na logo do cabecalho, observada no console.
- Force Jedi/Sith: nome R36S PORTS BR STORE HUB e edicao deslocados para x=116, deixando area exclusiva para a logo do console à esquerda.
- Cabecalho comum e modos Neon Grid, canais e xdash: titulos e versoes comecam no minimo em x=112; divisor e avisos acompanham.
- Fontes HTML e previews Jedi/Sith atualizadas para espelhar o mesmo alinhamento; temas 1.0.10.
- Logo oficial com bandeira preservada. Nenhuma mudanca no Top 5, atalhos, catalogos, controles, Cloudflare ou SD1/SD2.
- Backups anteriores preservados em ambos repositorios.

## [0.0.24-beta] - 2026-11-17

- Corrigida a logo minuscula do cabecalho em TODOS os temas, confirmada nas fotos reais do console (Force Sith e Neon Grid).
- Icone do console com nuvem agora usa asset de 42x38 com 2px de margem, ampliando significativamente a arte util (antes 46x32 com 4px de margem).
- Em todas as telas, a imagem oficial global (BR cromado com bandeira brasileira) tem prioridade sobre arquivos antigos incluidos nos temas instalados.
- O cabecalho Force Jedi/Sith e redesenhado em runtime mesmo com fundo HTML de tema antigo, impedindo arte velha ou esverdeada de aparecer.
- Removido filtro hue-rotate da logo azul no HTML Sith/Jedi, antes responsavel por altera-la de cor.
- Posicao do logo generico corrigida dentro do cabecalho de 40px, com reserva de margem de seguranca e texto ao lado.
- Logo completa mantida sem cortes no menu, Sobre e splash. Creditos/dev logo, catalogos, ranking, Cloudflare, SD1/SD2 preservados.
- Temas Jedi/Sith v1.0.9 com previews atualizadas. Testes automatizados verificam tamanho, visibilidade, prioridade global e ausencia de filtro.

## [0.0.23-beta] - 2026-11-17

- Logo oficial trocada para a variante R36S PORTS BR STORE HUB com BR prateado igual ao PORTS e bandeirinha do Brasil, como aprovada pelo usuario.
- A variante sem bandeira fica arquivada em tools/brand/logo_alternativa_sem_bandeira.webp para futuras trocas; nao e exibida no app.
- Nova fonte oficial RGBA transparente em tools/brand/logo_oficial_cloud.webp, com contorno azul/ciano e enquadramento anti-recorte.
- PNGs de cabecalho, menu, Sobre, abertura e launcher atualizados em todos os temas inclusos e nos pacotes Force Jedi/Sith, sem mudar visual ou controles.
- Tela Sobre: logo ampliada em aproximadamente 13%, usando variante about e posicao x26 y66; limites de escala impedem invadir painel Telegram e cartao do desenvolvedor.
- O HTML e o renderer Force usam exatamente o icone atualizado para suas previews, mantendo 640x480.
- Temas Force Nexus Jedi/Sith 1.0.8; backup anterior em ambos repositorios, fontes e creditos GPL preservados.
- Nenhuma mudanca em catalogos, download, jogos, Cloudflare ou SD1/SD2.

## [0.0.22-beta] - 2026-11-17

- Corrigidos recortes das logos oficiais no proprio projeto, em todos os temas.
- Gerador de marcas agora preserva uma margem transparente segura em todos os lados das imagens header, menu, Sobre, splash e icone launcher; mantém proporção, logo aprovada e BR brasileiro.
- Corrigido o desenho no LÖVE: cabecalhos com escala 1.3 ultrapassavam a faixa de 40px; agora o tamanho respeita o limite fisico de cada tela, inclusive temas claros, Force e menu.
- Preview Jedi/Sith usa o mesmo PNG do cabeçalho do jogo; evita diferença entre referencia HTML e arte instalada.
- Novos testes verificam alpha das bordas, dimensoes, copies por tema, escala Lua e icon dos previews.
- Jedi/Sith atualizados para 1.0.7, apenas ajustes de logos; Top 5, atalhos, catalogos, SD1/SD2 e creditos sem alteracoes.
- Backups anteriores mantidos nos dois repositorios.

## [0.0.21-beta] - 2026-11-17

- Nova logo oficial R36S PORTS BR STORE HUB: console azul com nuvem de download, R36S metalico e BR com motivos do Brasil; a arte aprovada e mantida, com bordas transparentes suaves.
- Logo otimizada para cabeçalho (46x32, icone), menu (218x74), Sobre (132x62) e abertura (252x170), sem esticar a proporcao.
- Gerador reproducivel em tools/make_brand_logos.py com a fonte original em tools/brand/logo_oficial_cloud.webp; build e temas geram variantes PNG RGBA.
- Aplicacao a todos os temas inclusos (Padrao, Neon Grid, Wii Blue, Pastel e Force Jedi), e aos pacotes Jedi e Sith de temas 1.0.6, preservando as cores e layouts existentes.
- Atualizadas as duas fontes HTML Jedi/Sith com o icone oficial e suas novas previews.
- No topo do Force, o icone da nuvem acompanha o nome que ja e exibido ao lado.
- Logos e creditos dos desenvolvedores terceiros preservados; nenhum catalogo, download, Cloudflare ou regra SD1/SD2 alterado.

## [0.0.20-beta] - 2026-11-17

- Corrigida sobreposicao dos titulos "Top Downloads" e "Central de Conteudo" no ranking dos temas Jedi/Sith.
- Tela Force desenha o proprio cabecalho uma unica vez antes dos paineis de capas; visual e texto do ranking preservados.
- Demais temas continuam usando seu cabecalho original e a tela de ranking sem modificacoes.
- A correcao pertence ao codigo do aplicativo; os temas Jedi/Sith permanecem na versao 1.0.5.
- Dados de catalogos, ranking, capas, Cloudflare, SD1/SD2 e creditos preservados.

## [0.0.19-beta] - 2026-11-17

- Force Nexus V6 aplicado nos dois temas Jedi/Sith: atalhos Meus Ports, Favoritos e Downloads mais altos e melhor alinhados, com folga inferior.
- Favoritos usa uma estrela vazada fixa, inclusive ao selecionar.
- Cabeçalho: R36S PORTS BR STORE HUB; edicao Jedi/Sith com sua versao 1.0.5 na mesma fonte/cor.
- Removidas as setas laterais do carrossel; indicadores e controle L1/R1 preservados.
- Top 5 Downloads na Central de Conteudo agora mostra miniaturas reais e capa ampliada do port selecionado (apenas nesses dois temas).
- Dados de ranking continuam reais, com isolamento entre catalogos do Lira e R36S ROMS STORE, incluindo fallback para capas ainda nao baixadas.
- Outros layouts, jogos, Cloudflare, SD1/SD2, licencas e creditos preservados.

## [0.0.18-beta] - 2026-11-17

- Temas Jedi e Sith com layout aprovado V3 (HTML demonstrativo).
- Seis cartoes de menu reduzidos e posicionados na parte superior direita, em grade 3x2.
- Top 5 Downloads movido para a parte inferior direita, com cinco capas de 78x134 px.
- Aba NOVIDADES renomeada para NOVOS e preservada aba EM BREVE.
- Carrossel sem contagem numerica e sem selos de NOVO/EM BREVE sobre a arte; indicadores centralizados e mais legiveis.
- Navegacao do direcional ajustada: do menu inferior desce para Top 5 e do Top 5 sobe para a segunda fileira.
- Fundos 640x480 e sprites de selecao 405x168 gerados diretamente dos HTMLs, para ambos temas.
- Temas Force Nexus 1.0.4 publicados individualmente, sendo necessario atualizar a STORE uma vez para o novo posicionamento Lua.
- Dados reais do catalogo, Top 5, outros temas, creditos, Cloudflare, SD1/SD2 e backup preservados.

## [0.0.17-beta] - 2026-11-17

- Force Nexus Jedi/Sith: painel esquerdo agora alterna entre NOVIDADES e EM BREVE, conforme a demonstracao HTML aprovada.
- NOVIDADES usa apenas jogos com download liberado e data de inclusao real, em ordem decrescente; aceita anuncios novos no campo news.
- EM BREVE lista apenas jogos do catalogo selecionado que ainda nao possuem link de download; nenhum anuncio ficticio.
- Abas acessiveis pelo D-pad, A e X; L1/R1 percorre as capas. Ausencia de anuncios exibe mensagem verdadeira.
- Preservados Top 5 ampliado, seis cartoes, cores e background HTML 640x480 em Jedi e Sith.
- Jedi agora aceita atualizacoes de temas individuais sem substituir arquivos inclusos. Pacote mais novo em user_themes prevalece e o incluso permanece como reserva.
- Temas Jedi/Sith 1.0.3 distribuidos separadamente; todos os outros temas, catalogos e instalacao SD1/SD2 preservados.

## [0.0.16-beta] - 2026-11-17

- Temas Force Nexus Jedi e Sith alinhados aos conceitos HTML V4 sem os textos INÍCIO e LAYOUT 640×480.
- Top 5 Downloads ampliado para ocupar a faixa superior disponível: painel na posição y=58 com altura 158 px (antes y=92 e 124 px).
- Cinco capas aumentadas para 78×106 px (antes 74×82 px), preservando a grade 5×1 e o restante dos seis atalhos.
- Os dois HTMLs fonte foram atualizados para que fundos e previews regenerados também reflitam o novo desenho.
- Temas atualizados para 1.0.2 e publicados separadamente no catálogo de temas, mantendo Jedi padrão inicial e Sith independente.
- NEON GRID, outros temas, catálogos, integridade de download, atualizador cumulativo, dados SD1/SD2 e créditos preservados.

## [0.0.15-beta] - 2026-11-17

- Corrigida a aparencia dos temas Force Nexus Jedi/Sith, reproduzindo os conceitos HTML V4 aprovados.
- Removido integralmente o bloco "Em destaque" da tela inicial desses dois temas.
- Estrutura real do HTML V4: carrossel vertical de quatro ports recentes (esquerda), Top 5 Downloads em uma linha e seis botoes grandes 3x2.
- Fundos, logos, tipografia, cores, gradientes e selecao dos seis botoes agora sao gerados a partir dos HTMLs V4 originais.
- O aplicativo desenha dados reais por cima do fundo: capa atual, nome dos ports, ranking Cloudflare e estado de rede/bateria/hora.
- Carrossel com selecao por direcionais e L1/R1; nenhum dado de exemplo dos HTMLs aparece como jogo real no console.
- Temas Force Nexus atualizados para 1.0.1; Sith segue baixavel individualmente pela Loja de Temas.
- NEON GRID, Wii Blue, Pastel Pop, Padrao, backup, creditos GPL-3.0, catalogos e SD1/SD2 preservados.

## [0.0.14-beta] - 2026-11-17

- Atualizacao online cumulativa: consoles antigos passam diretamente para a versao mais recente com pacote completo.
- Clientes novos escolhem automaticamente pacote incremental somente se a versao-base for compativel; caso contrario usam o completo.
- O feed publico usa por padrao url/sha256/size do pacote completo para atender tambem as versoes antigas da STORE.
- URL, tamanho, SHA-256 e limites do incremental agora ficam em campos proprios, sem restringir o ZIP completo.
- Testes automatizados cobrem 0.0.10, 0.0.11 e 0.0.12 com fallback completo e 0.0.13 com incremental.
- Verificacoes de integridade, backup, restauracao, temas, catalogos e SD1/SD2 preservados.

## [0.0.13-beta] - 2026-11-17

- Backup previo em branches separadas dos repositorios de codigo e atualizacoes.
- Force Nexus — Jedi como tema padrao em novas instalacoes, sem modificar preferencias ja salvas.
- Force Nexus — Sith como novo tema independente; quatro temas anteriores preservados.
- Painel inicial Sith/Jedi 640x480 com ports reais, Top 5 Downloads por catalogo e atalhos.
- Loja online de temas com catalogo separado, cache offline, download individual e atualizacoes.
- Instalacao segura com SHA-256, verificacao de ZIP, bloqueio de links e caminhos inseguros.
- Backup e restauracao durante atualizacoes de temas; remocao protegida sem atingir temas inclusos.
- Rolagem na tela Configuracoes > Temas; previas e progresso de download.
- Creditos originais, GPL-3.0, catalogos de jogos e caminho SD1/SD2 preservados.

## [0.0.12-beta] - 2026-11-17

- Tela Top 5 na Central de Conteudo, com ranking independente para Lira e R36S ROMS STORE.
- Cada catalogo utiliza seu proprio cache local, sem misturar estatisticas.
- Descoberta automatica da URL Cloudflare via stats_api.json publico (inicialmente desativada).
- Catálogo R36S ROMS STORE separado, com Aestheta e Alice in Clicheland, versao 1.0 e arquivos SHA-256 verificados.
- Codigo do Worker reforcado: verificacao de jogos autorizados, deduplicacao, bloqueio de POST por padrao e rate limit ponderado por evento.
- A publicacao na conta Cloudflare e a ativacao de POST exigem testes adicionais e nao fazem parte desta atualizacao do console.
- Temas existentes e caminhos de instalacao SD1/SD2 preservados.

## [0.0.11-beta] - 2026-11-16

- Infraestrutura do contador global de downloads: catalogos separados e ranking Top 5 do servidor.
- Registro de cada novo download de jogo concluido, incluindo reinstalacoes no mesmo console.
- Fila de eventos persistida no SD com reenvio em segundo plano e sem duplicacao no servidor.
- Backend Cloudflare Workers + D1 opcional, desativado ate haver uma URL HTTPS configurada.
- Sith e Jedi permanecem conceitos HTML; nenhuma alteracao de tema foi aplicada.

## [0.0.10-beta] - 2026-11-16

- Popup automático de atualização na tela inicial, somente quando a STORE encontra uma versão nova na internet.
- O botão Atualizar agora inicia o download online; Agora não fecha o popup. A instalação continua exigindo confirmação e SHA-256.
- Aviso deslizante mantido como lembrete discreto; popup mostrado uma vez por abertura, sem interromper outros diálogos.
- Atualizações futuras publicadas pelo GitHub Actions com ZIP incremental e código-fonte GPL-3.0, preservando catálogos e SD1/SD2.

## [0.0.9-beta] - 2026-11-16

- Corrigido o alinhamento vertical da `dev_logo` na tela Sobre.
- Aumentadas em 30% as logos da página inicial dos temas Neon Grid Edition, Wii Blue Edition e Pastel Pop Edition, ajustando o posicionamento do texto.
- Pacote `UPDATE.zip` incremental 0.0.8-beta → 0.0.9-beta com apenas `game.love` e manifesto de integridade.
- Distribuição pelo canal público de atualização online, preservando todos os catálogos, temas, configurações e SD1/SD2.

## [0.0.8-beta] - 2026-11-16

- Atualizador configurado para consultar o feed de Releases público da R36S ROMS STORE.
- Pacote de atualização incremental 0.0.7-beta → 0.0.8-beta: compara SHA-256 com a instalação 0.0.7-beta publicada, incluindo apenas arquivos alterados.
- Manifesto limitado à base 0.0.7, validado pelo gerenciador Lua; backup e restauração preservados.
- Instalador completo e código-fonte continuam sendo fornecidos separadamente; Release só será publicada após testes no console.

## [0.0.7-beta] - 2026-11-16

- Adaptados os seis scripts auxiliares de BIOS/hardware/artes: `fdtparse.py`, `fdt2.py`, `fdt3.py`, `mkconsoledb.py`, `mkbiosdb.py` e `mkart.py`.
- Removidos caminhos absolutos antigos dos geradores; entradas agora são configuráveis com parâmetros, e não há clonagem/download automático de fontes externas.
- Bases de assinaturas e BIOS geradas em `build/generated-data/`; as bases ativas permanecem inalteradas.
- Gerador de artes configurado para nossa logo e identidade moderna, com prévias em `build/generated-assets/art/`; imagens ativas intactas.
- Guardados os seis scripts originais completos em `docs/preservacao/original/tools/`, mantendo créditos e licença GPL-3.0.
- Incluídos testes de DTB sintético, geração de assinaturas, BIOS e artes, além de bloqueios de sobrescrita dos arquivos ativos.

## [0.0.6-beta] - 2026-11-16

- Restaurados os 30 arquivos ausentes do projeto original, incluindo manuais, seis imagens historicas, catálogos, scripts de teste e ferramentas FDT/BIOS/arte.
- Preservadas as modificacoes proprias de interface, temas, instalador, SD1/SD2, catalogos e versionamento.
- Adicionada copia offline integral do catalogo Lira, com fallback apenas quando selecionado e sem dados locais/cache.
- Desativado com seguranca o importador legado que podia substituir o repositorio inteiro; original arquivado.
- Publicador do projeto de origem preservado em arquivo, sem comandos de publicacao ativos.
- Inventario detalhado de 138 arquivos adaptados e 20 arquivos novos, com teste de preservacao no GitHub Actions.

## [0.0.5-beta] - 2026-11-15

- Organização do versionamento e do histórico de entregas, após as alterações acumuladas na versão 0.0.4-beta.
- Scripts de desenvolvimento Python e Shell recuperados e adaptados do R36S PORT HUB.
- Geração de pacotes ZIP com manifesto SHA-256 validado e nome derivado da versão atual.
- Inclusão de verificação automatizada de consistência e ferramenta para incrementar versões futuras.

## [0.0.4-beta] - 2026-11-15

- Base de desenvolvimento anterior à padronização do versionamento.
- Identidade própria R36S ROMS STORE, com créditos e licença GPL-3.0.
- Catálogos separados e seleção de SD1/SD2 preservados.
- A numeração 0.0.4-beta foi usada em várias entregas anteriores; essas mudanças não foram numeradas individualmente.

> Este histórico não declara versões intermediárias que não foram efetivamente publicadas.
