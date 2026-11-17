# R36S PORTS BR STORE KPM — v0.1.0

Projeto **novo e independente**, criado para R36S com interface Lua/LÖVE 11.5 (640×480), backend Bash e validador Python 3. Nao utiliza o codigo nem assets do KMP ou de outros projetos.

## Funcionalidades
- Interface moderna com abas Inicio, Catalogo, Instalados, Downloads e Ajustes; PT-BR/EN.
- Catalogo JSON remoto por HTTPS, com cache local e fallback offline (inicialmente vazio).
- Instalacao em SD1 `/roms/ports` ou SD2 `/roms2/ports` usando SHA-256 obrigatorio.
- Verificacao e extracao de ZIP por Python (bloqueia traversal, links, sobrescrita e tipos especiais). 7z/RAR requer 7zz ou 7z.
- Instalacao com registro de manifesto; recusa conflitos com arquivos existentes; desinstalacao apenas de ports gerenciados.
- Controles: A seleciona/confirmar, B voltar, L/R abas, Y sincronizar, X alternar SD nos Ajustes ou desinstalar em Instalados.
- Executa port instalado pelo proprio aplicativo por handoff do launcher.
- Pipeline GitHub Actions: verifica Lua/Bash/Python, executa testes e publica ZIP instalavel e codigo-fonte.

## Como obter os pacotes
Acesse **Actions → Validar e empacotar R36S KPM → execucao mais recente → Artifacts** e baixe `R36S-PORTS-BR-STORE-KPM`. Dentro estao:
- `R36S_PORTS_BR_STORE_KPM_INSTALAR.zip`
- `R36S_PORTS_BR_STORE_KPM_FONTE.zip`

Extraia o ZIP instalavel em `/roms/ports` do SD1. A estrutura deve ficar:

```
/roms/ports/R36S PORTS BR STORE KPM.sh
/roms/ports/r36s-store-kpm/game.love
/roms/ports/r36s-store-kpm/bin/worker.sh
/roms/ports/r36s-store-kpm/bin/archive_safe.py
/roms/ports/r36s-store-kpm/config/catalog_url.txt
```

Requisitos do console: **LÖVE 11.5 compatível, Bash, Python 3, curl ou wget, sha256sum, unzip apenas para testes, findmnt para SD2; 7zz ou 7z para RAR/7z**. O runtime LÖVE **não é incluído** nesta entrega; sem um `love` funcional no sistema a interface nao inicia. Os ZIPs da Actions sao artefatos de teste, nao uma certificacao de funcionamento em hardware real.

## Catalogo JSON remoto
Edite `r36s-store-kpm/config/catalog_url.txt` e coloque uma URL HTTPS pública com JSON no formato:

```json
{
  "schema_version": 1,
  "ports": [
    {
      "id": "demo",
      "name": "Port de exemplo",
      "category": "Aventura",
      "size_bytes": 1234567,
      "download_url": "https://exemplo.org/meu-port.zip",
      "sha256": "COLOQUE_AQUI_SHA256_REAL_DO_ZIP"
    }
  ]
}
```

Substitua o exemplo por links reais autorizados e o SHA-256 de 64 caracteres; o exemplo não permite instalacao. Pressione **Y** para sincronizar. Uma URL de repositório **privado** geralmente não funciona sem autenticacao no console, portanto use um endpoint HTTPS publico. O catalogo local de seguranca começa vazio; nenhum jogo, ROM, BIOS ou port comercial é distribuido.

O ZIP esperado possui um ou mais arquivos `.sh` na raiz ou dentro de uma unica pasta externa, além dos arquivos do jogo. A desinstalacao remove tambem saves colocados dentro das pastas gerenciadas. A loja nao altera o PortMaster nem instala automaticamente dependencias especificas de cada port.

## Testar localmente no Linux
```sh
lua5.4 tests/test_json.lua
python3 tests/test_archives.py
bash tests/test_backend.sh
bash tools/build.sh
```

## Estado atual
**Primeira base de teste.** Ainda falta validar o runtime LÖVE no R36S/dArkOSen ou ArkOS, controlar downloads pausados/retomados e integrar um catalogo publico de verdade. O codigo de terceiros nao foi reutilizado.


## Catálogo adicional GameStoreBR (integração independente)

A aba **CATÁLOGO** possui duas fontes separadas: **KPM** (ports próprios, com SHA-256 obrigatório) e **GAMESTORE BR** (jogos de múltiplos sistemas). Pressione **X** dentro do catálogo para alternar as fontes; **START** abre a seleção de plataformas, direcional esquerda/direita muda as páginas; **A** confirma download, **X** no diálogo alterna SD1/SD2.

O arquivo `GameStoreBR(1).zip` fornecido não contém a listagem de jogos: seu aplicativo consulta `r36swiki.com/getgames.php` usando as ações `categories` e `games`. O projeto implementa um adaptador **próprio**, `bin/gamestore_source.py`, que consulta essa API em tempo de execução, tenta HTTPS e, por compatibilidade com a origem, permite fallback HTTP **somente para a API desse provedor**. Isso não comprova que a API ainda esteja ativa; testes automatizados simulam respostas sem depender da conexão externa.

Jogos externos são salvos como **arquivos ROM/ZIP sem extração ou execução**, dentro de `/roms/<plataforma>/` (SD1) ou `/roms2/<plataforma>/` (SD2). Não são instalados como ports pela loja KPM. A extensão e o formato são mantidos conforme o download. Os arquivos não são sobrescritos automaticamente; o SD2 é checado antes da gravação. Quando a fonte não fornece um SHA-256, o arquivo fica **sem verificação criptográfica de origem**, ainda que tenha checksum local calculado; prefira fontes autorizadas e confiáveis.

O catálogo GameStoreBR e o catálogo KPM **não são mesclados**. Nenhum jogo/ROM é incluído nos ZIPs gerados. Links e capas são propriedade dos respectivos provedores; verifique permissões de uso e distribuição. A API original usa HTTP, o que implica risco de adulteração dos metadados e downloads se não houver HTTPS. Nenhum download é executado automaticamente.
