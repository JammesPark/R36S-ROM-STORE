# Atualizações automáticas — R36S ROMS STORE

## Fontes separadas
O desenvolvimento da R36S ROMS STORE está no repositório privado JammesPark/R36S-PORTS-BR-STORE-KPM.
A distribuição de atualizações usa o repositório público JammesPark/R36SPORTSBR-STORE-UPDATES, mas **somente a pasta roms-store/**.
A URL exclusiva é https://raw.githubusercontent.com/JammesPark/R36SPORTSBR-STORE-UPDATES/main/roms-store/update.json
O update.json da raiz pertence a OUTRO projeto e não é alterado.

## Atualização no console
1. Ao abrir o aplicativo, ele consulta o feed em segundo plano. A loja continua funcionando durante a consulta.
2. Ao encontrar versão nova, mostra aviso; também é possível abrir Configurações → Atualizações.
3. O usuário confirma o download. O pacote oficial HTTPS tem tamanho e SHA-256 obrigatórios.
4. O pacote UPDATE usa manifesto, whitelist de caminhos e hashes de arquivos. Não contém ROMs nem arquivos de estado.
5. Ao confirmar Instalar e reiniciar, o LÖVE fecha e o launcher aplica os arquivos, preserva state/ e cria backup.
6. Se a nova versão falhar no primeiro boot, o launcher restaura a anterior.

Nenhuma atualização é instalada silenciosamente. A loja só oferece atualização se o feed estiver publicado.

## Configuração da publicação (ação do proprietário)
1. Crie um fine-grained personal access token no GitHub, com acesso apenas a JammesPark/R36SPORTSBR-STORE-UPDATES e permissão Contents: Read and write.
2. No repositório privado R36S-PORTS-BR-STORE-KPM, em Settings → Secrets and variables → Actions, crie o secret ROMS_UPDATES_TOKEN com esse token. NÃO compartilhe o token em conversa ou código.
3. Aguarde build verde da main. Abra Actions → Publicar atualização ROMS STORE (feed isolado) → Run workflow. Informe o build_run_id da execução aprovada.
4. O workflow verifica que o ID corresponde ao commit atual, valida os três ZIPs, cria a Release exclusiva roms-vX.Y.Z-beta, compara o pacote publicado e somente depois altera roms-store/update.json.
5. Para as próximas versões, é possível acionar a publicação automaticamente usando [roms-online-release] na mensagem do commit. Sem esse marcador, builds experimentais nunca publicam.

A Release publica instalador, atualização e código-fonte correspondente, como requer a distribuição GPL-3.0. O repositório de desenvolvimento permanece privado.

## Diagnóstico
- Verificação e progresso: r36s-roms-store/state/store_update_status.json
- Arquivos baixados: r36s-roms-store/state/updates/
- Logs do launcher: r36s-roms-store/log.txt
- Sinal de rollback pendente: r36s-roms-store/state/updates/pending_health.json

O procedimento inicial está inativo até que um pacote real seja publicado; o feed inicial tem status awaiting_release. Verifique Python 3 e acesso à internet no console.
