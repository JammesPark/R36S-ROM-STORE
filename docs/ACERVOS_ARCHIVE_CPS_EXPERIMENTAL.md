# Pesquisa de acervos Archive.org — CPS1, CPS2 e CPS3

Data: 2026-11-21. **Somente planejamento e fontes candidatas. Nenhum link de ROM foi substituido ou publicado.**

## Escopo

| Plataforma | Situacao no catalogo proprio filtrado |
| --- | --- |
| CPS1 | Nao consta entre os 48 sistemas; requer inclusao da categoria e registros validados |
| CPS2 | Ja consta com 82 registros |
| CPS3 | Nao consta entre os 48 sistemas; requer inclusao da categoria e registros validados |

Os tres sistemas sao emulados pelo FinalBurn Neo. Em sistemas ArkOS, as pastas esperadas sao `/roms/cps1`, `/roms/cps2` e `/roms/cps3` (ou equivalentes no SD2), dependendo do firmware. Nao adicionar instalacao automatica antes de confirmar compatibilidade no codigo e no console.

## Fontes candidatas (Archive.org)

- https://archive.org/details/fbnarcade-fullnonmerged — colecao arcade FBNeo citada em referencias publicas; confirmar o status atual de cada arquivo;
- https://archive.org/details/2020_01_06_fbn — romset FBNeo mencionado em guias externos; verificar versao, cobertura e acesso.

**Verificacao pendente:** acesso aos itens do Archive.org nao foi concluido nesta pesquisa; nao assumir que qualquer arquivo individual esteja publicamente baixavel ou mais rapido.

## Regras para aproveitamento

1. Manter CPS1, CPS2 e CPS3 como sistemas separados no catalogo, evitando duplicacoes com FBNeo, MAME e CPS2 existente.
2. Identificar pelo shortname arcade (ex.: `sf2`, `ssf2`, `sfiii`) e versao do romset; nome comercial isolado nao e identificador suficiente.
3. Preferir conjuntos compatíveis com o core presente no console e, quando aplicavel, formato non-merged para evitar dependencias entre parent/clone. Para CPS3, verificar dependencias especiais.
4. Preservar o filtro de versoes apenas japonesas/chinesas, mas nao excluir jogos multilingues por regiao sem revisao.
5. Nunca afirmar que um arquivo e baixavel antes de verificar a disponibilidade e os direitos de uso/distribuicao.
6. Depois da validacao, associar capas e metadados via Libretro/ScreenScraper, sem usar a API GameStoreBR.

Referencias tecnicas:
- https://github.com/finalburnneo/FBNeo
- https://github.com/christianhaitian/arkos/wiki/ArkOS-Emulators-and-Ports-information
- https://github.com/libretro/docs/blob/master/docs/guides/arcade-getting-started.md
