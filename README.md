<p align="center">
  <img src="port/r36sromstore/logo_hd.png" alt="R36S ROM STORE — logo oficial" width="340">
</p>

<h1 align="center">R36S ROM STORE</h1>

<p align="center"><strong>Sua central de jogos retrô</strong><br>ROMs, BIOS, temas e ferramentas direto no console.</p>

<p align="center">
  <a href="https://github.com/JammesPark/R36S-ROM-STORE/releases/latest"><img alt="Versão oficial" src="https://img.shields.io/github/v/release/JammesPark/R36S-ROM-STORE?style=for-the-badge&color=2563eb&label=Vers%C3%A3o"></a>
  <img alt="R36S e R36H" src="https://img.shields.io/badge/Console-R36S%20%7C%20R36H-0891b2?style=for-the-badge">
  <img alt="Sistemas: dArkOSRE, dArkOS, dArkOSen, ArkOS, ArchR" src="https://img.shields.io/badge/Sistema-dArkOSRE%20%7C%20dArkOS%20%7C%20dArkOSen%20%7C%20ArkOS%20%7C%20ArchR-ffdc49?style=for-the-badge">
  <a href="LICENSE"><img alt="GPL-3.0" src="https://img.shields.io/badge/Licen%C3%A7a-GPL--3.0-16a34a?style=for-the-badge"></a>
</p>

<p align="center">
  <a href="https://www.lua.org/"><img alt="Lua" src="https://img.shields.io/badge/Lua-000080?style=for-the-badge&logo=lua&logoColor=white"></a>
  <a href="https://love2d.org/"><img alt="LÖVE 11.5" src="https://img.shields.io/badge/L%C3%96VE-11.5-db2777?style=for-the-badge"></a>
  <a href="https://luajit.org/"><img alt="LuaJIT" src="https://img.shields.io/badge/LuaJIT-Runtime-000080?style=for-the-badge"></a>
  <a href="https://www.python.org/"><img alt="Python" src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"></a>
  <img alt="Shell Script" src="https://img.shields.io/badge/Shell_Script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white">
  <img alt="HTML5" src="https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white">
  <img alt="JSON" src="https://img.shields.io/badge/JSON-333333?style=for-the-badge&logo=json&logoColor=white">
  <img alt="YAML" src="https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white">
  <img alt="XML" src="https://img.shields.io/badge/XML-005A9C?style=for-the-badge">
  <img alt="Markdown" src="https://img.shields.io/badge/Markdown-000000?style=for-the-badge&logo=markdown&logoColor=white">
  <a href="https://github.com/features/actions"><img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white"></a>
  <a href="https://www.cloudflare.com/"><img alt="Cloudflare R2" src="https://img.shields.io/badge/Cloudflare-R2-F38020?style=for-the-badge&logo=cloudflare&logoColor=white"></a>
</p>

<p align="center">
  <a href="README.md"><img alt="Português do Brasil" src="https://img.shields.io/badge/PT--BR-Português-16803c?style=flat-square"></a>
  <a href="docs/README.en.md"><img alt="English" src="https://img.shields.io/badge/EN-English-2563eb?style=flat-square"></a>
  <a href="docs/README.es.md"><img alt="Español" src="https://img.shields.io/badge/ES-Español-eab308?style=flat-square"></a>
  <a href="docs/README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/RU-Русский-dc2626?style=flat-square"></a>
</p>


**Status:** versão 0.7.1-beta — versão oficial BETA.

---

## 💡 Sobre o projeto

O **R36S ROM STORE** é um aplicativo independente para consoles portáteis R36S e R36H. Desenvolvido em Lua e LÖVE 11.5, permite organizar jogos, baixar e instalar ROMs em SD1 ou SD2, gerenciar BIOS, temas e utilizar ferramentas do sistema diretamente com os controles físicos do console.

A interface tem resolução lógica de 640×480, dois temas integrados (Matrix padrão e Pulse opcional) e quatro idiomas selecionáveis. O aplicativo tem origem no R36S PORT HUB, de Lag do Lira, e preserva a autoria de ferramentas e temas herdados. Não é uma loja oficial, afiliada ou mantida pelo projeto-base.

---

## ⚠️ Aviso importante

⚠️ **Versão BETA.** As principais funcionalidades foram testadas em ambiente simulado no computador e nos consoles R36S e R36H. Algumas funções e combinações de sistemas operacionais ainda precisam de validação adicional. Relatos de problemas, sugestões e contribuições da comunidade são bem-vindos.

Este é um projeto independente, em fase BETA, feito pela comunidade. Não somos autores, proprietários ou representantes dos jogos, ROMs, BIOS, temas e demais conteúdos de terceiros. A licença do aplicativo não autoriza automaticamente seu acesso ou redistribuição. Respeite os direitos autorais e utilize apenas arquivos para os quais tenha autorização.

A compatibilidade varia conforme modelo, firmware e tela. Faça backup dos cartões e da instalação antes de alterações; ferramentas de manutenção podem modificar arquivos mediante confirmação. Relate falhas de funcionamento e não confunda versões experimentais com as oficiais.

---

## ⬇️ Downloads

| Pacote | Download |
|---|---|
| 📄 Instalador automático (.sh) — última versão oficial com OTA | [Baixar SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) |
| 📦 Instalação completa 0.7.1-beta (com OTA) | [Baixar ZIP](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.1-beta/R36S_ROM_STORE_0.7.1-beta.zip) |
| 🔄 Atualização manual 0.7.1-beta | [Baixar UPDATE.zip](https://github.com/JammesPark/R36S-ROM-STORE/releases/download/store-v0.7.1-beta/R36S_ROM_STORE_0.7.1-beta_UPDATE.zip) |
| 🗂️ Versões anteriores | [Histórico oficial](https://github.com/JammesPark/R36S-ROM-STORE/releases) |

O SH consulta o canal oficial ativo e baixa o ZIP completo com verificação de integridade. Para migrar de 0.7.0-beta ou anterior, use o SH ou ZIP completo: a pasta agora é `r36sromstore/`. O UPDATE.zip contém apenas a pasta da aplicação, para instalações existentes da nova estrutura. Faça backup e mescle as pastas sem apagar os dados. O canal OTA legado permanece na 0.7.0-beta.

O instalador SH do novo canal passou em testes automatizados; a execução física desse script separadamente ainda não foi confirmada.

---

## 🎨 Temas e interface

| Matrix Edition — padrão | Pulse Edition — alternativa |
|:---:|:---:|
| <img src="docs/images/atual/matrix-menu.png" width="320" alt="Tela inicial Matrix"> | <img src="docs/images/atual/pulse-menu.png" width="320" alt="Tela inicial Pulse"> |
| Verde original, menu em grade | Azul original, menu com logo centralizada |

As imagens são capturas da interface real do aplicativo em LÖVE, 640×480, geradas em ambiente isolado. A exibição das prévias foi aprovada no console. Os números de jogos, espaço e hardware mostrados nas capturas não representam um console físico.

Ambos são integrados à loja, com cores personalizáveis de forma independente e modos Lista, Grade e Vitrine. São adaptações de temas originais de Lag do Lira.

---

## ✨ Funcionalidades

| | Função | Descrição |
|---|---|---|
| 🎮 | **ROMs** | Jogos por sistema, detalhes, busca, favoritos e capas quando disponíveis. |
| 🕹️ | **Biblioteca de jogos** | Consulta jogos presentes nos emuladores do console, com opção de iniciar o jogo. |
| 📦 | **Instalados** | Gerenciamento das ROMs instaladas pela loja. |
| ⭐ | **Favoritos** | Marcar e desmarcar jogos e consultar os itens favoritos. |
| 💾 | **SD1/SD2** | Escolha do cartão de destino para instalação. |
| 🖼️ | **Visualização** | Modos Lista, Grade e Vitrine em Pulse e Matrix. |
| ⬇️ | **Downloads** | Fila, progresso, velocidade, histórico e operações em segundo plano. |
| 🧩 | **BIOS do Sistema** | Área de verificação, download e instalação de BIOS, com gerenciamento de arquivos. |
| 🎨 | **Temas Store** | Consulta e instalação de temas da interface do console. |
| ⚙️ | **Configurações** | Aparência, cores, brilho, áudio, notificações e preferências. |
| 🔄 | **Atualizações** | Canal OTA da nova pasta com SHA-256, histórico e recuperação. |
| 🌐 | **Quatro idiomas** | 🇧🇷 PT-BR, 🇺🇸 EN, 🇪🇸 ES e 🇷🇺 RU. |

---

## 🛠️ Utilidades e ferramentas

As ferramentas abaixo foram identificadas no código e nas telas da versão atual. Parte delas foi herdada ou adaptada do R36S PORT HUB, por Lag do Lira. A disponibilidade depende das permissões, dos componentes e do firmware do console.

| Ferramenta | Função |
|---|---|
| **Analisador do cartão SD** | Espaço usado e livre, tamanho das pastas e maiores arquivos. |
| **Verificador do cartão SD** | Identificação do cartão, indícios de capacidade falsa e teste rápido de velocidade. |
| **Manutenção do cartão SD** | Operações de manutenção com confirmação. |
| **Verificador de integridade dos ports** | Confere scripts, pastas e dependências do PortMaster. |
| **R36S Analog Tester** | Teste de analógicos e botões, com relatório. Ferramenta de Lag do Lira. |
| **Teste de controles** | Verifica as entradas reconhecidas pela interface. |
| **Diagnóstico de rede** | Informações de rede, sinal, DNS e teste de conexão e velocidade. |
| **Gerenciar Wi-Fi** | Consulta e conexão a redes disponíveis. |
| **Servidor FTP** | Transferência de arquivos pela rede local. |
| **Gerenciador de arquivos** | Navegação e operações nos arquivos do cartão. |
| **PortMaster e runtimes** | Gerenciamento do PortMaster e dos runtimes necessários aos ports. |
| **Analisador de console** | Identificação do aparelho e consulta de informações do sistema. |
| **R36 Control** | Ajustes do console quando suportados pelo sistema. |
| **Bateria e energia** | Consulta das informações de energia disponíveis. |
| **Data e hora** | Configuração de horário e fuso. |
| **Transmissão e gravação** | Recursos de transmissão pela rede local e gravação da interface. |
| **Backup e restauração** | Backup, exportação e recuperação de configurações. |
| **Diagnóstico e suporte** | Consulta dos registros de erros do aplicativo. |

---

## 🚀 Instalação no R36S

**Instalador automático:** copie o [SH](https://raw.githubusercontent.com/JammesPark/R36S-ROM-STORE/main/INSTALAR_R36S_ROM_STORE.sh) para `ports/`, conecte o console à internet e execute pelo EmulationStation.

**Instalação manual:**

1. Baixe o pacote completo da seção Downloads.
2. Extraia os arquivos na pasta `ports` do cartão de destino.
3. Confira a estrutura:

   ```text
   ports/
   ├── R36S ROM STORE.sh
   └── r36sromstore/
   ```

4. Reinicie o EmulationStation, se necessário, e abra o aplicativo na seção Ports.
5. Conecte o console à internet para a primeira sincronização.

**Requisito:** runtime LÖVE 11.5 disponível no aparelho. A primeira instalação da nova estrutura usa o ZIP completo em `ports/`.

---

## 🎮 Controles

| Botão | Ação |
|---|---|
| Direcional / analógico esquerdo | Navegação, seleção e rolagem. |
| **A** | Abrir, confirmar, selecionar ou executar a ação indicada. |
| **B** | Voltar, cancelar ou abrir a saída no menu principal. |
| **X** | Pesquisa na lista de ROMs; outras ações conforme a tela. |
| **Y** | Atualiza a lista de ROMs; remove temas instalados ou abre informações e ações na Central de Downloads. |
| **L1 / R1** | Alternam categorias, abas ou páginas nas telas compatíveis. |
| **L2 / R2** | Alternam os modos de visualização nas listas de ROMs compatíveis. |
| **SELECT** | Marca ou desmarca favoritos; abre a atualização quando há aviso no menu. |
| **START** | Abre a Central de Downloads; na Temas Store, abre opções; na tela Sobre, abre o apoio ao projeto. |
| **FN** | Captura de tela quando reconhecido pelo sistema; no teste de controles, é testado sem capturar. |
| Analógico direito / L3 / R3 | Sem atalho global definido no mapeamento geral; consultar o teste de controles. |

As funções contextuais aparecem no rodapé das telas. O mapeamento físico pode variar conforme o firmware.

---

## 🖥️ Compatibilidade e testes

| Aparelho / sistema | Situação |
|---|---|
| R36S | Testado fisicamente pelo responsável. |
| R36H | Testado fisicamente pelo responsável. |
| dArkOSen | Testado em console; foram observadas diferenças de mapeamento de controles. |
| ArchR | Instalação testada; demais funções dependem da versão do sistema. |
| dArkOSRE / dArkOS / ArkOS | Sistemas de referência; validação individual completa em andamento. |
| Outras telas e clones | Compatibilidade em validação. |

A documentação não certifica todos os firmwares ou aparelhos. Informe o modelo, o sistema e a versão ao relatar problemas.

---

## 🔄 Atualizações

A primeira migração exige backup do cartão e o pacote completo. As instalações em `r36sromstore/` consultam o canal OTA da nova estrutura. O feed das instalações anteriores continua na 0.7.0-beta.

---

## 📖 Documentação

| Documento | Conteúdo |
|---|---|
| [CHANGELOG.md](CHANGELOG.md) | Histórico de versões |
| [CONTRIBUTORS.md](CONTRIBUTORS.md) | Registro de contribuições |
| [HISTORICO_RELEASES.md](docs/HISTORICO_RELEASES.md) | Histórico das publicações oficiais |
| [REORGANIZACAO.md](docs/REORGANIZACAO.md) | Organização dos arquivos |
| [NOTICE.md](NOTICE.md) | Autoria e avisos |
| [LICENSE](LICENSE) | Licença GPL-3.0 |

A pasta `docs/` preserva também documentos do projeto-base, que podem citar versões e caminhos antigos.

---

## 🗂️ Estrutura do projeto

```text
src/       Código-fonte Lua/LÖVE, temas e recursos
port/      Launcher e arquivos de instalação no console
tools/     Build, ferramentas e serviços auxiliares
tests/     Testes automatizados
docs/      Documentação, protótipos e arquivos históricos
.github/   GitHub Actions
```

Para gerar o pacote: `sh tools/build.sh`. O GitHub Actions valida LuaJIT, testes e integridade dos ZIPs.

---

## 💬 Comunidade

Canal oficial: [Telegram]().

Relatos de bugs e sugestões: [GitHub Issues](https://github.com/JammesPark/R36S-ROM-STORE/issues).

---

## 🤝 Contributors

- **[JammesPark](https://github.com/JammesPark)** — criador, responsável pelo projeto, direção visual e testes no console.
- **[ChatGPT (OpenAI)](https://chatgpt.com/)** — colaboração no desenvolvimento assistido por IA desde o início do projeto.
- **[Lag do Lira](https://github.com/liralflsti-wq/r36s-port-hub)** — autor do projeto-base, dos temas originais e de ferramentas herdadas do R36S PORT HUB.

Veja o [registro completo das contribuições](CONTRIBUTORS.md).

---

## 🙏 Autoria, licença e uso responsável

Baseado no **R36S PORT HUB, por [Lag do Lira](https://youtube.com/@lagdolira)**. Pulse Edition e Matrix Edition são adaptações dos temas originais do autor, com créditos preservados. Parte das ferramentas e dos utilitários também foi herdada ou adaptada do projeto-base; sua autoria original é de Lag do Lira, respeitados os créditos e as licenças de componentes de terceiros.

Código sob GNU GPL-3.0, conforme [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) e avisos de terceiros. A licença do aplicativo não concede direitos sobre ROMs, BIOS, capas ou outros conteúdos de terceiros. Utilize somente arquivos para os quais tenha direito de acesso, download e distribuição.

<p align="center"><strong>R36S ROM STORE</strong><br>Desenvolvimento colaborativo para a comunidade retrô.</p>
