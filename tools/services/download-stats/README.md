# R36S ROM STORE — contador de downloads (Cloudflare Workers + D1)

Backend da R36S ROM STORE, baseado no Worker do projeto, sem misturar os dois catálogos.

## Estado e seguranca

- Banco D1 existente: `r36sportsbr-download-stats`; NÃO recriar.
- `download_events`: cada event_id só pode ser contabilizado uma vez.
- `download_totals`: ranking independente por `catalog`.
- `approved_ports`: lista autorizada por catálogo; preenchida pelo cron de hora em hora.
- `STATS_WRITES_ENABLED = "false"` é o padrão seguro de deploy.
- POST de 1 a 10 eventos validado; até 8 KiB; allowlist de jogos; transação D1.
- Rate limit aproximado: 12 **eventos** por minuto/IP, por local Cloudflare, não 12 requisições.
- Os rankings só aceitam `catalog=r36sbr` ou `catalog=lira`; `all` não é permitido.
- O cliente guarda eventos offline e reenvia com o mesmo event_id para evitar duplicar.
- **Limitação fundamental:** o servidor não consegue provar que um cliente terminou um download. Um agente malicioso pode simular eventos; deduplicação, whitelist e rate limit são mitigações, não antifraude infalível.

## Publicar pela primeira vez (PowerShell / conta Cloudflare do proprietário)

1. Na pasta `services/download-stats`, execute `npx.cmd wrangler@latest deploy --dry-run`.
2. Confirme que a D1 remota possui as três tabelas, **sem executar o schema novamente**:
   `npx.cmd wrangler@latest d1 execute r36sportsbr-download-stats --remote --command "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('download_events','download_totals','approved_ports');"`
3. Com `STATS_WRITES_ENABLED="false"`, execute `npx.cmd wrangler@latest deploy`.
4. Copie a URL HTTPS `https://r36sportsbr-download-stats.<sua-conta>.workers.dev` informada pelo Wrangler.
5. Confirme `GET /health` com `writes_enabled:false` e `GET /v1/top?catalog=r36sbr`.
6. Aguarde a sincronização automática horária ou execute o trigger agendado no painel da Cloudflare e confira no D1 remoto 2 jogos `r36sbr` e 37 jogos `lira` (valores atuais, podem mudar).
7. Somente após a checagem de risco e os testes, configure `STATS_WRITES_ENABLED="true"` e execute o novo deploy.
8. No repositório público `JammesPark/R36SPORTSBR-STORE-UPDATES`, arquivo `stats_api.json`, preencha `enabled:true` e `api_url` com a URL HTTPS. Não coloque tokens, chaves nem segredos nele. A STORE atualizada descobre a API automaticamente.

A conexão com a conta Cloudflare não é disponibilizada pelo conector GitHub. Fazer commits neste repositório NÃO publica automaticamente o Worker.

## Endpoints

- `GET /health` — saúde, estado de gravação.
- `GET /v1/top?catalog=r36sbr` — Top 5 exclusivo da sua STORE.
- `GET /v1/top?catalog=lira` — Top 5 exclusivo do catálogo do Lira.
- `GET /v1/count?catalog=r36sbr&port_id=aestheta` — contagem do jogo.
- `POST /v1/events` — aceita `{"events":[{"event_id":"32hex","catalog":"r36sbr","port_id":"aestheta"}]}`, com lista autorizada e limite de taxa.

## Adicionar novos jogos

Altere apenas o JSON público `JammesPark/R36SPORTSBR-STORE-UPDATES/catalog/catalog.json`.
O cron sincroniza os novos IDs sem editar D1 ou reimplantar o Worker.

## Testes

`node --test services/download-stats/test.mjs` na raiz do repositório.
`node --check services/download-stats/src/worker.mjs`.

## Licença

GPL-3.0. Créditos da base preservados ao autor Lag do Lira conforme avisos originais.
