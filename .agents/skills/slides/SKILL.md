---
name: slides
description: >-
  Inicia o questionário em blocos temáticos focado no conteúdo visual e roteiro
  dos slides da AV4 (Tema 6), gerando o documento estruturado em docs/.
---

# `/slides` — Questionário e Roteiro Visual dos Slides (AV4 - Tema 6)

Este comando inicia um questionário (~12 a 15 perguntas específicas, em **blocos temáticos de 5 a 8 perguntas por rodada**) focado **principalmente no conteúdo visual de cada slide** para a apresentação do Tema 6.

## Regras Combinadas com o Usuário

- **Formato de condução:** Em blocos temáticos (5 a 8 perguntas por rodada).
- **Foco do documento:** **Conteúdo visual dos slides** (títulos, palavras-chave, trechos curtos de código, diagramas/comparativos visuais e analogias do cotidiano), mantendo pouco texto na tela conforme exigido pela AV4.
- **Divisão do trio:** Não precisa perguntar nomes ou divisão de integrantes — o próprio trio definirá quem apresenta cada parte.

## Instruções para o Agente

1. Conduza o questionário em **2 blocos** cobrindo:
   - Bloco 1: Ferramenta/estilo visual dos slides, quantidade estimada de slides para ~15 min, ordem dos blocos (situação-problema antes da definição, conforme dica da AV4) e escolha das 3 analogias do cotidiano;
   - Bloco 2: Nível de código exibido nos slides (Prisma vs. SQL), tipo de diagramas (fluxo 1+N vs. 1 query/JOIN, print/trecho ilustrativo de `general_log` apenas como apoio visual enquanto a demo roda ao vivo), posição dos momentos de "Demo ao Vivo" entre os slides e slides de fechamento.
2. Consolide as respostas em um documento **estruturado e limpo por seções** em `docs/03-roteiro-slides.md`, detalhando slide por slide o conteúdo visual exato (título, bullets curtos, código/diagrama sugerido e tempo aproximado).
