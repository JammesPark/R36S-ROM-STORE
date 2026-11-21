# Catálogo próprio Experimental — Etapa 1 concluída

Branch: `experimental/0.6.7-beta-20261121` — código LÖVE 11.5,
sem API GameStoreBR e sem OTA oficial. A `main` permanece intacta.

## Catálogo atual: **15.652 ROMs / 48 sistemas**

| Evolução do catálogo | Quantidade |
| --- | ---: |
| Importação dos arquivos originais | 15.652 |
| Filtragem preliminar JP/CN | 12.475 |
| Reintegração prévia de versões explicitamente traduzidas/multilíngues | +13 |
| Total da versão intermediária | 12.488 |
| **Reintegração agora, com siglas** | **+3.164** |
| **Total atual** | **15.652** |

As 3.164 entradas restauradas foram identificadas a partir de marcadores
no `file_name` original, sem inferir idioma a partir de palavras do título.

| Sigla exibida ao fim do nome | Referência do arquivo | Quantidade |
| --- | --- | ---: |
| `[JP]` | Japan / JP / japonês declarado | 3.122 |
| `[CN]` | China / CN / chinês declarado | 1 |
| `[TW]` | Taiwan / TW | 41 |
| `[HK]` | Hong Kong / HK | 0 |

Por exemplo, `Auto Bahn Tokio (Japan)` será exibido como
`Auto Bahn Tokio (Japan) [JP]`. **Região não comprova idioma.**
As 12.488 entradas anteriormente mantidas não tiveram os nomes alterados.
Nenhum jogo foi duplicado e as ROMs não estão dentro do pacote: são links.

Para as 3.164 entradas reintegradas, o catálogo inclui os metadados
`original_name`, `region_tag`, `region_tag_basis`,
`region_source_tags` e `reintegrated`. O campo `name` tem a sigla
visível; `id`, `file_name` e `download_url` mantêm o valor original.
Os metadados próprios são preservados no JSON para futuras buscas de
capas por nome original. O motor de busca atual utiliza `name` e mantém
a sigla visível nas listas.

## Arquivos gerados separadamente do código

- **`R36S_ROMSTORE_INSTALAR_SD_15652_SIGLAS.zip`**:
  `r36sromsstore/catalogo_proprio.zlib` e
  `r36sromsstore/catalogo_proprio_ultimo_valido.zlib`;
- **`R36S_ROMSTORE_CATALOGO_COMPLETO_15652_SIGLAS.zip`**:
  os dois ZLIBs, JSON legível, manifesto SHA-256, relatório de
  ROMs reintegradas `roms_reintegradas_siglas.csv`, resumo com totais por
  sistema e o script `reintegrar_regioes_roms.py`.

**Estes arquivos de dados foram entregues separadamente ao usuário e não
estão commitados no GitHub.** O ZIP de instalação publicado na branch
`experimental-downloads` contém somente o aplicativo. Instalar apenas
o executável não coloca as 15.652 ROMs no catálogo.

## Instalação e backup

1. Instale a edição Experimental da Etapa 1 compilada com sucesso.
2. Faça backup dos dois ZLIBs de catálogo já instalados.
3. Extraia `R36S_ROMSTORE_INSTALAR_SD_15652_SIGLAS.zip` diretamente
   na partição de ROMs em `/roms/ports/`, ou na pasta real do aplicativo
   quando instalado no SD2.
4. Confira `/roms/ports/r36sromsstore/catalogo_proprio.zlib` e
   `/roms/ports/r36sromsstore/catalogo_proprio_ultimo_valido.zlib`.
5. Reinicie a loja e confira **15.652 ROMs / 48 sistemas**.

Para **trocar apenas os dados do catálogo**, não é necessário substituir
`game.love`. Para usar as **etiquetas coloridas e L2/R2**, instale o
**novo instalador Experimental** publicado na branch de downloads: são
mudanças de interface Lua, não fazem parte do arquivo `.zlib`.

## Validação e recuperação offline

- Arquivo ZLIB: **652.613 bytes**, abaixo do limite de 4 MiB.
- JSON descompactado: **5.490.288 bytes**, abaixo do limite de 16 MiB.
- IDs únicos: **15.652**; URLs de download únicas: **15.652**.
- Sistemas: **48**, sem modificação da ordem.
- URLs modificadas: **0**; nomes de arquivos originais modificados: **0**.
- Backup compactado idêntico à versão nova.
- Os dois pacotes passaram no teste local de integridade ZIP e ZLIB.

O aplicativo lê somente o catálogo próprio local. Se o arquivo principal
faltar/corromper, tenta a cópia válida ao lado. Não retorna à API GameStoreBR.
O canal de atualização OTA oficial permanece desativado nesta edição.
Testes reais de desempenho e abertura no console para a nova contagem ainda
precisam ser feitos.

## Etapas seguintes — ainda não iniciadas

A próxima etapa prevista é a **associação e otimização de capas**
para o catálogo completo, usando o `file_name` e/ou `original_name`
sem as novas siglas para não prejudicar o reconhecimento dos títulos.
Libretro é a primeira fonte de capas, ScreenScraper é complementar;
a consulta deve ser feita no PC, não durante a navegação do console.

### Interface de regiões e visualizações (código implementado)

**Status: código integrado e compilação automatizada; teste real no console pendente.**

- [x] Identificar a região por etiqueta colorida, separada do sistema.
- [x] **JP** rosa-coral `#FF738A`, **CN** laranja `#FFC065`,
      **TW** verde `#58E0A6`, **HK** lilás `#B9A1FF`.
- [x] Manter o sistema em ciano `#38D6FF`, usando etiquetas arredondadas.
- [x] Retirar `[JP]`, `[CN]`, `[TW]` ou `[HK]` e, quando coincidir
      com o selo, a indicação textual `(Japan)`, `(China)`, `(Taiwan)`
      e `(Hong Kong)` apenas da **visualização**. Preservar `p.name`,
      `original_name`, ID, URL e arquivo original.
- [x] Aplicar nas telas de **Lista, Grade, Vitrine e Detalhes**; listas de
      resultados de pesquisa também compartilham o componente de linha.
- [x] Disponibilizar no **Tema Padrão** três visões reaproveitadas:
      Lista original, Grade Jedi (`ui/covergrid.lua`) e Vitrine Pastel
      (`ui/coverview.lua`).
- [x] Adicionar **L2 para anterior** e **R2 para próximo** na tela de ROMs.
      A preferência `rom_view_default` é persistida; existe alternativa
      em Configurações > Catálogo de ROMs.
- [x] Manter o tema Neon com seu próprio modo de grade, sem troca de perfil
      via L2/R2.
- [x] Remover do pacote do código **Pastel, Wii Blue, Force Nexus Jedi e Sith**.
      Somente `themes/default` e `themes/neongrid` são incluídos.
- [x] Impedir que temas antigos já instalados no SD sejam exibidos e
      selecionados (sem apagar dados privados automaticamente).
- [x] Acrescentar testes de região, mapeamento de gatilhos e integridade
      da lista de temas ao GitHub Actions.
- [ ] Testar a navegação, a legibilidade de títulos longos e o funcionamento
      físico dos gatilhos em console R36S/R36H real.

O protótipo HTML de referência continua independente. Alterar o visual
não modifica as 15.652 ROMs nem inicia a busca por capas.

Migração de links para Archive.org, inclusão de CPS1/CPS3, novas instalações
por sistema e otimizações de velocidade não fazem parte desta alteração.
