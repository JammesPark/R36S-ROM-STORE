# Atualizações públicas

A partir da 0.6.7-beta, a loja consulta `ota/update.json` no repositório público JammesPark/R36S-ROMS-HUB-STORE-UPDATES. A primeira instalação desta versão é manual. O aviso pode ser alterado em Configurações. O instalador completo inclui o catálogo inicial. O pacote OTA contém apenas os arquivos do manifesto para preservar os dados locais.

Aumente a versão com `python3 tools/version.py bump patch --note "Descrição"`. Após os testes da main, o workflow envia o instalador ao repositório público usando o segredo ROMS_UPDATES_TOKEN com escrita de conteúdo nesse destino. O workflow público gera o ZIP OTA, verifica a integridade, publica a Release e só então atualiza o feed.
