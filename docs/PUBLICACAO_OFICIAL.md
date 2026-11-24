# Publicação de versões oficiais

O workflow `Validar e empacotar R36S ROMS STORE` executa testes e gera o pacote em pushes e pull requests, sem publicar Releases ou OTA por padrão.

A publicação oficial exige aprovação do responsável pelo projeto e uma destas ações na branch `main`:

- Em Actions, executar o workflow manualmente e marcar `publish_release`.
- Em um commit de versão previamente aprovado, incluir o marcador `[release approved]` na mensagem.

O job de publicação depende de todos os testes da build. A distribuição é feita somente pelo repositório [de atualizações](https://github.com/JammesPark/R36S-ROMS-HUB-STORE-UPDATES), que verifica os dois ZIPs antes de ativar o feed OTA. A versão deve ser nova e superior à do canal. Builds experimentais continuam separadas e não alimentam a OTA.

Não use o marcador de aprovação em commits de documentação, testes ou versões experimentais. O histórico de commits e tags permanece preservado.

Assisted-by: ChatGPT (OpenAI)
