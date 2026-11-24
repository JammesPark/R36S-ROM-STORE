<p align="center">
  <img src="game/assets/logo/logo_splash.png" alt="R36S ROM HUB STORE — logo oficial" width="290">
</p>

<h1 align="center">R36S ROM HUB STORE</h1>

<p align="center"><strong>Sua central de jogos retrô</strong><br>ROMs, BIOS, temas e ferramentas direto no console.</p>

<p align="center">
  <a href="https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest"><img alt="Versão oficial" src="https://img.shields.io/github/v/release/JammesPark/R36S-ROMS-HUB-STORE-UPDATES?style=for-the-badge&color=2563eb&label=Vers%C3%A3o"></a>
  <img alt="R36S" src="https://img.shields.io/badge/Console-R36S-0891b2?style=for-the-badge">
  <img alt="LÖVE 11.5" src="https://img.shields.io/badge/L%C3%96VE-11.5-db2777?style=for-the-badge">
  <a href="LICENSE"><img alt="GPL-3.0" src="https://img.shields.io/badge/Licen%C3%A7a-GPL--3.0-16a34a?style=for-the-badge"></a>
</p>

<p align="center">
  <a href="https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest"><strong>⬇ Baixar versão oficial</strong></a> ·
  <a href="#instalação">Instalação</a> ·
  <a href="#funcionalidades">Funcionalidades</a> ·
  <a href="#contributors">Contributors</a>
</p>

**Status:** versão 0.7.0-beta — beta oficial.

> **BETA:** a loja está em desenvolvimento. A compatibilidade com todos os consoles, firmwares e resoluções ainda não está certificada. A edição experimental de tela é separada do canal oficial.

---

## ⬇ Downloads

| Pacote | Destino |
|---|---|
| Instalação completa | [Última versão oficial](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest) — ZIP sem o sufixo OTA |
| Atualização | Menu de atualização da própria loja, com conexão à internet |
| Histórico | [Releases oficiais](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases) |

O endereço da última versão é permanente. Os nomes dos arquivos ZIP incluem o número da versão. A edição experimental não é publicada pelo canal OTA oficial.

## Sobre o projeto

O **R36S ROM HUB STORE** é um aplicativo independente para consoles portáteis R36S/R36H, desenvolvido em Lua e LÖVE 11.5, com interface para os botões físicos do console. Permite consultar um catálogo online, baixar e instalar ROMs em SD1 ou SD2, organizar favoritos, gerenciar BIOS e temas e utilizar ferramentas do sistema.

O catálogo é separado das atualizações do aplicativo. Uma nova ROM ou capa pode ser adicionada sem instalar uma nova versão da loja. Uma cópia local válida é preservada se a sincronização falhar.

## 🎨 Temas

| Pulse Edition | Matrix Edition |
|:---:|:---:|
| Paleta azul original | Paleta verde original |
| Logo centralizada e menu principal | Painel de catálogo e menu 3×3 |
| Lista, Grade e Vitrine | Lista, Grade e Vitrine |

Os dois temas são integrados à loja, com personalização de cores independente. São adaptações de temas originais de Lag do Lira.

As capturas atualizadas da interface serão adicionadas após conferência das telas da versão atual. Imagens antigas do projeto-base não são utilizadas nesta apresentação.

## Funcionalidades

| Recurso | Descrição |
|---|---|
| Catálogo de ROMs | Sistemas, capas, detalhes, pesquisa e favoritos. |
| Visualização | Modos Lista, Grade e Vitrine em Pulse e Matrix. |
| Instalação SD1/SD2 | Seleção do cartão de destino e gerenciamento dos instalados pela loja. |
| Downloads | Central de fila e progresso, com velocidade e controles de download. |
| BIOS | Área dedicada ao gerenciamento das BIOS. |
| Temas Store | Área de temas do console. |
| Configurações | Painéis de configuração e personalização da interface. |
| Utilitários | Ferramentas de apoio e diagnóstico, incluindo recursos herdados do R36S PORT HUB, por Lag do Lira. |
| Atualização online | Verificação do feed oficial, confirmação e validação antes da instalação. |
| Catálogo offline | Recuperação da última cópia local válida após falha de rede ou validação. |

## Instalação

1. Baixe o ZIP completo (sem o sufixo OTA) nas [Releases oficiais](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES/releases/latest).
2. Extraia o conteúdo na pasta `ports` do cartão de destino.
3. Confira se o launcher e a pasta do aplicativo estão juntos:

   ```text
   ports/
   ├── R36S ROMS STORE.sh
   └── r36sromsstore/
   ```

4. Reinicie o EmulationStation, se necessário, e execute a loja na seção Ports.
5. Conecte o console à internet para a primeira sincronização do catálogo.

**Requisito:** runtime LÖVE 11.5 disponível no console. Faça backup da instalação e dos cartões antes de substituir arquivos.

## Atualizações

Use o menu de atualização da loja e confirme a instalação após a verificação do pacote. O feed oficial está no [repositório de atualizações](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES).

Não instale uma edição experimental sobre a instalação oficial sem backup. As edições experimentais podem ter restrições de compatibilidade e não devem ser confundidas com o canal de produção.

## Controles

Use o direcional para navegar, A para confirmar e B para voltar. As demais ações dependem da tela e são indicadas no rodapé da interface. No catálogo, Y solicita a atualização dos dados; L2/R2 alternam os modos de visualização nas telas que oferecem esse recurso.

## Documentação

| Documento | Conteúdo |
|---|---|
| [CHANGELOG.md](CHANGELOG.md) | Histórico de versões e mudanças |
| [CONTRIBUTORS.md](CONTRIBUTORS.md) | Registro das contribuições anteriores e futuras |
| [NOTICE.md](NOTICE.md) | Autoria e avisos |
| [LICENSE](LICENSE) | Licença GPL-3.0 |

O manual e os documentos técnicos herdados estão em `docs/` e serão revisados para refletir a loja de ROMs; não devem ser interpretados como instruções atualizadas quando mencionarem o antigo PORT HUB.

## Estrutura do projeto

```text
game/             Código-fonte Lua/LÖVE, temas e recursos
r36sromsstore/    Arquivos de instalação no console
tools/            Build e ferramentas de apoio
tests/            Testes automatizados
docs/             Documentação
design/           Protótipos visuais
services/         Serviços auxiliares
.github/          GitHub Actions
```

Para gerar o pacote, execute `sh tools/build.sh`. O GitHub Actions valida LuaJIT, os testes e a integridade dos ZIPs.

## Contributors

- **[JammesPark](https://github.com/JammesPark)** — criador, responsável pelo projeto, direção visual e testes no console.
- **[ChatGPT (OpenAI)](https://chatgpt.com/)** — colaboração no desenvolvimento assistido por IA desde o início do projeto.
- **[Lag do Lira](https://github.com/liralflsti-wq/r36s-port-hub)** — autor do projeto-base, dos temas originais e de ferramentas herdadas do R36S PORT HUB.

Veja o [registro completo das contribuições](CONTRIBUTORS.md).

## Autoria, licença e uso responsável

Baseado no **R36S PORT HUB, por [Lag do Lira](https://youtube.com/@lagdolira)**. Pulse Edition e Matrix Edition são adaptações dos temas originais do autor, com créditos preservados. Parte das ferramentas e dos utilitários também foi herdada ou adaptada do projeto-base; sua autoria original é de Lag do Lira, respeitados os créditos e as licenças de componentes de terceiros.

Código sob GNU GPL-3.0, conforme [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) e avisos de terceiros. A licença do aplicativo não concede direitos sobre ROMs, BIOS, capas ou outros conteúdos de terceiros. Utilize somente arquivos para os quais tenha direito de acesso, download e distribuição.

<p align="center"><strong>R36S ROM HUB STORE</strong><br>Desenvolvimento colaborativo para a comunidade retrô.</p>
