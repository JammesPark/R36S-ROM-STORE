# Roadmap pós-lançamento — R36S ROM STORE

Registro de propostas de 26/11/2026. Este documento é um backlog, não um compromisso de prazo ou autorização para implementar. Nenhuma funcionalidade abaixo deve ser acrescentada antes do lançamento oficial sem aprovação específica. A versão 0.7.0-beta experimental, commit dc2c7b9f1c9b0914dbe44ee5dc78b83500187be3, foi aprovada no teste físico; popup automático de atualização de temas e remoção de instalação manual ficaram sem validação física específica.

## Antes do lançamento (escopo separado)

- [ ] Revisar README e documentação em PT-BR, EN, ES e RU, com links de idioma funcionais.
- [ ] Usar identidade oficial, logo HD, capturas reais do Matrix e Pulse, galeria e apresentação das funcionalidades.
- [ ] Corrigir links antigos, instruções de instalação, migração de pasta, tabela de controles e compatibilidade efetivamente comprovada.
- [ ] Atualizar changelog, créditos, licenças, FAQ, suporte e instruções de download.
- [ ] Validar migração de instalações antigas, atualização OTA, integridade dos pacotes e recuperação; só habilitar OTA e sincronizar main com aprovação explícita.
- [ ] Validar popup de atualização de temas quando houver atualização real e remoção manual quando houver oportunidade.
- [ ] Preservar a versão experimental aprovada como referência.

## 0.8.0-beta — Estatísticas e catálogo (sugestão de versão)

### Alta prioridade
- [ ] Ranking das 10 ROMs mais baixadas (Top 10).
- [ ] Contador global de downloads concluídos; contar somente instalações concluídas, com deduplicação de eventos e proteção contra abuso. Infraestrutura independente do PORTS BR STORE.
- [ ] Filtros por região e tamanho, sem inventar metadados de região.
- [ ] Ordenação por nome, tamanho e popularidade.
- [ ] Tela inicial: Top 10, adicionados recentemente, indicador discreto de atualizações e contagem de ROMs, sistemas e temas.

### Média prioridade
- [ ] Notificar novas ROMs e manter histórico de mudanças no catálogo.
- [ ] Permitir denunciar links quebrados.
- [ ] Estatísticas de ROMs instaladas por sistema.
- [ ] Exportar e importar favoritos.
- [ ] Melhorar descrições, ano e gênero quando disponíveis; destacar traduções PT-BR confirmadas.
- [ ] Ranking dos temas mais baixados, filtro por origem, data da versão instalada e restauração de versão anterior.
- [ ] Central de Downloads: filtros Todos/ROMs/Temas/BIOS, repetir downloads com falha, excluir registros individualmente, informar espaço necessário antes de baixar. Preservar a fila e o acesso direto aos detalhes já existentes.

### Baixa prioridade
- [ ] Contador de usuários online (avaliar privacidade, necessidade e custo).
- [ ] Avaliações e recomendações de jogos.

## 0.9.0-beta — Otimização e manutenção (sugestão de versão)

- [ ] Gerenciamento e limite do cache de capas.
- [ ] Avaliar e melhorar o modo econômico existente; medir desempenho, RAM e cache no console.
- [ ] Revisar traduções dos quatro idiomas.
- [ ] Ampliar testes em diferentes firmwares, resoluções e aparelhos.
- [ ] Revisar referências ao nome antigo e a Ports; alterar somente as referências indevidas, preservando caminhos de migração, créditos e ferramentas realmente destinadas a ports.
- [ ] Unificar ferramentas efetivamente duplicadas, sem remover ferramentas úteis.
- [ ] Limpar resíduos de temas descontinuados sem apagar dados dos usuários.
- [ ] Simplificar descrições, substituir imagens antigas e melhorar mensagens de erro com causas e ações possíveis.
- [ ] Conferir exclusão de arquivos exclusivos de desenvolvimento do pacote final.

## 1.0.0 — Estável (meta, não prazo)

- [ ] Estabilidade e compatibilidade confirmadas por testes físicos ampliados.
- [ ] Testes de instalação, atualização e recuperação em cada ambiente suportado.
- [ ] Documentação, suporte e distribuição revisados.

## Melhorias de documentação e comunidade

- [ ] Modelos de GitHub Issues para bugs e sugestões.
- [ ] Guia de solução de problemas e documentação separada por idioma.
- [ ] README com Sobre, aviso, downloads, novidades, capturas, Matrix/Pulse, catálogo, Temas Store, Downloads, BIOS e ferramentas, instalação, controles, compatibilidade, FAQ, roadmap, comunidade, contribuidores, créditos e licenças.

## Regras de execução

- Preservar Matrix como padrão e Pulse como alternativa; não acrescentar temas internos sem aprovação.
- Preservar os layouts e funcionalidades aprovados, o mapeamento de controles e as ferramentas úteis.
- Manter autoria de Lag do Lira, créditos de terceiros e GNU GPL-3.0.
- Trabalhar em Experimental, testar antes de publicar; não modificar main, habilitar OTA ou alterar o PORTS BR STORE sem autorização.
- Recursos, capas, ROMs, BIOS e temas de terceiros devem respeitar as permissões e licenças aplicáveis.
- Versões sugeridas são indicativas: 0.7.1-beta para publicação, se aprovada; 0.8.0-beta para estatísticas; 0.9.0-beta para otimização; 1.0.0 após validação ampliada. A numeração definitiva será decidida pelo responsável.
