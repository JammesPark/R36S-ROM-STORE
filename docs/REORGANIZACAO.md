# Reorganização do repositório

A raiz do repositório foi simplificada sem alterar os nomes instalados no console.

| Origem | Destino no Git |
|---|---|
| game/ | src/ |
| R36S ROMS STORE.sh | port/R36S ROMS STORE.sh |
| r36sromsstore/ | port/r36sromsstore/ |
| design/ | docs/design/ |
| services/ | tools/services/ |
| GUIA_GITHUB_CATALOGOS.txt | docs/GUIA_GITHUB_CATALOGOS.txt |
| publicar.sh (desativado) | docs/preservacao/publicar-desativado.sh |
| temas.json (cópia histórica) | docs/preservacao/temas.json |
| update_manifest.json (antigo) | docs/preservacao/update_manifest.json |

O código de execução e os arquivos do launcher foram movidos sem alteração de conteúdo. O comando `sh tools/build.sh` continua gerando o ZIP no formato de instalação original: launcher e pasta r36sromsstore na raiz do pacote. O manifesto do instalador é gerado novamente durante o build. O catálogo ativo de ROMs e o feed OTA continuam no repositório de atualizações. A loja de temas usa a cópia interna quando C.ES_THEMES_URL está vazio.

Documentos antigos preservados podem citar caminhos e nomes históricos. Ferramentas e testes históricos do projeto-base não são todos executados pelo CI atual. O arquivo de temas na raiz era legado: configurações personalizadas que apontem diretamente para esse caminho antigo não foram verificadas.

A reorganização deve ser validada na branch experimental antes de ser integrada. Nenhuma publicação OTA é necessária.
