---
name: quest
description: >-
  Inicia o questionário em blocos temáticos sobre como o usuário quer aprender o
  Tema 6 (ORM, Problema N+1 e Carregamento Antecipado) com TypeScript + Prisma,
  gerando o documento estruturado em docs/ para o /tutor.
---

# `/quest` — Questionário de Aprendizado (Tema 6: ORM + TypeScript + Prisma)

Este comando inicia o questionário de médio porte (~12 a 15 perguntas no total), dividido em **blocos temáticos de 5 a 8 perguntas por rodada**, para definir o plano de estudo que será usado no `/tutor` e compartilhado com o trio.

## Regras Combinadas com o Usuário

- **Formato de condução:** Em blocos temáticos (5 a 8 perguntas por turno), aguardando as respostas do usuário antes de avançar para o próximo bloco.
- **Extensão:** Médio (~12 a 15 perguntas diretas e específicas).
- **Público:** O material resultante será **compartilhado entre os 3 integrantes do trio**.
- **Profundidade esperada no `/tutor`:** Conteúdo amplo e acessível (desde os fundamentos básicos de ORM, TypeScript e Prisma até detalhes internos importantes como `schema.prisma`, `PrismaClient`, estratégia `IN (...)` vs. `relationLoadStrategy: "join"` no MySQL), mantendo os **3 tópicos do Tema 6 da AV4** como pilares centrais.
- **Recursos obrigatórios:** Analogias do cotidiano, comparações lado a lado (SQL puro × Prisma) e simulado de perguntas individuais do professor.

## Instruções para o Agente

1. Conduza o questionário em **2 blocos** (ex.: Bloco 1 sobre nível do trio, ritmo e formato do guia; Bloco 2 sobre foco nos 3 tópicos do Tema 6, profundidade técnica no Prisma e tipo de simulado/exemplos desejados).
2. Ao receber todas as respostas, gere um documento **estruturado e limpo por seções** em `docs/01-plano-estudo-orm.md`.
3. Informe ao usuário que o arquivo foi criado e que ele já pode digitar `/tutor` para receber o guia completo de estudo.
