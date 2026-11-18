---
name: tutor-app
description: >-
  Guia interativamente o usuário na construção passo a passo de um mini app
  didático em TypeScript + Prisma em uma pasta separada (ex.: pratica/),
  usando modo guiado com lacunas (TODOs) para praticar todos os conceitos
  ensinados no /tutor sem alterar app/, banco/ ou docs/.
---

# `/tutor-app` — Oficina Prática Guiada (Modo Lacunas • TypeScript + Prisma)

Este comando conduz a construção prática de um **mini app simples de terminal** em uma **pasta separada** (padrão `pratica/`), conectado ao banco **TechStore** em modo somente leitura, para aprender na prática tudo o que é ensinado no `/tutor`.

---

## Regras Combinadas com o Usuário

- **Isolamento total:** Nunca altere arquivos em `app/`, `banco/` ou `docs/`. Todo o código de estudo fica em uma pasta separada na raiz (padrão: `pratica/`, já ignorada no `.gitignore`, ou outro nome escolhido pelo usuário — caso escolha outro nome, adicione `<pasta>/` ao `.gitignore` da raiz automaticamente).
- **Banco de dados:** Usar o próprio **TechStore** (`localhost:3306/techstore`, usuário `root`/`root` para permitir habilitar e ler `mysql.general_log`) em **modo somente leitura** (`SELECT`s + controle do `general_log`, sem alterar os dados das tabelas).
- **Formato do mini app:** Scripts simples de terminal em **TypeScript + Prisma** (sem servidor HTTP/web).
- **Dinâmica de programação (Modo Guiado com Lacunas):**
  - O agente **não entrega o código pronto de uma só vez** nem copia `app/`.
  - A cada etapa, o agente cria o **esqueleto limpo do arquivo** apenas com o código necessário e marcações curtas de `TODO` (sem blocos longos de explicação nem exemplos comentados dentro do arquivo).
  - **No chat**, para **cada `TODO`** da etapa, o agente deve sempre dizer explicitamente: (1) em qual arquivo/linha ele está, (2) **o que exatamente o usuário precisa fazer nele**, e (3) um **exemplo genérico de sintaxe** (com outro nome de model/campo fictício, ex.: `prisma.usuario.findMany(...)`) como referência, sem entregar a resposta pronta.
  - Quando o usuário disser que preencheu (ou pedir ajuda/revisão), o agente valida o código, executa o script no terminal junto com ele e corrige/explica eventuais erros antes de seguir.
- **`schema.prisma` incremental:** Construído aos poucos (`Cliente` → `Pedido` → `Produto` / `ItemPedido`), com lacunas de `@map`, `@@map` e `@relation` para o usuário completar e rodar `npx prisma generate`.
- **Inspeção progressiva de queries:** Começar na Etapa 1 com `log: ["query"]` no `PrismaClient` e, na Etapa 2, montar com lacunas o helper de `mysql.general_log` para comparar o log do ORM com o log real do MySQL.
- **Recursos didáticos obrigatórios em TODA etapa:**
  1. **Analogia rápida** conectada ao `/tutor` (`docs/01b-guia-estudo-tema6.md`) antes de codar;
  2. **Erros propositais / debug guiado** (provocar N+1, esquecer `@map` ou omitir campo antes de corrigir);
  3. **Comparação lado a lado** do código Prisma escrito pelo usuário × SQL capturado no MySQL;
  4. **Perguntas estilo banca** sobre o código que o usuário acabou de escrever antes de liberar a próxima etapa;
  5. **Explicação de recursos fora do Prisma (no chat):** sempre que um esqueleto usar algo nativo do Node/JS (ex.: `console.table`, `import "dotenv/config"`, `performance.now()`, `.map()`), explique **no chat** de onde vem, o que é e o que faz, mantendo os arquivos de código limpos e acessíveis para os 3 integrantes do trio.

---

## Roteiro da Oficina (1 Etapa por Turno)

### Etapa 0 — Setup da Pasta Separada + Primeiro Model (`Cliente`)
1. Leia `docs/01b-guia-estudo-tema6.md` (se existir) e `banco/init.sql` para alinhar nomes reais de tabelas e colunas.
2. Pergunte apenas o nome da pasta de prática (sugestão: `pratica/`, já listada no `.gitignore`), garanta que `<pasta>/` esteja no `.gitignore` da raiz (se usar outro nome) e verifique se o MySQL 8 está ativo na porta `3306` (se não estiver, oriente rodar `npm run setup` no Windows ou `./banco/iniciar.sh` no Linux).
3. Crie na pasta separada o boilerplate mínimo (`package.json`, `tsconfig.json`, `.env`), instale as dependências (`@prisma/client`, `dotenv`, `prisma`, `tsx`, `typescript`) e crie um `prisma/schema.prisma` inicial contendo o `datasource`, `generator client` (com `previewFeatures = ["relationJoins"]`) e o **`model Cliente` com lacunas (`TODO`)** para `@@map("clientes")` e `@map("data_cadastro")`.
4. **Erro proposital sugerido (opcional/rápido):** deixar o usuário rodar ou analisar o que aconteceria se `@map`/`@@map` faltasse, depois completar as lacunas, rodar `npx prisma generate` e avançar.

### Etapa 1 — Parte 1: ORM Básico + `log: ["query"]`
1. Apresente a analogia rápida do ORM (`model` = tabela, objeto = linha).
2. Crie `src/lib/prisma.ts` com lacuna para o usuário ligar `log: ["query"]` no `new PrismaClient(...)`.
3. Crie `src/01-orm.ts` com lacunas (`TODO`) para:
   - Buscar 1 cliente por `id` com `findUnique`;
   - Listar produtos filtrando por `categoriaId` (após adicionar `model Produto` com lacuna de `@map("categoria_id")` no `schema.prisma` e rodar `npx prisma generate`).
4. Execute `npx tsx src/01-orm.ts`, compare lado a lado o código TS × SQL impresso pelo `log: ["query"]`, e faça 1–2 perguntas estilo banca.

### Etapa 2 — Parte 2: `mysql.general_log` + Provocando o Problema N+1
1. Apresente a analogia rápida do N+1 (1 viagem pela lista + N viagens individuais) e explique por que `mysql.general_log` é a prova real no servidor.
2. Adicione `model Pedido` (e `enum StatusPedido`) no `schema.prisma` com lacunas para `@relation`, `@map("cliente_id")` e `@map("data_pedido")`, e rode `npx prisma generate`.
3. Crie `src/lib/mysql-log.ts` com lacunas (`TODO`) nos comandos `SET GLOBAL log_output = 'TABLE'`, `SET GLOBAL general_log = 'ON'`, `TRUNCATE TABLE mysql.general_log` e `SET GLOBAL general_log = 'OFF'` (no `finally`).
4. Crie `src/02-n1.ts` com lacuna para o usuário **provocar propositalmente o N+1** em um loop (`pedidos` → `findUnique` em `cliente`).
5. Execute, conte as **36 queries** reais no `general_log`, compare TS × SQL e faça perguntas estilo banca.

### Etapa 3 — Parte 3a & 3b: Carregamento Antecipado (`include` vs `relationLoadStrategy: "join"`)
1. Apresente a analogia do pedido consolidado antes do loop.
2. Crie `src/03-eager.ts` com lacunas (`TODO`) para o usuário implementar:
   - Cenário A: `include: { cliente: true }` com `relationLoadStrategy: "query"` → validar **2 queries** (`WHERE id IN (...)`) no `general_log`;
   - Cenário B: `relationLoadStrategy: "join"` → validar **1 query única** no MySQL 8.
3. Compare lado a lado o SQL das duas estratégias e faça perguntas estilo banca sobre quando preferir `IN (...)` vs `join`.

### Etapa 4 — Parte 3c & 3d: `select` Enxuto, Erro Proposital e SQL Manual (`$queryRaw`)
1. Adicione `model ItemPedido` no `schema.prisma` (com lacunas de `@map`/`@relation`) e rode `npx prisma generate`.
2. Crie `src/04-select-e-raw.ts` com lacunas (`TODO`) para:
   - Enxugar colunas com `select` aninhado (`pedidos` → `cliente` + `itens`), testando inclusive o erro proposital de tentar acessar um campo não selecionado no TypeScript (mostrando a proteção de tipagem em tempo de compilação);
   - Escrever uma consulta analítica com `$queryRaw` (ex.: ranking de faturamento com `SUM` + `GROUP BY`, ou clientes sem compras com `LEFT JOIN ... WHERE p.id IS NULL`), comparando TS/Prisma × SQL manual e revisando proteção contra SQL Injection via *tagged template*.

### Etapa 5 — Desafio Final + Simulado de Banca
1. Proponha um último mini desafio sem esqueleto prévio (ex.: consulta de faturamento por categoria ou produtos nunca vendidos) na pasta `pratica/`.
2. Conduza uma rodada curta de perguntas cruzadas estilo banca sobre o código escrito pelo próprio usuário.
