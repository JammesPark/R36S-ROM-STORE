# R36S ROMS STORE — v0.2.2 (teste)

Loja de ROMs para consoles R36S, com interface Lua + LÖVE 11.5 na resolução **640×480**, catálogo único GameStoreBR (`r36swiki.com/getgames.php`) e arquivos baixados diretamente para SD1/SD2. **Nenhuma ROM, BIOS ou conteúdo comercial é distribuído com o aplicativo.**

## Identidade definitiva

- Nome apresentado, título do LÖVE, launcher, diretório, logs e pacotes: **R36S ROMS STORE**.
- Launcher: `R36S ROMS STORE.sh`
- Diretório do app: `/roms/ports/r36s-roms-store/`
- Arquivos de dados: `/roms/ports/r36s-roms-store/state/`
- Identidade LÖVE: `r36s-roms-store`
- O instalador legado de ports e seu validador de arquivos foram retirados. Os arquivos ROM são salvos **sem descompactação ou execução**.

## Interface

- Menu lateral; catálogo com categorias e grade 3×2 de capas; busca, detalhes, favoritos, histórico, downloads e configurações.
- Idiomas: português (Brasil), inglês, espanhol e russo.
- Temas: azul, roxo, verde, laranja, rosa, vermelho e gelo. Preferências mantidas em `state/roms_settings.json`.
- Favoritos salvos em `state/roms_favorites.json`, com indicador SD1, SD2, ambos ou não baixado.
- Histórico em `state/roms_downloads.json`. Cache de categorias e jogos: `state/gamestore_*.json`.
- Os arquivos baixados ficam em `/roms/<plataforma>/` ou `/roms2/<plataforma>/`, sem sobrescrever outros arquivos.

## Instalar ou atualizar no SD1

1. Baixe o ZIP instalável da execução mais recente do GitHub Actions.
2. Extraia na **raiz de `/roms/ports/`**, criando `R36S ROMS STORE.sh` e `r36s-roms-store/`.
3. Abra a loja em **Ports**. É necessário PortMaster com runtime LÖVE 11.5, Python 3 e acesso à rede para consultar o catálogo.
4. Na primeira execução, o launcher procura dados da versão anterior em uma pasta técnica legada e copia, **sem apagar nem sobrescrever arquivos**, idioma, tema, favoritos, histórico e cache de catálogo para a nova estrutura. Capas poderão ser baixadas novamente.
5. Após confirmar que favoritos e configurações estão presentes na nova versão, você pode remover **o launcher antigo e a pasta técnica legada** manualmente, se não precisar mais deles. Faça um backup antes. **Não apague sua pasta de ROMs** (`/roms/<plataforma>/` ou `/roms2/<plataforma>/`).

## Controles

- Cima/baixo: mover a seleção no menu inicial; esquerda/direita: alternar foco. Movimento do direcional **não abre** telas.
- A: confirmar opção; B: voltar; L1/R1: trocar entre áreas principais.
- Catálogo: START busca; Y atualiza lista; X favorita; esquerda na primeira coluna acessa categorias.
- Confirmação: X ou esquerda/direita alterna entre SD1 e SD2.

## Diagnóstico

Se o aplicativo fechar, envie `/roms/ports/r36s-roms-store/log.txt` ou `state/logs/startup.log`. O launcher usa `control.txt` e `runtimes/love_11.5/love.txt` do PortMaster, com fallback para o comando `love` do sistema. O funcionamento gráfico no console precisa ser confirmado com teste real.

## Testes

```sh
lua5.4 tests/test_json.lua
R36S_STORE_OFFLINE_TEST=1 lua5.4 tests/test_ui_smoke.lua
python3 tests/test_gamestore.py
python3 tests/test_single_catalog.py
python3 tests/test_brand_cleanup.py
bash tests/test_bootstrap.sh
bash tools/build.sh
```

A API GameStoreBR é de terceiros e sua disponibilidade depende do provedor. Os arquivos que ela disponibiliza estão sujeitos aos direitos dos respectivos titulares. A interface deste projeto é independente.
