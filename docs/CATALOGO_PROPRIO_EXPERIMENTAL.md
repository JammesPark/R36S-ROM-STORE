# Catálogo próprio — R36S ROMS STORE — Experimental

Base: 0.6.7-beta (`f9f7d2b`). **Somente a branch Experimental**; sem alterações na `main` ou no repositório público OTA.

## Fonte e resultado

- Fonte entregue: `links(1).zip`, arquivos `links/*.csv`.
- 15.727 links inspecionados de 48 sistemas.
- 15.652 itens classificados como ROMs/jogos cadastrados.
- 75 links de arquivos auxiliares (`.nfo`, `.sav`, `.srm`, `.rtc`, etc.) ficaram em relatório separado e **não** entram como jogos.
- Todas as URLs foram preservadas exatamente como fornecidas. A disponibilidade individual dos servidores e os direitos de distribuição não foram verificados.
- Nenhuma capa foi fornecida na fonte. `cover` fica vazio, sem imagens inventadas.

O ZIP do catálogo é entregue separadamente ao usuário e **não está commitado** nesta branch. Portanto, o instalador padrão construído pelo GitHub Actions **não inclui** o arquivo de dados do catálogo próprio até que ele seja instalado manualmente.

## Instalação do arquivo de dados

1. Instalar a edição Experimental da loja (em ambiente de teste, com backup).
2. Extrair o ZIP do catálogo na raiz de `/roms/ports/`, preservando o caminho `r36sromsstore/catalogo_proprio.zlib`.
3. Em uma instalação no SD2, copiar `catalogo_proprio.zlib` para a **pasta real da loja**, conforme `C.APP_DIR`.
4. Na loja, abrir **Configurações → Catálogo de ROMs → Fonte do catálogo → R36S ROMS STORE — Experimental**.
5. Para retornar ao original, selecionar **GameStoreBR**. Os catálogos não são mesclados.

O catálogo próprio é descompactado e validado localmente. Limites: 2 MiB compactado, 8 MiB em JSON e 50.000 entradas. O arquivo validado contém 15.652 registros e 48 categorias. Quando escolhido, todas as entradas aparecem de imediato, sem paginação da API GameStoreBR; a busca funciona localmente.

## Compatibilidade de instalação

As 20 plataformas já aceitas pelo instalador da versão 0.6.7-beta mantêm suas regras originais. Os outros 28 sistemas aparecem no catálogo e podem ser pesquisados, mas a instalação automática desses sistemas requer uma revisão futura de pastas, formatos e emuladores para cada firmware. **Não adicionar mapeamentos arbitrários.**

Os links podem apontar para ROMs, pacotes ou arquivos com formatos inadequados para cada emulador. O catálogo **não garante** download bem-sucedido, funcionamento no console ou permissão para redistribuir o conteúdo.

## Integridade

- Compactado (SHA-256): `e31d90c9623e1a8336f6e671af37cde06a84f5126b45f3575eb2e1279621f392`
- JSON (SHA-256): `d948b001fb93d7b833b34df579854af263ce95a9f98fabf555ab10af00ffb7cf`

A validação do arquivo é feita antes de aceitar as entradas. Os jogos, capas, favoritos e downloads já existentes não são apagados durante a troca de fonte.

## Testes

`tests/test_own_catalog.lua` simula um catálogo válido, registros duplicados, URL não HTTP(S), JSON descompactado excessivo e arquivo ausente. O GitHub Actions da branch experimental executa esse teste e a compilação LuaJIT; não publica uma Release oficial.
