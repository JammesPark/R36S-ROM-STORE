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
