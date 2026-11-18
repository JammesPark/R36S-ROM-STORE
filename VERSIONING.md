# Política de versionamento — R36S ROMS STORE

## Fonte única
A versão corrente está em [VERSION](VERSION), apenas o número, sem prefixo "v". Nenhum outro arquivo de código, documentação ou workflow deve definir separadamente a versão corrente.

No build, VERSION é copiado para src/VERSION (incluído no game.love) e port/r36s-roms-store/VERSION. O build nomeia os pacotes R36S_ROMS_STORE_v<versão>_TESTE.zip e R36S_ROMS_STORE_v<versão>_FONTE.zip. O rodapé do aplicativo lê VERSION do LÖVE.

## Sequência
- 0.2.X-beta: correções pequenas e melhorias dentro da fase atual.
- 0.3.0-beta, 0.4.0-beta etc.: marcos funcionais relevantes. A versão 0.3.0-beta introduz o atualizador online.
- 1.0.0: primeira versão estável somente após validação completa no console físico, incluindo SD1/SD2, catálogo, downloads, exclusão e controles.

Não renumerar retroativamente versões ou pacotes já entregues. Commits e builds internos de teste não precisam gerar uma nova versão pública: aumentar VERSION somente ao entregar um conjunto identificável de mudanças.

## Procedimento
1. Alterar somente VERSION para definir a nova versão.
2. Atualizar CHANGELOG.md com as mudanças.
3. Rodar testes e bash tools/build.sh.
4. Verificar que rodapé, pacotes ZIP e VERSION internos coincidem.
5. Testar o build beta no dispositivo antes de declarar versão estável.
