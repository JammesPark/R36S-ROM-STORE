# Histórico de versões — R36S ROMS STORE

O histórico mantém os números usados nas entregas anteriores, sem renumeração retroativa.

## 0.4.1-beta
- Corrigida a atualização direta da v0.3.1-beta: o UPDATE mantém os sete caminhos permitidos no gerenciador legado, com SHA-256 e manifesto íntegros.
- Componente BIOS incluído no game.love e preparado automaticamente quando necessário, evitando arquivos ausentes após atualizar.
- Atualizador novo aceita apenas dois formatos oficiais (sete ou oito arquivos), mantendo lista de caminhos autorizados e backup/rollback.
- Teste de compatibilidade executa o atualizador real da v0.3.1-beta com o ZIP da nova versão.
- Quem já instalou manualmente v0.4.0-beta deve usar o instalador v0.4.1-beta; o atualizador v0.4.0-beta não reconhece o pacote legado.

## 0.4.0-beta
- Popup de nova atualização com versão instalada, versão disponível e resumo das mudanças.
- Nova área **Configurações → BIOS do Sistema** com scanner próprio (sem reaproveitar código do Port Hub), importação de arquivos próprios, instalação cautelosa, backup e restauração.
- O sistema não fornece nem baixa imagens de BIOS protegidas; apenas identifica nomes conhecidos e arquivos que o usuário coloca em `state/bios_import`.
- No catálogo e nos resultados de busca, botão **Y** adiciona ou remove a ROM selecionada dos favoritos.
- Na tela inicial, **B** abre a confirmação de saída; ←/→ selecionam Sim/Não, **A** confirma e **B** cancela.
- Mantido canal público exclusivo de atualização, com pacote UPDATE incluindo o novo gerenciador de BIOS.
- Todas as funcionalidades passaram no GitHub Actions antes da publicação beta.

## 0.3.1-beta
- Atualizador migrado para o repositório público exclusivo `JammesPark/R36S-ROMS-STORE-UPDATES`, sem utilizar o canal do outro HUB.
- Feed `update.json` próprio e publicação preparada para criar o feed na primeira Release.
- Testes de isolamento do feed, versão, URL e ausência de dependências do repositório anterior.
- A ativação pública depende da criação do novo repositório e do token restrito do Actions.

## 0.3.0-beta
- Consulta automática por atualizações e nova área Configurações → Atualizações em PT/EN/ES/RU.
- Download com confirmação e verificação SHA-256, manifesto e identidade da loja.
- Instalação com backup/rollback realizada pelo launcher depois do fechamento do LÖVE.
- Canal público isolado em roms-store/update.json e workflow próprio de publicação.
- Testes de pacote, versão e recuperação sem alterar ROMs e arquivos de estado.
- O feed só será ativado após publicação verificada da primeira Release.

## 0.2.16-beta
- Versão unificada no arquivo VERSION, lida em execução pelo LÖVE.
- Nomes dos ZIPs gerados automaticamente e validação cruzada no GitHub Actions.
- README e política de numeração atualizados.
- Nenhuma alteração intencional no catálogo, downloads ou controles.

## Marcos anteriores
| Versão | Marco |
| --- | --- |
| 0.2.15 | Download atual na tela Início e correção dos ícones |
| 0.2.14 | Ícones individuais para cada item da navegação |
| 0.2.13 | Destaques sem nomes; START verde |
| 0.2.11–0.2.12 | Alinhamento da interface |
| 0.2.9–0.2.10 | Rolagem contínua e exclusão/sobrescrita de ROMs |
| 0.2.8 | Músicas, ícones, QR codes e tela Sobre |
| 0.2.7 | Seleção inicial de idioma e aviso obrigatório |
| 0.2.6 | Logo oficial, catálogo em lista e busca remota |
| 0.2.4–0.2.5 | Status do console e melhorias na navegação |
| 0.2.2–0.2.3 | Limpeza da identidade anterior e interface |
| 0.2.0–0.2.1 | Tema novo e correção de navegação inicial |
