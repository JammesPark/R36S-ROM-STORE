# R36S ROM HUB STORE

**Status:** versão 0.7.0-beta — beta oficial.

Aplicativo independente para consoles R36S/R36H, com interface Lua e LÖVE 11.5. Catálogo próprio de ROMs, instalação SD1/SD2, favoritos, BIOS, temas e ferramentas. Inclui os temas Pulse Edition e Matrix Edition, baseados no trabalho de Lag do Lira.

## Instalação e atualização

- Instalação inicial: baixe o ZIP sem o sufixo OTA nas [Releases do canal oficial](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases), extraia na pasta ports do cartão e execute `R36S ROMS STORE.sh`.
- Atualização: use o menu de atualização da loja, com conexão à internet e confirmação antes de instalar. Faça backup da instalação e das configurações.
- O runtime LÖVE 11.5 do console é necessário. O catálogo próprio é obtido pelo canal dedicado, com validação e recuperação da última cópia válida no SD. Em uma instalação nova sem cópia local, a primeira sincronização exige conexão.
- A versão aprovada em console foi a Experimental 0.6.7-beta; a publicação oficial altera a identificação, a versão e reativa o feed OTA. A compatibilidade com todos os firmwares, telas e consoles não está certificada.

## Novidades

- Nova identidade visual R36S ROM HUB STORE, com logos PNG atualizadas e título de abertura corrigido.
- Pulse Edition e Matrix Edition: dois temas integrados, créditos a Lag do Lira, cores personalizadas independentes e azul como paleta original do Pulse.
- Matrix: painel de catálogo, menu 3×3, atalhos Downloads, Favoritos e Instalados, logo ampliada à direita e indicadores à esquerda.
- Pulse: logo centralizada com o menu. Sobre: logo e textos do Telegram ampliados.
- Catálogo próprio remoto com validação e cópia local de segurança; modos Lista, Grade e Vitrine nos dois temas, seleção L2/R2 e etiquetas regionais.
- Configurações e Utilitários em painel lateral; Temas Store, detalhes de ROM e instalados pela loja.
- Preservados SD1/SD2, controles testados, licenças e créditos; atualização automática pelo canal oficial reativada.

Veja [CHANGELOG.md](CHANGELOG.md) e [documentação do catálogo](docs/CATALOGO_ONLINE_EXPERIMENTAL.md). O canal de dados continua separado do OTA, preservando a fonte já testada. A branch experimental permanece para futuras validações.

## Código-fonte

Execute `sh tools/build.sh` para gerar o pacote. O GitHub Actions valida LuaJIT, os testes e a integridade dos ZIPs. A main publica o instalador; o canal de atualizações prepara e verifica o pacote OTA antes de ativar o feed.

## Autoria e licença

Baseado no **R36S PORT HUB, por [Lag do Lira](https://youtube.com/@lagdolira)**. Pulse Edition e Matrix Edition são adaptações de temas originais de Lag do Lira; autoria e créditos preservados. Código sob GNU GPL-3.0, conforme LICENSE, NOTICE.md e avisos de terceiros. Use somente conteúdos para os quais tenha direito de download e distribuição.

## Contributors

- **[JammesPark](https://github.com/JammesPark)** — criador e responsável pelo projeto.
- **[ChatGPT (OpenAI)](https://chatgpt.com/)** — colaboração no desenvolvimento assistido por IA desde o início do projeto.
- **[Lag do Lira](https://youtube.com/@lagdolira)** — autor do projeto-base e dos temas originais.

Veja o [registro completo de contribuições](CONTRIBUTORS.md), incluindo a atribuição das contribuições anteriores e futuras.
