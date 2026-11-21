# R36S ROMS STORE — Experimental

Edição **R36S ROMS STORE — Experimental**, criada a partir da versão oficial **0.6.7-beta**, commit `f9f7d2b`, sem reutilizar as modificações descartadas. O código experimental fica exclusivamente na branch `experimental/0.6.7-beta-20261121`; o projeto oficial permanece na `main`.

**Status:** versão 0.6.7-beta — Experimental, Etapa 1 do catálogo próprio (15.652 ROMs / 48 sistemas). Dados em pacote separado, mantendo o número de versão para compatibilidade.

Aplicativo para consoles R36S/R36H, com interface Lua e LÖVE 11.5. Inclui catálogo de ROMs por sistema, gerenciamento de downloads, instalação em SD1/SD2, favoritos, BIOS, temas e gerenciamento seguro dos arquivos instalados.

**Esta revisão** inclui só os temas **Padrão e Neon Grid**. O tema Padrão
tem **Lista**, **Grade Jedi** e **Vitrine Pastel**; na tela de ROMs,
**L2** e **R2** trocam a visualização e salvam a escolha. Como alternativa,
use **Configurações > Catálogo de ROMs > Visualização de ROMs (Padrão)**.
O tema Neon continua com a sua grade independente.

As regiões são identificadas por etiquetas separadas e coloridas:
**JP** rosa-coral, **CN** laranja, **TW** verde, **HK** lilás.
O sistema mantém a etiqueta ciano. Os sufixos regionais são escondidos
somente no nome mostrado, preservando IDs, arquivos e URLs originais.
Temas antigos permanecem no cartão do usuário, caso já existam, mas não
aparecem mais na seleção e não integram o instalador novo.

Atenção: esta edição utiliza o mesmo launcher e diretório de instalação da versão oficial. Antes de testar no console, faça backup da instalação atual. Esta branch não publica OTA nem substitui a versão oficial.

## Instalação da Experimental (Etapa 1)

**Não use as Releases oficiais para obter esta edição.** Elas continuam
destinadas à `main`, preservada em 0.6.7-beta.

1. Após uma execução **verde** do GitHub Actions da branch `experimental/0.6.7-beta-20261121`,
   baixe o ZIP na [branch de downloads experimentais](https://github.com/JammesPark/R36S-ROMS-HUB-STORE/tree/experimental-downloads/distribution):
   `R36S_ROMSTORE_Experimental_Etapa1.zip`.
2. Faça backup da loja instalada e extraia o ZIP do aplicativo em `/roms/ports/`.
3. Extraia, em seguida, o pacote de **dados** `R36S_ROMSTORE_INSTALAR_SD_15652_SIGLAS.zip`,
   distribuído separadamente, no mesmo local. Ele contém o catálogo e a cópia válida.
4. Abra **Configurações > Catálogo de ROMs** e confirme **15.652 ROMs**.
   O aplicativo não usa a API GameStoreBR.

Em instalação personalizada/SD2, coloque os dois ZLIBs na pasta real da loja
(`R36SBR_DIR` / `C.APP_DIR`). O aplicativo não faz fallback automático
para outra API, nem contém um catálogo fictício.

A compilação exige o runtime LÖVE 11.5 do console e o pacote de suporte
necessário. **Testes no hardware real ainda não foram realizados.**

## Código-fonte, build e verificações

- `game/`: código Lua da edição Experimental, fonte única de catálogo local;
- `game/core/own_source.lua`: validação, backup e recuperação offline;
- `tests/test_own_catalog.lua`: teste do leitor e cópia válida;
- `tests/test_catalog_offline.py`: teste de ausência da API de jogos antiga;
- `tests/test_region_view.lua`: valida L2/R2 como botão/eixo, etiquetas e
  preservação dos nomes originais;
- `tests/test_theme_layouts_experimental.py`: verifica que só dois temas
  integram o pacote e que a troca Lista/Grade/Vitrine está disponível;
- `tools/build.sh`: gera o instalador e recompila o `game.love`;
- `.github/workflows/build.yml`: valida LuaJIT, testa e empacota, publicando
  o ZIP somente na branch `experimental-downloads` (sem Release oficial nem OTA).
  O GitHub Actions `upload-artifact` foi desativado porque a cota do repositório está cheia.
  Nenhum link para a branch de downloads é atualizado caso o build falhe.

```sh
sh tools/build.sh
```

Documentação e auditoria: [Catálogo próprio Experimental](docs/CATALOGO_PROPRIO_EXPERIMENTAL.md).
A revisão anterior reintegrou 13 versões traduzidas/multilíngues, e a
revisão atual recolocou as **3.164 ROMs restantes**, com os marcadores
`[JP]` (3.122), `[CN]` (1) e `[TW]` (41) nos nomes do catálogo.
São códigos identificados no arquivo, e não comprovação do idioma do jogo.
IDs, `file_name` e links de download permaneceram inalterados.
O instalador de código não inclui estes dados: instale o ZIP separado
`R36S_ROMSTORE_INSTALAR_SD_15652_SIGLAS.zip` para obter a nova contagem.

Os links diretos de ROM continuam no acervo original (Axiom/Archive.org);
retirar uma API de catálogo não significa hospedar ou alterar ROMs. Capas,
ScreenScraper, substituição de links e otimização de downloads são etapas futuras.

## Autoria, licenças e conteúdo

Aplicativo derivado do **R36S PORT HUB**, por **Lag do Lira**, com modificações para a R36S ROMS STORE. Ver `LICENSE`, `NOTICE.md` e os avisos de terceiros. Código distribuído sob GPL-3.0, com as condições e os avisos de licença aplicáveis. As ROMs, artes e marcas de terceiros são responsabilidade de seus respectivos titulares; o aplicativo não concede licenças sobre elas.
