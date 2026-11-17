# Plano de Estudo — Tema 6: ORM, Problema N+1 e Carregamento Antecipado (TypeScript + Prisma)

Documento de alinhamento gerado pelo `/quest` para orientar a geração da apostila compartilhável (`docs/01b-guia-estudo-tema6.md`), a sessão de tira-dúvidas e o simulado da banca no `/tutor`.

---

## 1. Perfil do Trio e Objetivo na AV4

- **Público:** Trio de apresentação da disciplina *Banco de Dados Relacional (TSI33D-TSI3)* — material compartilhável entre os 3 integrantes.
- **Domínio exigido na banca:** Todos os 3 integrantes precisam dominar os **3 pilares do Tema 6 integralmente**, estando preparados para perguntas individuais e cruzadas.
- **Nível técnico prévio:**
  - **TypeScript / Node.js:** Intermediário.
  - **SQL / MySQL:** Confortáveis (`INNER JOIN`, `LEFT JOIN`, `WHERE id IN (...)`, leitura de logs no MySQL).
  - **ORM / Prisma:** Primeiro contato prático do grupo.

---

## 2. Diretrizes Didáticas e Formato da Apostila

- **Estilo de escrita:** Completo, passo a passo e ultra didático — explicar cada conceito desde a raiz ("sem pular degraus"), mantendo rigor técnico sem presumir familiaridade prévia com ORMs.
- **Analogia central:** Operação de **pedidos em uma loja de informática**, usando a própria **TechStore** como referência concreta.
- **Comparações obrigatórias:** Quadros **SQL puro × Prisma** lado a lado baseados no schema real de `banco/init.sql` (`categorias`, `clientes`, `produtos`, `pedidos`, `itens_pedido`).
- **Fio condutor das consultas:** Listagem integrada de **`pedidos`, `clientes` e `itens_pedido`** (além da extensão em cascata até `produtos` quando aplicável).
- **Recursos visuais e de revisão:**
  - Diagramas de sequência em Mermaid comparando as idas e vindas ao MySQL (**N+1** × **`include` com `IN (...)`** × **`relationLoadStrategy: "join"`**).
  - Seção final **"Cola Rápida de Banca"** (resumo de 1 página com conceitos-chave, números de queries e respostas diretas para revisar minutos antes da apresentação).
- **Fluxo da tutoria após a apostila:** Ir direto para **tira-dúvidas livre + simulado da banca** (sem blocos intermediários obrigatórios de exercícios durante a leitura).

---

## 3. Escopo Técnico por Pilar do Tema 6

### Pilar 1 — O que é um ORM e Anatomia do Prisma
- Conceito fundamental do mapeamento objeto-relacional (`model` ↔ tabela, objeto ↔ linha, propriedade ↔ coluna, relações ↔ chaves estrangeiras).
- **Ciclo completo do Prisma do zero:**
  1. Modelagem no `schema.prisma` (datasource MySQL, generator, models e `@relation` mapeando as tabelas da TechStore).
  2. Geração de código com `npx prisma generate`.
  3. Uso do `PrismaClient` tipado em TypeScript e tradução em tempo de execução para SQL no MySQL.
- Análise de trade-offs: ganho de produtividade, autocompletar e segurança de tipos × perda de controle fino sobre o SQL gerado e abstrações perigosas.

### Pilar 2 — O Problema N+1 na Prática
- Definição clara do porquê ocorrem `1 + N` consultas ao banco e seu impacto real em latência e sobrecarga de conexões.
- **Dois níveis de exemplo na TechStore:**
  1. **Caso clássico (2 níveis):** listar `pedidos` (1 query) e buscar o `cliente` de cada pedido em loop (`N` queries).
  2. **Caso em cascata (múltiplos níveis):** `pedidos` → `itens_pedido` → `produtos` (explosão multiplicativa de round-trips).
- **Inspeção e prova real:** Passo a passo para habilitar/ler as queries geradas via logs do Prisma (`log: ['query']`) e via `general_log` do MySQL.

### Pilar 3 — Carregamento Antecipado (Eager Loading) e Controle de SQL
- Como corrigir o N+1 no Prisma usando `include` (e como estruturar `select` para evitar trafegar colunas desnecessárias).
- **Comparação técnica das duas estratégias internas no MySQL:**
  1. **Padrão do Prisma (Queries em lote com `WHERE id IN (...)`):** 1 query para os pais + 1 query por relação carregada; evita duplicação cartesiana de linhas no tráfego de rede.
  2. **`relationLoadStrategy: "join"`:** Query única com `LEFT JOIN` (ou subqueries/JSON dependendo do dialeto/versão suportada no MySQL); reduz round-trips, mas pode repetir dados do registro pai na resposta.
- Comparação direta da **quantidade de queries** (N+1 vs. `IN (...)` vs. `JOIN`).
- **Quando abandonar o ORM e usar SQL manual (`$queryRaw`):** Critérios objetivos (relatórios com `SUM`/`GROUP BY`, `LEFT JOIN` para identificar clientes que nunca compraram ou produtos sem venda, consultas analíticas e otimizações específicas em que o ORM gera SQL subótimo).

---

## 4. Formato do Tira-Dúvidas e Simulado da Banca

- **Etapa 1 — Entrega da apostila:** Gerar a explicação completa e salvar em `docs/01b-guia-estudo-tema6.md`.
- **Etapa 2 — Tira-dúvidas livre:** Abrir espaço para o trio perguntar qualquer ponto da apostila ou do código.
- **Etapa 3 — Simulado da Banca (Formato Misto — Opção C):**
  - **Perguntas orais diretas (estilo defesa AV4):** Cobrindo os 3 pilares + perguntas cruzadas entre eles, sempre trazendo *o que a banca espera ouvir* e *pegadinhas clássicas*.
  - **Análise de caso prático:** Trechos de código TypeScript/Prisma ou extratos de `general_log` do MySQL para o trio diagnosticar o problema N+1, contar queries e propor a correção adequada (`include`, `select`, `relationLoadStrategy` ou `$queryRaw`).
