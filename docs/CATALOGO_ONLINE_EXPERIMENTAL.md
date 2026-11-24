# Canal de catálogo online — Experimental

- Canal dedicado: branch catalogo-experimental do repositório R36S-ROMS-HUB-STORE-UPDATES, em catalogo/catalogo_proprio.zlib.
- O JSON fonte e o ZLIB correspondente devem ser publicados juntos, somente após validação e autorização dos direitos de distribuição.
- O Hub carrega primeiro o arquivo local e, após a abertura, tenta atualizar em segundo plano. A tecla Y no catálogo repete a consulta.
- O download usa HTTPS, tamanho máximo de 4 MiB e timeout de 30 segundos. O parser exige catálogo próprio, IDs/URLs únicos, no mínimo 50 sistemas e 15.652 registros, e aceita URLs de capa apenas do Worker configurado, no sistema correto. A cópia existente permanece se a rede, a validação ou a gravação falhar.
- Os mínimos de 50 sistemas e 15.652 registros protegem o primeiro rollout contra amostras truncadas; uma futura redução intencional da coleção exige rever esses limites.
- Capas em cache são indexadas pela URL e slug. O aplicativo não baixa todas as capas durante a atualização do catálogo.
- Nenhuma alteração no OTA oficial. CPS1/CPS3 permanecem sem registros até haver fonte autorizada.
- O pacote experimental deve ser testado no R36S antes de promover qualquer alteração.
