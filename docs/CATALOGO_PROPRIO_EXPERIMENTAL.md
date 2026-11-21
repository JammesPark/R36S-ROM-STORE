# Catálogo próprio — R36S ROMS STORE — Experimental

**Etapa 1 — catálogo próprio offline (2026-11-21).** Apenas na branch
`experimental/0.6.7-beta-20261121`. A `main` permanece em **0.6.7-beta**
(`f9f7d2b9caa87ca3f6e8242641a3b483d1f29f50`).

## Dados e auditoria do filtro

| Medida | Resultado |
| --- | ---: |
| Links inspecionados nos CSVs originais | 15.727 |
| Arquivos auxiliares descartados | 75 |
| Jogos no catálogo inicial | 15.652 |
| Jogos excluídos no filtro anterior | 3.177 |
| Versões multilíngues/traduzidas reintegradas na revisão | **13** |
| Jogos excluídos após a revisão | **3.164** |
| Exclusões por região JP/CN/TW/HK sem idioma comprovado | **3.162** |
| Exclusões por idioma explícito JA/CH | **2** |
| **Jogos do catálogo próprio final** | **12.488** |
| Sistemas | **48** |

**Atenção:** `(Japan)`, `(JP)`, `(China)`, `(CN)`,
`(Taiwan)` e `(HK)` são marcadores de **região** e não provam,
isoladamente, que o jogo não ofereça inglês ou outro idioma. Para respeitar
o pedido de excluir essas versões, as 3.162 entradas continuam de fora,
**com relatório individual para eventual verificação manual posterior**.
Não estão classificadas como idioma confirmado.

A revisão reintegrou jogos com indicação explícita de tradução `[T-En ...]`,
`[T-Fr ...]`, `[T-Fre ...]`, `[tr en]` ou idiomas `(en-ja)`.
Nenhum jogo foi reintegrado com base em palpite sobre seu conteúdo.

Os pacotes de dados, separados do código no repositório, incluem:
- `catalogo_proprio.json`, `catalogo_proprio.zlib`;
- `r36sromsstore/catalogo_proprio.zlib`;
- `r36sromsstore/catalogo_proprio_ultimo_valido.zlib` (cópia inicial validada);
- `auditoria_regiao_sem_idioma_comprovado.csv` (3.162 itens);
- `exclusoes_idioma_explicito.csv` (2 itens);
- `restauradas_multilingue_traduzidas.csv` (13 itens);
- `resumo_por_sistema.csv` (originais, removidas, restantes);
- `filtrar_regioes_roms_etapa1.py` (filtro reproduzível).

As URLs de download originais foram preservadas. Não se verificou a
disponibilidade de cada link ou autorização de distribuição dos jogos.

## Independência da API GameStoreBR

Na edição Experimental:
1. `game/core/catalog.lua` usa exclusivamente `core.own_source`.
   `Catalog.provider()` devolve somente `r36s_own`;
2. `game/main.lua` carrega e recarrega somente o ZLIB instalado, sem consultas
   ao serviço de jogos anterior;
3. `game/core/rom_source.lua` mantém apenas uma interface inerte de compatibilidade,
   sem HTTP;
4. as telas de loja, pesquisa e configurações não fazem busca paginada;
5. se o ZLIB próprio falhar, **não existe retorno automático para GameStoreBR,
   catálogo legado ou outra fonte remota**;
6. as URLs diretas de ROM presentes no catálogo continuam externas e
   independentes da API usada para listar jogos.

O projeto continua com outros recursos de rede (como ROMs, capas,
atualizações de temas); não confundir a retirada de **uma API de catálogo**
com funcionamento integralmente offline de todas as ferramentas.

## Cópia de recuperação e comportamento em falhas

O arquivo principal fica em `<pasta da loja>/catalogo_proprio.zlib`.
O backup fica no mesmo diretório com o nome
`catalogo_proprio_ultimo_valido.zlib`.

- Após validar estrutura, URLs, IDs e normalizar **100%** dos registros,
  a loja grava a cópia válida por arquivo temporário + renomeação;
- se o principal faltar ou estiver inválido, tenta a cópia validada;
- quando o backup é utilizado, tenta restaurar automaticamente o principal;
- sem ambos, avisa o erro, sem consultar APIs nem carregar dados falsos;
- se uma atualização falhar durante a mesma sessão, preserva a lista
  anteriormente carregada na memória.

Limites do leitor: **4 MiB ZLIB, 16 MiB JSON, 50.000 jogos, 100 categorias**.
O backup é do catálogo, não das ROMs baixadas. Não apaga favoritos,
jogos instalados ou histórico.

## Instalação da etapa 1

1. Faça backup da pasta atual da loja Experimental.
2. Instale o código da branch Experimental (não a versão oficial `main`).
3. Extraia o pacote `R36S_ROMSTORE_Etapa1_INSTALAR_SD.zip` na raiz de
   `/roms/ports/`, preservando:
   - `r36sromsstore/catalogo_proprio.zlib`;
   - `r36sromsstore/catalogo_proprio_ultimo_valido.zlib`.
4. Se o aplicativo estiver no SD2 ou em pasta diferente, copie esses dois
   arquivos para a pasta **real do aplicativo** (`C.APP_DIR`).
5. Na loja: **Configurações → Catálogo de ROMs**. A fonte é fixa e
   `Recarregar catálogo do cartão` faz somente leitura local.
6. Verifique que a loja mostra **12.488 ROMs**. O catálogo não inclui capas
   nem descrições: isto pertence às etapas seguintes.

**Os arquivos de dados não foram commitados no GitHub**. O ZIP da build
gerado apenas pelo GitHub Actions não carrega automaticamente as 12.488 ROMs;
é necessário instalar o ZIP de dados separado. Os links não foram alterados.

## Testes e limites

- `tests/test_own_catalog.lua`: validação do ZLIB, IDs, URLs, backup,
  recuperação e ausência sem fallback;
- `tests/test_catalog_offline.py`: garante que o runtime não contém o
  endpoint anterior, a fonte é única, a busca da loja é local e o OTA da
  Experimental segue desligado;
- `.github/workflows/build.yml`: compila LuaJIT, executa testes e constrói
  o pacote apenas no CI. Não distribui esta edição pelo canal oficial.

Testes no console real (memória, desempenho e instalação dos 48 sistemas)
não fazem parte desta verificação de código. Apenas 20 plataformas tinham
instalação automática implementada na base 0.6.7-beta; as demais exigem
compatibilidade específica antes de serem habilitadas.

A **Etapa 1 não inclui** migração de acervos Archive.org, CPS1/CPS3,
ScreenScraper, download de capas ou otimização de downloads.
