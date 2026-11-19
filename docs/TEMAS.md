# Temas do R36S ROMS STORE HUB

## Distribuicao atual — 0.6.3-beta

**Inclusos na instalacao:** Force Nexus — Jedi e Force Nexus — Sith. O Jedi e o tema inicial, e o Sith fica imediatamente abaixo dele.

**Opcionais para download:** Tema Padrao, Neon Grid, Wii Blue e Pastel Pop (temas originais de Lag do Lira, com creditos e licenca GPL-3.0 preservados). Baixe em Configuracoes > Temas > Baixar Novos Temas. Cada pacote possui SHA-256 validado e nao executa codigo.

**Migracao sem perda de aparencia:** se a 0.6.2-beta usava algum dos quatro temas antigos, ao atualizar o Hub identifica a escolha ja salva em `theme.txt` e copia somente aquele tema para a pasta de temas do usuario usando o pacote de compatibilidade offline. Nenhum outro tema opcional e ativado ou instalado automaticamente. Temas ja baixados nao sao removidos.

As informacoes abaixo registram a evolucao historica do projeto, incluindo versoes anteriores em que os quatro legados vinham inclusos.

---
Configurações → **Temas** lista os temas instalados. **A** aplica o tema na hora (sem reiniciar). A escolha fica salva em `theme.txt`, na pasta de dados do app (`r36sporthub/conf/...`), e é aplicada automaticamente ao abrir. Se o tema salvo não puder ser carregado, o app volta ao **Tema Padrão** e avisa. Sem escolha salva (primeira abertura), o app usa o **Tema Padrão**.

Nesta versão vêm quatro temas, nesta ordem:

| id | Nome | Tela inicial | Cartões | Seleção |
|---|---|---|---|---|
| `pastel` | Pastel Pop Edition (tema claro) | carrossel | brancos com borda colorida | salto + contorno roxo/azul |
| `wiiblue` | Wii Blue Edition | grade de canais | brancos, texto azul-escuro | halo azul + leve aumento |
| `neongrid` | Neon Grid Edition | painel verde (Guia Rápido + destaque + blocos); listas em grade de capas | grafite | brilho verde; bloco selecionado fica verde |
| `default` | Tema Padrão (padrão, usado ao instalar) | menu em lista | painéis escuros | moldura rosa |

Os três primeiros usam **a mesma estrutura** (mesmas telas, menus, botões, dados e estados): só cores, fundo, cartões e efeitos mudam. O antigo tema verde e preto (id `xbox`) continua sendo migrado para o `neongrid`.

## Onde ficam

| Tipo | Pasta |
|---|---|
| Temas que acompanham o app | `src/themes/<id>/` (dentro do `game.love`) |
| Temas baixados (futuro) | `<dados do app>/user_themes/<id>/` — separados dos arquivos do app; instalar ou remover um tema nunca altera os temas inclusos |

Cada tema é **só dados** (nenhum código é executado):

```
<id>/
  theme.json    identificação, cores, botões e estilo
  preview.png   pré-visualização 320x240 (opcional)
  logo_header.png / logo_menu.png / logo_about.png / logo_splash.png   logo própria do tema (opcional; altura 32, 74, 62 e 170 px, largura conforme a proporção)
```

## theme.json

```json
{
  "id": "neongrid",
  "name": "NEON GRID",
  "description": "Texto curto exibido na lista",
  "version": "2.0",
  "author": "R36S PORT HUB",
  "preview": "preview.png",
  "colors": {
    "bg0": "#07090b", "bg1": "#10151a", "bg2": "#18212a", "bg3": "#123826", "line": "#243039",
    "text": "#eefcf3", "dim": "#9fb3a8", "faint": "#5d6f66",
    "accent": "#39ff88", "accent2": "#7dffc0",
    "yellow": "#ffd23f", "green": "#39ff88", "red": "#ff4d6a", "orange": "#ff9f43",
    "black": "#000000", "shadow": "#00000090"
  },
  "buttons": { "a": "#39ff88", "b": "#ff4d6a", "x": "#3fb6ff", "y": "#ffd23f",
    "l1": "#9fb3a8", "r1": "#9fb3a8", "start": "#9fb3a8", "select": "#9fb3a8", "dpad": "#9fb3a8" },
  "style": { "background": "neongrid", "layout": "channels", "round": 0.7, "glow": "#00cfff", "scanlines": false,
    "focus": "#39ff88", "effect": "neon",
    "card": { "fill": "#121a2e", "line": "#26355a", "text": "#f4f8ff", "dim": "#91a5c0", "faint": "#56688a", "icon": "#00f0ff" } }
}
```

- `colors`: **todas** as 16 cores são obrigatórias (`#rrggbb` ou `#rrggbbaa`). Faltou uma → o tema é recusado.
  - `bg0` fundo, `bg1` painéis, `bg2`/`bg3` painéis secundários/selecionados, `line` bordas, `text`/`dim`/`faint` textos, `accent` destaque e seleção, `accent2` destaque secundário (informações, barras), `yellow`/`green`/`red`/`orange` avisos e estados.
- `buttons`: cores dos ícones dos botões (opcional).
- `style.background`: `"retro"` (grade e scanlines, do tema padrão), `"modern"` (preto com brilho e diagonais), `"neongrid"` (quase preto, grade em perspectiva e horizonte iluminado) `"wii"` (degradê azul, faixas horizontais discretas e arcos claros na base) ou `"pastel"` (moldura em degradê ciano/azul/roxo, área clara pontilhada e formas pastel desfocadas).
- `style.layout`: `"carousel"` troca a tela inicial pelo **carrossel** (Pastel Pop); `"channels"` pela **grade de canais** (Wii Blue e Neon Grid); `"dashboard"` usa o painel NEON GRID da 0.4.7; `"xdash"` usa o **painel verde** (Neon Grid). `style.list = "grid"` mostra as listas de ports em **grade de capas** com o port escolhido em destaque. Os dois trocam também a página do port pela versão com grade de informações e ações Instalar / Iniciar / Remover / Favoritar. Sem esse campo, as telas clássicas continuam.
- `style.card` (opcional): cores dos **cartões compartilhados** (canais, áreas da Central, categorias, cartões de Configurações): `fill`, `line`, `text`, `dim`, `faint`, `icon`. Sem ele, os cartões usam as cores dos painéis. Em cartão claro, as cores de estado ficam mais escuras automaticamente para manter o contraste.
- `style.focus`: cor da seleção dos cartões. `style.effect`: `"pop"` (cartão salta, contorno roxo/azul, Pastel Pop), `"soft"` (halo e leve aumento, Wii Blue) `"neon"` (contorno pulsante e cantos de mira) ou `"glow"` (brilho verde largo, Neon Grid); sem ele, moldura simples.
- `style.chrome`: `"pill"` desenha a barra do topo e a de dicas como pílulas brancas flutuantes (Pastel Pop).
- Tema claro: basta usar cores claras em `bg0`/`bg1` e escuras em `text`/`dim` — as telas seguem a paleta.
- `style.round`: cantos (1 = arredondado como o padrão, 0 = retos).
- `style.glow`: cor do brilho do fundo. `style.scanlines`: linhas de TV antiga.

## Catálogo de temas no GitHub (futuro)

**Ainda não está ativo.** A opção **BAIXAR NOVOS TEMAS** só informa que o catálogo remoto ainda será configurado. O endereço fica em `config.lua` → `C.THEMES_CATALOG_URL` (vazio) ou no arquivo `themes_url.txt` na pasta `r36sporthub` (uma linha).

Formato previsto do índice (`themes.json` no repositório):

```json
{
  "themes": [
    {
      "id": "nome-do-tema",
      "name": "Nome exibido",
      "description": "Descrição curta",
      "version": "1.0",
      "author": "Autor",
      "preview": "https://raw.githubusercontent.com/USUARIO/REPO/main/nome-do-tema/preview.png",
      "url": "https://github.com/USUARIO/REPO/releases/download/temas/nome-do-tema.zip",
      "size": 51234,
      "sha256": "..."
    }
  ]
}
```

O `.zip` de cada tema deve conter `theme.json` (e `preview.png`) na raiz. Na integração, o app vai baixar, conferir `sha256`, validar o `theme.json` e instalar em `user_themes/<id>/`.

## Migração do antigo tema (id `xbox`)

- O id antigo `xbox` virou `neongrid`. Ao abrir, se `theme.txt` tiver `xbox`, o hub aplica o NEON GRID e regrava `theme.txt` com `neongrid`.
- O mesmo vale para backups e exportações antigas que trazem `xbox` no `theme.txt`.
- Não há tema duplicado: a pasta `themes/xbox/` não existe mais dentro do `game.love`.
- Voltar para a versão anterior (Atualizações > Backups e recuperação): a 0.4.6 não conhece o id `neongrid` e abre com o Tema Padrão, avisando. As outras preferências continuam.

## Componentes compartilhados (para quem desenvolve)

- `ui/gfx.lua` → `G.card(x, y, w, h, on, k, r)`: desenha o cartão do tema ativo e devolve a paleta do conteúdo (`text`, `dim`, `faint`, `icon`, `light`). `G.focus_k(chave, on)` anima o foco (0..1); `G.ink(cor, paleta)` escurece cores de estado em cartão claro. Uma tela nova que use esses três funciona nos dois temas sem código próprio de tema.
- `ui/channels.lua`: tela inicial em canais; as ações são as do menu (`menu.lua`: `S.open`, `S.exit_dialog`).
- `ui/icons.lua`: família de ícones de linha em `assets/icons/line/` (64x64, branco, pintada com a cor do tema), gerada por `tools/make_icons.py`. Os ícones antigos continuam como reserva.


## Loja online de temas da R36S ROMS STORE (0.0.13-beta)

**Separada** da loja de temas de EmulationStation. Um catalogo JSON HTTPS em `C.THEMES_CATALOG_URL`
permite baixar/atualizar pacotes ZIP de `theme.json` e imagens PNG. A loja nao executa scripts
extraidos. O pacote exige SHA-256 e tamanho exato, ID/versao compativeis, cores obrigatorias,
limite de espaco e validacao contra caminhos inseguros e links simbolicos. Durante uma atualizacao
um backup local permite restaurar a versao anterior em caso de falha. Tema ativo e temas inclusos
nao podem ser excluidos. O catalogo baixado fica em cache para navegacao offline.

O tema **Force Nexus — Jedi** passa a ser padrao apenas se a loja ainda nao tiver preferencia
salva em `theme.txt`. O **Force Nexus — Sith** fica disponivel no catalogo remoto.
Os temas originais (Neon Grid, Pastel, Wii Blue, Padrao) permanecem preservados.

Os ZIPs sao produzidos de `theme_packages/<id>/theme.json` e imagens PNG geradas pelo
script `tools/build_force_themes.py`. O indice publicado em
`https://raw.githubusercontent.com/JammesPark/R36SPORTSBR-STORE-UPDATES/main/themes/themes.json`
e gerado pelo workflow de publicacao somente depois de conferir os arquivos ZIP.


## Atualizacoes cumulativas da STORE (0.0.14-beta)

O arquivo publico `update.json` usa `url`, `sha256` e `size` do ZIP completo;
isso permite que consoles em versoes antigas atualizem em um salto. O pacote incremental
permanece separado em `incremental_url`, `incremental_sha256`, `incremental_size`,
`incremental_min_version` e `incremental_max_version`. O cliente 0.0.14-beta escolhe
automaticamente o menor pacote apenas quando a versao-base corresponde; caso contrario
utiliza o ZIP completo. A instalacao sempre verifica integridade e cria backup para restauracao.


## Fidelidade visual Force Nexus (0.0.15-beta)

A tela inicial dos temas `forcejedi` e `forcesith` e baseada **diretamente** nos
HTMLs aprovados em `design/force-v4/jedi-v4.html` e `design/force-v4/sith-v4.html`.
O script `tools/render_force_v4.py` renderiza backgrounds 640x480 sem dados de
exemplo, previews ilustrativas 640x480 e um atlas de seis selecoes 402x196.
Na execucao, `ui/force_dash.lua` sobrepoe exclusivamente dados reais do console e
do Cloudflare. A vitrine `Em destaque` nao integra esses temas. O tema Sith 1.0.1
pode ser instalado independentemente; os outros temas nao mudam.


## Force Nexus: Novidades / Em Breve (0.0.17-beta)

Os temas Jedi e Sith utilizam a mesma interface de 640x480, agora com duas abas no carrossel esquerdo:
`NOVIDADES` (jogos com data real e download liberado) e `EM BREVE` (jogos sem link de download).
Use D-pad para selecionar as abas, A para alternar e L1/R1 para percorrer os jogos; X também muda de aba.
A lista reflete o catálogo ativo e é atualizada quando o JSON remoto muda, sem misturar fontes.
Os HTMLs das duas variantes são regenerados no build. Não use nomes de jogos fictícios no pacote final.
O Jedi aceita agora sobreposição por pacotes de temas mais novos em `user_themes/forcejedi`:
a versão incluída é preservada como fallback e pode ser restaurada removendo o pacote baixado.


## Force Nexus V3 final (0.0.18-beta; Jedi/Sith 1.0.4)

Grade de seis botoes compactos (direita, y=58 e 148; 135x84) acima do ranking.
Top 5 Downloads (y=242, h=188; capas 78x134) abaixo dos botoes, sem mudancas no Top 5 real.
Abas `NOVOS` e `EM BREVE`, sem contador numerico nem selo sobre a capa.
Indicadores centralizados com barra ativa longa, setas ao lado. HTML fonte em `design/force-v4/`, assets 640x480 e atlas selecionado 405x168 gerados via `tools/render_force_v4.py`.
O layout geométrico usa `ui/force_dash.lua`; a versao 0.0.18-beta da STORE e necessaria para aplicar a nova geometria. Depois, assets de temas posteriores podem ser atualizados individualmente conforme o catalogo de temas.


## Force Nexus V6 aprovado (0.0.19-beta; Jedi/Sith 1.0.5)

- Atalhos inferiores da coluna esquerda alinhados com 14px de respiro inferior, estrela vazada permanente no Favoritos.
- Titulo exibido: `R36S PORTS BR STORE HUB`, e `JEDI/SITH EDITION · v1.0.5` na fonte/cor do tema.
- Setas graficas do carrossel removidas; L1/R1 e indicadores continuam funcionando.
- Nova variacao de Top Downloads (`ui/force_ranking.lua`) na Central de Conteudo, com cinco miniaturas de capas reais e capa ampliada, restrita aos temas Force e respeitando a fonte do catalogo.
- Os arquivos de referencia `design/force-v4/*.html` e o renderizador geram as novas previews e fundos de 640x480; a geometria dos atalhos e a tela de ranking pertencem ao Lua, exigindo STORE 0.0.19-beta. Temas 1.0.5 ficam disponiveis individualmente na Loja de Temas.


## Logo oficial universal com nuvem (0.0.21-beta)

A identidade visual aprovada é **R36S PORTS BR STORE HUB** (R36S metalizado,
BR verde/amarelo/azul, console azul com nuvem e seta de download). O mestre RGBA
compacto fica em `tools/brand/logo_oficial_cloud.webp` e o gerador em
`tools/make_brand_logos.py`. A cada build de `tools/render_force_v4.py`, são
criados PNGs de cabeçalho 46x32 (ícone), menu 218x74, Sobre 132x62 e splash
252x170, todos com proporção preservada, nos temas Padrão/Neon Grid/Wii Blue/
Pastel/Force Jedi e pacotes Jedi/Sith.

Os temas Force Jedi e Sith têm versão **1.0.6**, distribuem os quatro PNGs
adicionais e são atualizáveis isoladamente pela Loja de Temas. A versão do
Hub é **0.0.21-beta** para atualizar também a logo dos temas inclusos e as telas
de abertura/menu/Sobre. Não substituir `dev_logo.png` nem `logo_dev.png` dos
créditos. Para gerar manualmente: `python3 tools/make_brand_logos.py` após
instalar Pillow. O HTML Jedi/Sith tem o ícone novo embutido para visualização
sem depender da rede.


## Ajuste anti-recorte das logos (0.0.22-beta; Force 1.0.7)

O gerador `tools/make_brand_logos.py` conserva uma margem real de alpha 100% transparente
entre os elementos luminosos e os limites de cada PNG. Variantes mantidas: cabeçalho 46x32,
menu 218x74, Sobre 132x62, splash 252x170 e launcher 128x128, com proporções sem deformação.

O código `ui/gfx.lua` limita a escala das logos à área destinada ao cabeçalho (40px),
à zona acima da versão no menu e à área da abertura/Sobre. Isto impede que temas com
`logo_header_scale=1.3` cortem as bordas inferiores do ícone. Os HTMLs de referência
Jedi e Sith não precisam manter manualmente cópias antigas do PNG: o renderizador agora
injeta a logo gerada no momento do build, com `await logo.decode()` antes da captura.

Verificação: `python3 tools/tests/test_brand_logos.py` após instalar Pillow.
A logo do desenvolvedor e os créditos existentes permanecem intocados.


## Logo com bandeira brasileira — padrão oficial (0.0.23-beta; Jedi/Sith 1.0.8)

A logo oficial adotada possui BR metalizado como o texto PORTS e uma pequena
bandeira do Brasil na faixa inferior. Fonte transparente com alfa:
`tools/brand/logo_oficial_cloud.webp`. A opção **sem bandeira**, também salva,
está em `tools/brand/logo_alternativa_sem_bandeira.webp`, mas não substitui a
oficial. O gerador `tools/make_brand_logos.py` produz os quatro PNGs oficiais
para os temas padrão, Neon Grid, Wii Blue, Pastel, Force Jedi/Sith e launcher.
Os assets ficam também nos diretórios dos temas no repositório para inspeção,
e são reproduzidos identicamente na compilação.

A tela **Sobre** usa a variante `logo_about.png` com escala 1.04 e posição
`(26,66)`: marca um pouco maior (+13% de largura visível), dentro do cartão
esquerdo, sem invadir o cartão do Telegram. O renderizador `ui/gfx.lua` limita
a escala para evitar cortes. A variante de cabeçalho usa apenas o ícone do
console com nuvem e mantém 46x32.


## Correção da logo pequena em todos os temas (STORE 0.0.24-beta / Force 1.0.9)

As fotos do console revelaram que o logo de cabeçalho renderizava apenas ~23x24 pixels
visíveis devido ao formato 46x32 com margem de 4px e escala forçada. O gerador passa a
criar `logo_header.png` **42x38** com 2px de margem externa, mantendo o console
com nuvem de download e azul oficial. A área útil cresce para aproximadamente 35x36px.

Em `ui/gfx.lua`, a logo global `assets/logo/logo_<variant>.png` passa a ter prioridade
sobre `themes/<id>/logo_<variant>.png`, para evitar que pacotes antigos reinstalem
identidade visual ultrapassada. Os arquivos dos próprios temas ficam disponíveis como
fallback caso a logo global esteja ausente.

O cabeçalho da tela Force é redesenhado a cada quadro, por cima do background do tema:
assim a cor/versão da marca também são corrigidas mesmo com o pacote Sith 1.0.7 antigo.
Foi removido o `hue-rotate(239deg)` do logo nos HTMLs Jedi/Sith; a marca mantém o azul
oficial em qualquer paleta de cores. Os elementos do menu, dos catálogos e do Top 5
não foram modificados.

As logos horizontais dos menus, abertura e Sobre continuam completas. O cabeçalho
compacto exibe somente o console/nuvem maior e o nome textual da loja ao lado, pois
uma imagem com toda a marca seria ilegível numa faixa de 40px.


## Cabeçalhos afastados da logo (STORE 0.0.25-beta; Jedi/Sith 1.0.10)

O nome e a versão do tema não devem sobrepor o ícone no canto esquerdo.
Force começa o texto em x=116, demais cabeçalhos da STORE em x>=112,
incluindo G.header, channels, Neon Grid e xdash. A divisória do cabeçalho
se desloca junto e os avisos de atualização respeitam a nova posição.
O HTML dos temas Force também foi atualizado com 60px de margem após o
ícone, para correspondência com a renderização Lua em 640x480.
A logo oficial com bandeira brasileira não foi substituída.


## Logo oficial completa e sincronizacao geral (STORE 0.0.26-beta; Jedi/Sith 1.0.11)

O arquivo `tools/brand/logo_oficial_cloud.webp` e agora a arte completa
aprovada de **1000x298** com BR prateado e pequena bandeira brasileira.
O `logo_header.png` exibe a marca inteira em **140x40**, com
letterbox e proporcao **3,36:1**. Nao existe mais o recorte `logo.crop(...0.29)`
para o cabecalho; o recorte do console continua apenas no icone do launcher.
Os nomes das telas comecam depois da largura efetivamente desenhada.

O game.love leva todos os temas incluidos (Jedi, Padrao, Neon Grid, Wii Blue,
Pastel). O build tambem inclui `theme_updates/forcesith` para atualizar
automaticamente o Sith quando ele **ja estiver instalado**; temas opcionais nao
sao instalados sem escolha do usuario, nem rebaixados quando a copia local for
mais recente. A versao de `theme.json` e gravada por ultimo para permitir
nova tentativa caso a copia dos assets falhe.


## Atualizacao conjunta de TODOS os temas — STORE 0.0.27-beta

Na atualizacao geral da STORE, os cinco temas internos vao no mesmo game.love.
`tools/bundle_theme_updates.py` inclui no pacote todos os temas opcionais
em `theme_packages/`, excluindo os ja internos. `core/themes.lua` so os atualiza
quando ja estavam instalados em `user_themes/<id>/` e a versao nova for maior.
Nenhuma instalacao de tema opcional e forçada; arquivos personalizados sao preservados.

Testes de comportamento: `luajit tools/tests/test_theme_sync_runtime.lua` e
`python3 tools/tests/test_theme_sync.py`. QA visual:
`python3 tools/tests/test_all_theme_layouts.py` checa seis cabecalhos
em 640x480, margens e capturas Playwright Jedi/Sith publicadas como artifact.
Previews HTML nao substituem teste no console fisico.

A logo oficial com BR prateado e bandeira do Brasil continua a mesma.
