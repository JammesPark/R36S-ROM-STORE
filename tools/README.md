# Ferramentas de desenvolvimento — R36S ROM STORE

Scripts recuperados e adaptados do **R36S PORT HUB**, por **Lag do Lira**:
https://github.com/liralflsti-wq/r36s-port-hub (GPL-3.0, ver `LICENSE` e `NOTICE.md`).
A loja e a identidade visual permanecem independentes.

| Script | Para que serve |
| --- | --- |
| `tools/make_update.py` | Gera o manifesto completo de hashes SHA-256, uma baseline e pacotes incrementais de atualização para **r36sromsstore/** e **R36S ROM STORE.sh**. Não publica nem instala automaticamente. |
| `tools/make_icons.py` | Gera ícones de linha herdados do projeto-base, para inspeção e eventual aproveitamento na loja. |
| `tools/make_system_icons.py` | Gera artes de sistemas/consoles herdadas, para inspeção e eventual aproveitamento. Usa `make_icons.py`. |
| `tools/build.sh` | Empacota `src/` em `game.love`, monta a árvore `build/ports/`, atualiza manifesto completo e gera ZIP instalável. |

## Comandos

```sh
sh tools/build.sh
python3 tools/make_update.py baseline build/ports build/versao-base.json
# Depois de alterar C.VERSION_NUM em src/config.lua e gerar um novo build:
python3 tools/make_update.py incremental --base build/versao-base.json --ports build/ports --out build/atualizacao.zip --desc "Atualização da STORE"
```

Para os geradores de imagens (Pillow: `python3 -m pip install Pillow`):

```sh
python3 tools/make_icons.py
python3 tools/make_system_icons.py
```

**Segurança:** os geradores escrevem por padrão em `build/generated-assets/`, **não** em `src/assets/`. Use `R36SBR_ICON_OUT` e `R36SBR_SYSTEM_ICON_OUT` para escolher outro diretório, e revise os resultados antes de integrá-los. A criação de pacotes trabalha em `build/`, sem alterar a instalação do console, os catálogos, a logo, temas, SD1/SD2 ou os arquivos de `src/`.

A geração de incrementais não habilita, por si só, atualizações remotas no console: a publicação de releases, URL própria de atualização e integração de download serão configuradas separadamente.

## Geradores de hardware, BIOS e artes — adaptados (0.0.7-beta)

Os seis scripts recuperados foram adaptados, sem modificar as funções existentes na STORE. As cópias originais estão em `docs/preservacao/original/tools/` (Lag do Lira, GPL-3.0).

**Requisitos no computador:** Python 3.9+ (recomendado Python 3.11+), Pillow somente para as artes, arquivos DTB de projetos de firmware que você tenha obtido legitimamente. Os scripts não usam a rede e não clonam repositórios.

Para gerar assinaturas DTB de fontes obtidas separadamente:

```sh
python3 tools/fdt2.py /caminho/darkosre/files/BOOT/dtb --out build/generated-data/darkosre_sigs.json
python3 tools/fdt2.py /caminho/aeolus --out build/generated-data/aeolus_sigs.json
python3 tools/fdt3.py /caminho/a4c/boot/dArkOS/consoles --out build/generated-data/a4c_sigs.json
python3 tools/mkconsoledb.py \
  --ini /caminho/darkosre/files/BOOT/dtb/r36_devices.ini \
  --dk-commit SHA_DARKOSRE --a4-commit SHA_ARKOS4CLONE --ae-commit SHA_AEOLUS \
  --out build/generated-data/console_signatures.json
```

**Importante:** informar os SHAs reais dos commits das três fontes; não inventar identificação de placa. Comparar a base gerada com `src/data/console_signatures.json` antes de adotar novas assinaturas. O script não substitui a base ativa.

Para gerar a base de BIOS a partir do `System.dat` preservado:

```sh
python3 tools/mkbiosdb.py --source tools/ref/System.dat \
  --out build/generated-data/bios_db.lua
```

A base ativa `src/core/bios_db.lua` não é alterada. O arquivo DAT é uma referência de hashes, **não** distribui ROMs/BIOS protegidas.

Para gerar capas de prévia no estilo moderno da STORE:

```sh
python3 -m pip install Pillow
python3 tools/mkart.py --out build/generated-assets/art
```

Saídas: `cover.png` (640×480) e `fanart.png` (1280×720), utilizando a logo existente em `port/r36sromsstore/logo.png`. Isso não altera o tema nem substitui imagens já aprovadas.

Testes isolados, inclusive um DTB sintético e validação de destinos protegidos:

```sh
python3 -m unittest discover -s tools/tests -p 'test_*.py' -v
```

## Ferramentas preservadas e não ativadas automaticamente

- `docs/preservacao/publicar-desativado.sh`: manipula publicação/lançamentos e URLs do projeto original; exige redesenho seguro antes de usar no nosso repositório.
- Os scripts adaptados de hardware/BIOS/artes são **ferramentas offline de desenvolvimento**: não executam automaticamente no console nem substituem arquivos da STORE. A aplicação continua com as bases já aprovadas.
