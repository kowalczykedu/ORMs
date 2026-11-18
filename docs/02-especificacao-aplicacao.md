# Especificação da Aplicação — TechStore CLI (TypeScript + Prisma)

Especificação estruturada gerada pelo `/quest2` para orientar a implementação pelo `/task`, conectando a aplicação simples ao banco **TechStore** (`banco/init.sql` / MySQL 8.0 no container `techstore-mysql`).

---

## 1. Visão Geral e Restrições de Arquitetura

- **Local do projeto:** Subpasta `app/` na raiz do repositório (`/home/eduardo/Documentos/ORMs/app`).
- **Preservação da disciplina:** Todos os arquivos originais dentro de `banco/` (`init.sql`, `docker-compose.yaml`, `iniciar.sh`, `reset.sh`, `parar.sh`, etc.) devem permanecer **100% intactos**.
- **Objetivo didático:** Código simples, enxuto, comentado apenas onde agrega clareza e fácil de projetar e explicar pelos 3 integrantes do trio durante a apresentação da AV4.
- **Executor TypeScript:** `tsx` (execução direta dos arquivos `.ts` sem etapa manual de build `tsc`).
- **Interface de execução:** Menu interativo único no terminal via `npm start` (`src/index.ts`), com saída formatada (cores ANSI leves, cabeçalhos, tabelas alinhadas e pausa antes de retornar ao menu).

---

## 2. Estrutura de Pastas e Arquivos Esperada em `app/`

```text
app/
├── prisma/
│   └── schema.prisma         # Mapeamento manual camelCase (@map / @@map) do TechStore
├── src/
│   ├── lib/
│   │   ├── prisma.ts         # Instância do PrismaClient (conexão com TechStore)
│   │   ├── mysql-log.ts      # Automação do general_log (ON, TRUNCATE, leitura, contagem, OFF)
│   │   └── terminal.ts       # Helpers de formatação ANSI, tabelas e prompt/pausa do menu
│   ├── 01-orm-basico.ts      # Parte 1: ORM básico (classe/model = tabela, objeto = linha)
│   ├── 02-problema-n1.ts     # Parte 2: N+1 clássico (pedidos -> clientes)
│   ├── 03-eager-loading.ts   # Parte 3a: include (IN), relationLoadStrategy: "join" e select
│   ├── 04-sql-manual.ts      # Parte 3b: $queryRaw (ranking de gastos + clientes sem pedidos)
│   ├── 05-comparativo.ts     # Comparativo lado a lado: N+1 x include (IN) x join
│   └── index.ts              # Menu interativo CLI principal (npm start)
├── .env.example              # Modelo com DATABASE_URL em modo root
├── package.json              # Dependências (prisma, @prisma/client, tsx, dotenv, etc.)
├── tsconfig.json             # Configuração TypeScript estrita e limpa
├── setup.sh                  # Script portátil de preparação (Lab / Notebook)
└── README.md                 # Guia rápido de setup, apresentação ao vivo e reset (../banco/reset.sh)
```

---

## 3. Configuração do Banco e `schema.prisma`

### 3.1. Conexão (`.env.example` / `.env`)
- Usar usuário **`root`** por padrão para permitir que a própria aplicação ligue, limpe, leia e desligue o `mysql.general_log`:
  ```env
  DATABASE_URL="mysql://root:root@localhost:3306/techstore"
  ```

### 3.2. Estratégia do `prisma/schema.prisma`
- Schema escrito manualmente em **`camelCase`**, utilizando `@map` nas colunas e `@@map` nas tabelas para espelhar fielmente `banco/init.sql` sem alterar o banco:
  - `Categoria` ↔ `categorias`
  - `Cliente` ↔ `clientes` (`dataCadastro` ↔ `data_cadastro`)
  - `Produto` ↔ `produtos` (`categoriaId` ↔ `categoria_id`)
  - `Pedido` ↔ `pedidos` (`clienteId` ↔ `cliente_id`, `dataPedido` ↔ `data_pedido`, enum `StatusPedido`)
  - `ItemPedido` ↔ `itens_pedido` (`pedidoId` ↔ `pedido_id`, `produtoId` ↔ `produto_id`, `precoUnitario` ↔ `preco_unitario`)
- Incluir `previewFeatures = ["relationJoins"]` no `generator client` para suportar `relationLoadStrategy: "join"` no MySQL 8.0.

---

## 4. Especificação Funcional das Demonstrações (Menu Interativo)

### Opção 1 — Parte 1: O que é um ORM (`src/01-orm-basico.ts`)
- **Operação:** Apenas leitura/busca simples tipada (sem criar, editar ou apagar registros, mantendo o banco sempre intacto).
- **Fluxo:**
  1. Busca um cliente específico (ex.: `prisma.cliente.findUnique({ where: { id: 1 } })`) e exibe como um objeto TypeScript representa uma linha da tabela `clientes`.
  2. Lista produtos filtrados (ex.: `prisma.produto.findMany` por categoria ou faixa de preço) e imprime uma amostra formatada no terminal, destacando a relação `model` ↔ tabela e propriedade ↔ coluna.

### Opção 2 — Parte 2: Problema N+1 Clássico (`src/02-problema-n1.ts`)
- **Cenário:** Listagem de `pedidos` buscando o respectivo `cliente` dentro de um loop (`1 + 35 = 36` queries no dataset padrão da TechStore).
- **Prova no MySQL:** Executa sob monitoramento automático do `mysql.general_log`, **imprime todas as queries SQL capturadas no terminal** na ordem em que chegaram ao MySQL e, **ao final da listagem das queries**, exibe o **resumo destacado** com:
  - Total exato de queries executadas no MySQL;
  - Tempo total de execução (ms);
  - Amostra resumida dos resultados retornados (ex.: primeiros registros formatados).

### Opção 3 — Parte 3a: Carregamento Antecipado com `include` padrão (`IN (...)`) (`src/03-eager-loading.ts`)
- **Cenário:** Mesma listagem de `pedidos` + `cliente` (e opção/extensão com `itens`) usando `include` na estratégia padrão (`query` / `WHERE id IN (...)`).
- **Prova no MySQL:** Imprime **todas** as queries capturadas do `mysql.general_log` (evidenciando a cláusula `IN (...)` e a queda de `36` para `2` queries fixas no caso `pedidos` + `clientes`) + **resumo final** (contagem de queries e tempo em ms).

### Opção 4 — Parte 3b: Carregamento Antecipado com `relationLoadStrategy: "join"` (`src/03-eager-loading.ts`)
- **Cenário:** Mesma listagem usando `relationLoadStrategy: "join"` + `include`.
- **Prova no MySQL:** Imprime **todas** as queries capturadas do `mysql.general_log` (mostrando **1 única query** enviada ao MySQL 8 via subquery/agregação JSON) + **resumo final** (contagem de queries e tempo em ms).

### Opção 5 — Parte 3c: Enxugando Colunas com `select` (`src/03-eager-loading.ts`)
- **Cenário:** Listagem integrada de `pedidos`, `clientes` e `itens_pedido` usando `select` aninhado para trazer somente os campos essenciais (`id`, `dataPedido`, `status`, `cliente.nome`, `itens.quantidade`, `itens.precoUnitario`), evitando `SELECT *` disfarçado.
- **Prova no MySQL:** Imprime **todas** as queries capturadas do `mysql.general_log` + **resumo final** (contagem de queries, tempo em ms e preview dos objetos retornados).

### Opção 6 — Parte 3d: Quando usar SQL Manual (`$queryRaw`) (`src/04-sql-manual.ts`)
- **Cenário:** Duas consultas analíticas reais da TechStore em SQL puro seguro (tagged template ``prisma.$queryRaw`...` ``):
  1. **Ranking de faturamento por cliente:** `SUM(ip.quantidade * ip.preco_unitario)` com `INNER JOIN` e `GROUP BY` (excluindo pedidos cancelados);
  2. **Clientes que nunca compraram:** `LEFT JOIN pedidos ... WHERE p.id IS NULL`.
- **Prova no MySQL:** Imprime **todas** as queries capturadas no `mysql.general_log` + **resumo final** (contagem e tempo em ms) + tabelas formatadas com os resultados das duas consultas.

### Opção 7 — Comparativo Lado a Lado (`src/05-comparativo.ts`)
- **Cenário:** Executa automaticamente em sequência as 3 abordagens sobre a mesma consulta (`pedidos` + `cliente`):
  1. Loop sem `include` (**N+1 Clássico**);
  2. `include` padrão (**Estratégia `query` / `IN (...)`**);
  3. `include` + **`relationLoadStrategy: "join"`**.
- **Saída:** Exibe uma **tabela comparativa final** clara no terminal comparando **Abordagem | Queries no MySQL (`general_log`) | Tempo (ms) | Estratégia SQL**. *(Neste modo comparativo, foca na tabela-resumo lado a lado para facilitar a comparação visual na apresentação, enquanto as opções individuais 2 a 6 imprimem todas as queries detalhadas.)*

### Opção 0 — Sair
- Encerra a conexão do `PrismaClient` (`prisma.$disconnect()`) de forma limpa.

---

## 5. Monitoramento Automático do `mysql.general_log` (`src/lib/mysql-log.ts`)

Em cada demonstração monitorada, a aplicação deve executar automaticamente o seguinte ciclo seguro:
1. Configurar saída em tabela e ativar o log:
   - `SET GLOBAL log_output = 'TABLE';`
   - `SET GLOBAL general_log = 'ON';`
2. Limpar logs anteriores antes da medição:
   - `TRUNCATE TABLE mysql.general_log;`
3. Medir o tempo (`performance.now()`) e executar a função Prisma alvo.
4. Desativar imediatamente o log após a execução para não acumular registros no container:
   - `SET GLOBAL general_log = 'OFF';`
5. Consultar `mysql.general_log` filtrando apenas as instruções reais da aplicação (`command_type IN ('Query', 'Execute')` e excluindo os próprios comandos de controle do `general_log`, `SET GLOBAL`, `TRUNCATE`, `SHOW`, etc., para que a contagem reflita exatamente as queries geradas pelo Prisma/SQL da demonstração).
6. Imprimir **todas** as queries capturadas numeradas (`[1] ...`, `[2] ...`, etc.) e, ao final, exibir o bloco de **Resumo** com contagem total de queries e tempo de execução em `ms`.

---

## 6. Portabilidade Notebook / Laboratório (`app/setup.sh` e `app/README.md`)

- **`app/setup.sh`:**
  - Verifica se `node` e `npm` estão disponíveis (exibindo mensagem clara se não estiverem);
  - Verifica se `.env` existe em `app/`; caso não exista, copia automaticamente `.env.example` para `.env`;
  - Verifica se o MySQL de `banco/` está acessível na porta `3306` (orientando rodar `../banco/iniciar.sh` se estiver offline);
  - Executa `npm install` e `npx prisma generate`;
  - Executa uma validação rápida de conexão com o banco `techstore` e informa como rodar `npm start`.
- **`app/README.md`:**
  - Passo a passo direto para rodar no notebook ou no PC do laboratório (`../banco/iniciar.sh` → `./setup.sh` → `npm start`);
  - Roteiro de apresentação mapeando cada opção do menu aos 3 pilares do Tema 6;
  - Instrução explícita de reset seguro do banco usando `../banco/reset.sh`.
