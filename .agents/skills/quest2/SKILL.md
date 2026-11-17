---
name: quest2
description: >-
  Inicia o questionário em blocos temáticos e extremamente específico sobre a
  aplicação simples em TypeScript + Prisma ligada ao TechStore, gerando a
  especificação estruturada em docs/ para o /task.
---

# `/quest2` — Questionário da Aplicação TechStore (TypeScript + Prisma)

Este comando inicia o questionário (~12 a 15 perguntas específicas, divididas em **blocos temáticos de 5 a 8 perguntas por rodada**) para especificar cada detalhe da aplicação simples conectada ao TechStore (`banco/`).

## Regras Combinadas com o Usuário

- **Formato de condução:** Em blocos temáticos (5 a 8 perguntas por rodada), aguardando as respostas antes de prosseguir.
- **Extensão:** Médio (~12 a 15 perguntas específicas e diretas).
- **Estilo já escolhido:** **Scripts no Terminal / CLI simples** (extremamente simples, com foco total em TypeScript + Prisma, fácil de ler e explicar pelos 3 integrantes).
- **Requisitos já definidos:**
  - Deve incluir também uma pequena operação extra (ex.: busca/criação simples) para ilustrar a **Parte 1** ("classe = tabela, objeto = linha"), além da demonstração principal de **N+1 vs. carregamento antecipado** e **`general_log`** do MySQL;
  - Precisa ser **portátil** tanto para o notebook/SSD do grupo quanto para um **PC do laboratório**, com script/passos claros de instalação e reset seguro (`banco/reset.sh`).

## Instruções para o Agente

1. Inspecione `banco/docker-compose.yaml`, `banco/init.sql` e `banco/iniciar.sh` para fazer perguntas aderentes ao banco real.
2. Conduza o questionário em **2 blocos** cobrindo:
   - Bloco 1: Organização dos scripts/CLI (menu interativo vs. comandos `npm run ...` separados vs. ambos), estrutura de pastas/arquivos, operação extra da Parte 1 e estratégia do `schema.prisma` (`db pull` vs. schema mapeado);
   - Bloco 2: Detalhes da demonstração ao vivo (N+1 em `pedidos` + `clientes`, como ativar/filtrar/exibir o `general_log` do MySQL, correção com `include` / `JOIN` / SQL manual `$queryRaw`, contagem de queries, formatação da saída no terminal e automação de setup para notebook e laboratório).
3. Ao final, gere um documento **estruturado e limpo por seções** em `docs/02-especificacao-aplicacao.md` e informe que o usuário pode digitar `/task` para iniciar a implementação.
