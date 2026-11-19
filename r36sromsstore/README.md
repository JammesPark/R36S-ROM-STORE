# R36S ROMS STORE

Loja independente para o R36S com catalogo local de ROMs, construída como uma versão modificada do projeto de Lag do Lira, publicada sob **GPL-3.0**.

> **Baseado no R36S PORT HUB, por Lag do Lira**  
> https://youtube.com/@lagdolira

**Status:** versão 0.6.6-beta com identificadores internos R36SBR; o catálogo próprio e a distribuição de atualizações aponta para o canal público oficial. Não é uma versão oficial do projeto original.

## Instalação (SD1)

1. Extraia o conteúdo do ZIP de instalação na pasta `/roms/ports/` do cartão do console.
2. Execute `R36S ROMS STORE.sh` pelo EmulationStation.
3. O runtime LÖVE 11.5 do PortMaster precisa estar instalado no sistema.

A loja permite selecionar SD1 ou SD2 ao instalar ports. A identificação em Meus Ports, a proteção contra sobreposição e o Analisador SD1/SD2 foram mantidos.
A loja em si usa um diretório próprio: `r36sromsstore/`, separado do projeto original, e não o substitui.

## Fontes de download e atualização

A URL de atualizações (C.UPDATE_URL) usa o repositório público R36SPORTSBR-STORE-UPDATES, separado do desenvolvimento. O catálogo R36S BR mantém URL configurável. Configure URLs próprias em `config.lua` ou nos arquivos de URL descritos nessa configuração. O catálogo local inicial está vazio. A URL de BIOS também não está definida.

## Código-fonte e licença

Distribuído sob **GNU GPL-3.0**. O código Lua editável deve acompanhar as distribuições desta versão. Veja `source/` no pacote de código-fonte, `LICENSE` e `NOTICE.md`. Conserve todos os créditos de autoria e licenças de terceiros. Código-fonte da base: https://github.com/liralflsti-wq/r36s-port-hub

## Avisos

A R36S ROMS STORE é independente do projeto de origem. Não está afiliada aos fabricantes do dispositivo, à equipe PortMaster ou aos titulares dos direitos sobre jogos. O usuário deve respeitar a licença de cada conteúdo instalado.

## Alteracoes tecnicas 0.0.4-beta

Os identificadores internos de ambiente (`R36SBR_*`), logs e novos arquivos temporarios usam a identidade da R36S ROMS STORE.
As rotinas preservam leitura de alguns marcadores legados para reconhecer temas e recuperar uma operacao do PortMaster interrompida; isso nao reutiliza a identidade visual antiga.
Autores dos temas e ferramentas herdados continuam creditados.

**Pendencias visuais, a pedido do responsavel pela loja:** alterar depois o rotulo `PORT HUB` na tela de informacoes do console e revisar as imagens que ainda exibam a marca antiga.


Fontes de download: o catalogo do Lag do Lira continua disponivel e pode ser alternado com o catalogo R36S ROMS STORE em Configuracoes > Catalogo. BIOS e runtimes preservados; fonte de atualização aponta para nosso canal público de Releases; a publicação de cada versão continua manual. Meus Ports pode desinstalar ports manuais do SD1 ou SD2, com verificacao do script e pasta e confirmacao antes de apagar.
