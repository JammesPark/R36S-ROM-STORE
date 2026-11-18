# BIOS do Sistema — R36S ROMS STORE (implementação independente)

Esta ferramenta foi desenvolvida diretamente para a ROMS STORE, sem copiar o código do R36S PORT HUB. A análise desse projeto serviu apenas como referência de funcionalidades. Nenhum arquivo de BIOS ou firmware comercial é distribuído. Direitos sobre BIOS pertencem aos titulares; utilize somente arquivos que você tenha direito de usar.

## Operação no console

Abra **Configurações → BIOS do Sistema**. A tela tenta identificar o diretório de BIOS configurado no RetroArch ou em `/roms/bios` e `/roms2/bios`. Caso não exista, a ferramenta não cria pastas nem altera o sistema. Em **A — Verificar**, ela informa quais nomes esperados estão presentes, parciais ou ausentes. As informações não certificam licenças ou autenticidade.

Para importar, copie seus arquivos locais (ou um ZIP de BIOS que você tenha direito de usar) na pasta `r36s-roms-store/state/bios_import` e pressione **X**. Após confirmar, o aplicativo valida caminhos, nomes permitidos, tamanho e tipos de arquivo; ignora arquivos desconhecidos. Nenhuma imagem de BIOS é executada. Antes de substituir BIOS existente, é criado um backup e um diário para recuperação em caso de falha. **Y — Restaurar backup** permite voltar ao estado anterior, mediante confirmação. Se alguma BIOS foi alterada manualmente após o backup, a restauração é bloqueada para proteger os arquivos do usuário.

Os arquivos temporários, o estado e backups ficam em `r36s-roms-store/state/bios_manager`. Não são distribuídos no instalador, nem excluídos por futuras atualizações. Limites: até 512 entradas num ZIP, 32 MB por arquivo e 128 MB no conjunto. Suporte a importação de arquivos soltos e ZIP, sem RAR/7z nesta primeira implementação.

## Avisos de segurança

- Arquivos conhecidos são identificados por nome e existência; não fornecemos hashes oficiais de autenticidade.
- Não utilize pacotes de procedência desconhecida. Faça backup do SD antes de importar.
- A ferramenta só reconhece diretórios BIOS de cartão SD e não deve operar em caminhos externos.
- Verificação, importação e backup devem ser validados no console real antes de confiar em uma instalação de BIOS importante.
