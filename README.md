# R36S ROMS STORE — v0.2.0 (teste)

A interface aprovada da apresentação HTML 640×480 foi convertida para **Lua + LÖVE 11.5** e integrada ao aplicativo real. O catálogo único continua sendo o **GameStoreBR**, consultado pela API `r36swiki.com/getgames.php`. Nenhuma ROM ou BIOS é incluída.

## Interface e funcionalidades

- **Novo tema moderno:** menu lateral fixo, painel principal à direita e grade de **3 colunas x 2 linhas** com capas, miniaturas geométricas de reserva e rolagem da página atual.
- **Telas e fluxos:** entrada, início, catálogo, pesquisa, detalhes, confirmação/seleção SD, download, conclusão, histórico, instalados, favoritos, configurações, idiomas, temas, armazenamento, rede, sobre, ajuda e tela sem conexão.
- **4 idiomas:** Português do Brasil, inglês, espanhol e russo. A fonte para cirílico é procurada no sistema; sem fonte compatível, o console poderá exibir caracteres ausentes.
- **7 cores:** Azul Oceano, Roxo Neon, Verde Esmeralda, Laranja Âmbar, Rosa Sunset, Vermelho Coral e Branco Gelo. Seleção salva em `state/roms_settings.json`.
- **Favoritos persistentes:** `state/roms_favorites.json`, com indicador SD1, SD2, ambos ou não baixado, obtido do registro de download e da existência do arquivo no cartão.
- **Capas reais quando disponíveis:** baixadas por `bin/gamestore_source.py covers` para `state/covers/`, respeitando tamanho máximo; caso não haja rede, mostra ilustração geométrica.
- **SD1/SD2:** as ROMs são salvas sem extração em `/roms/<plataforma>/` ou `/roms2/<plataforma>/`. Arquivos existentes não são substituídos.
- O fluxo preserva o histórico de downloads e os manifestos legados de instalações de ports, sem instalar nem incluir esses ports no catálogo.

## Instalação para testar no console

Baixe o artefato **R36S-ROMS-STORE-TESTE** da execução mais recente do GitHub Actions. Ele contém o instalador `R36S_ROMS_STORE_v0.2.0_TESTE.zip` e o código-fonte `R36S_ROMS_STORE_FONTE.zip`.

Extraia o conteúdo do ZIP instalável dentro de **`/roms/ports/` no SD1**. O launcher se chama **`R36S ROMS STORE.sh`**. O diretório técnico `r36s-store-kpm/` continua o mesmo, para preservar preferências/logs do aplicativo anterior. **Remova apenas o launcher antigo `R36S PORTS BR STORE KPM.sh` da pasta `/roms/ports/`**, se estiver presente, para evitar um ícone duplicado no menu. Não apague a pasta `r36s-store-kpm/state/`.

Requer **PortMaster com runtime LÖVE 11.5**, Python 3, Bash e acesso à internet para atualizar o catálogo (o último JSON da listagem fica salvo no cache). O runtime e o catálogo não são incorporados ao ZIP. A disponibilidade dos servidores GameStoreBR não foi confirmada no hardware.

## Controles do R36S

- **A:** entrar/confirmar; **B:** voltar.
- **L/R:** trocar as áreas principais; **direcional:** selecionar categorias, ROMs e opções.
- **Catálogo:** esquerda na primeira coluna ativa as categorias da esquerda; **START** abre a pesquisa, **Y** sincroniza e **X** favorita/desfavorita.
- **Detalhes:** **A** vai para a confirmação de download; **X** favorita.
- **Confirmação:** **X** ou esquerda/direita alterna SD1/SD2 antes do download.
- **Configurações:** seleção de idioma, cor do tema, cartão e rede com gravação local.

## Debug

Se fechar antes de exibir a interface, verifique `r36s-store-kpm/log.txt` e `r36s-store-kpm/state/logs/startup.log`. O launcher usa a configuração de runtime `love_11.5/love.txt` do PortMaster. Alguns sistemas podem precisar de uma fonte Unicode (DejaVu Sans / Noto Sans) já instalada para russo.

Testes automatizados verificam o código Lua/Bash/Python, telas, preferências, API simulada, downloads/manifestos, SD1/SD2 e o empacotamento. **O hardware R36S ainda precisa de validação real.**

## Licenciamento e origem

O código da interface aqui foi criado para este projeto. A API GameStoreBR e suas capas são externas; os arquivos do aplicativo GameStoreBR não foram copiados. Respeite os direitos de cada jogo, imagem e arquivo disponibilizado na API.

## Ajuste v0.2.1 — Navegação do menu inicial

Corrigida a entrada involuntária no catálogo: **cima/baixo** movem o destaque na coluna lateral, **esquerda/direita** alternam o foco entre menu e conteúdo, **A** confirma a opção destacada e **B** volta ao menu. O catálogo não deve mais abrir por um simples movimento do direcional. O teste automatizado simula teclado e D-pad para evitar regressões.
