---
name: tutor
description: >-
  Entrega o guia didático completo (apostila compartilhável) sobre ORM,
  TypeScript + Prisma, Problema N+1 e Carregamento Antecipado, seguido de
  tira-dúvidas e simulado de perguntas da banca.
---

# `/tutor` — Guia Didático e Tutoria (Tema 6: TypeScript + Prisma)

Este comando inicia o ensino do **Tema 6: ORM e o problema N+1** com **TypeScript + Prisma**, conectado ao contexto real do banco **TechStore** (`banco/init.sql`).

## Regras Combinadas com o Usuário

- **Formato:** Explicação completa em estilo **guia/apostila compartilhável** para os 3 integrantes do trio primeiro, e depois abertura para tira-dúvidas e simulado de perguntas do professor.
- **Escopo e profundidade:** Conteúdo amplo e básico/acessível, incluindo detalhes internos do Prisma (`schema.prisma`, `PrismaClient`, geração de queries, padrão `WHERE id IN (...)` vs. `relationLoadStrategy: "join"` no MySQL), mas com ênfase máxima nos **3 tópicos obrigatórios do Tema 6**:
  1. **O que é um ORM** (classe/model = tabela, objeto = linha, ganho de produtividade vs. perda de controle sobre o SQL);
  2. **O problema N+1** (1 consulta de pedidos + N consultas de cliente, impacto real e inspeção via `general_log` do MySQL);
  3. **A correção** (carregamento antecipado / `include`, `JOIN` gerado vs. queries em lote, comparação de quantidade de consultas e quando escrever SQL manual / `$queryRaw`).
- **Didática obrigatória:** Analogias do cotidiano, comparações lado a lado (**SQL puro × Prisma**) usando tabelas reais do TechStore (`clientes`, `pedidos`, `itens_pedido`, `produtos`), e simulado de perguntas individuais da banca.

## Instruções para o Agente

1. Leia `docs/01-plano-estudo-orm.md` (caso não exista, avise o usuário e sugira rodar `/quest` primeiro) e `banco/init.sql`.
2. Gere o guia completo de forma didática, limpa e organizada, **salvando-o também em `docs/01b-guia-estudo-tema6.md`** para facilitar o compartilhamento com os outros dois colegas do trio.
3. Ao final da entrega do guia, conduza a sessão de dúvidas e o simulado de perguntas do professor (cobrindo inclusive perguntas cruzadas entre as 3 partes).
