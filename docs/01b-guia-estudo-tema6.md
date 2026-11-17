# Guia Didático Completo — Tema 6: ORM, Problema N+1 e Carregamento Antecipado (TypeScript + Prisma)

> **Material de estudo compartilhável para o trio da AV4** — Disciplina *Banco de Dados Relacional (TSI33D-TSI3)*
> **Banco de referência:** TechStore (`banco/init.sql` — MySQL 8.0)

---

## Mapa Geral do Tema 6 (Como os 3 Pilares se Conectam)

Imagine que sua apresentação tem uma história contínua com começo, meio e fim:

1. **Pilar 1 — O que é um ORM (e como o Prisma funciona):** Por que usamos uma ponte entre objetos TypeScript e tabelas MySQL, o que ganhamos (produtividade e tipagem) e o que perdemos (controle fino do SQL).
2. **Pilar 2 — O Problema N+1:** O erro clássico que acontece quando essa ponte facilita demais o código e faz a aplicação ir ao banco dezenas ou centenas de vezes sem o programador perceber.
3. **Pilar 3 — A Correção (Carregamento Antecipado e SQL Manual):** Como resolver o N+1 no Prisma (`include`, estratégia `IN (...)` vs. `relationLoadStrategy: "join"`), como enxugar dados com `select` e quando abandonar o ORM para escrever SQL direto via `$queryRaw`.

> **Dica de banca:** Os 3 pilares formam uma cadeia lógica. Se o professor perguntar sobre N+1 para quem apresentou ORM, ou perguntar sobre `$queryRaw` para quem apresentou N+1, lembre-se da cadeia: **Abstração do ORM → Esconde as queries geradas → Causa N+1 → Exige Eager Loading ou SQL manual**.

---

## Pilar 1 — O que é um ORM e Como o Prisma Funciona por Dentro

### 1.1. A Analogia da TechStore: O Atendente Bilíngue

Imagine a loja física da **TechStore**.
- No **almoxarifado** (o **MySQL**), tudo é guardado em planilhas rígidas separadas por gavetas: uma gaveta para `clientes`, outra para `pedidos`, outra para `itens_pedido`, outra para `produtos`. O almoxarife só entende uma língua: **SQL**.
- No **balcão de atendimento** (seu código **TypeScript/Node.js**), os vendedores trabalham com **fichas de objeto** na mão: um objeto `Pedido` que já tem dentro dele o nome do cliente e a lista de itens, sem precisar pensar em `JOIN` o tempo todo.

O **ORM (Object-Relational Mapping — Mapeamento Objeto-Relacional)** é o **tradutor automático** entre o balcão (objetos TypeScript) e o almoxarifado (tabelas MySQL).
Em vez de você escrever strings SQL na mão para cada busca simples e depois montar os objetos na marra, você pede em TypeScript (`prisma.pedido.findMany()`) e o ORM traduz para SQL, executa no MySQL e devolve objetos prontos e tipados.

### 1.2. A Tabela de Tradução Fundamental

Sempre que a banca perguntar *"o que um ORM mapeia?"*, tenha esta equivalência na ponta da língua:

| Mundo Orientado a Objetos / TypeScript (Prisma) | Mundo Relacional / SQL (MySQL TechStore) |
| :--- | :--- |
| **`model Pedido`** (definição de entidade) | **Tabela `pedidos`** |
| **Um objeto `pedido`** (instância retornada) | **Uma linha (tupla/registro)** da tabela `pedidos` |
| **Propriedade do objeto** (`pedido.status`) | **Coluna da tabela** (`pedidos.status`) |
| **Relação `@relation(...)`** (`pedido.cliente`) | **Chave Estrangeira (`FOREIGN KEY`)** (`fk_pedidos_cliente`) |

### 1.3. O Ciclo Completo do Prisma (Do Zero até o SQL no MySQL)

Como este é o primeiro contato do trio com o Prisma, entenda exatamente os **4 passos** que acontecem antes e durante a execução do seu código:

#### Passo 1: Definir o mapa no `schema.prisma`
O `schema.prisma` é o arquivo central onde você diz ao Prisma: *"este é o banco MySQL e estas são as tabelas dele"*.
Como o banco da TechStore já existe (`banco/init.sql`) com nomes de tabelas e colunas no plural e em `snake_case` (ex.: `data_pedido`, `itens_pedido`), usamos `@map` (para colunas) e `@@map` (para tabelas):

```prisma
// 1. Quem vai gerar o código TypeScript?
generator client {
  provider = "prisma-client-js"
  // Habilita a estratégia "join" para compararmos no Pilar 3 (Prisma 5.10+ no MySQL)
  previewFeatures = ["relationJoins"]
}

// 2. Onde está o banco MySQL?
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL") // ex: mysql://aluno:aluno123@localhost:3306/techstore
}

// 3. Mapeamento das tabelas reais da TechStore
enum StatusPedido {
  pendente
  pago
  enviado
  entregue
  cancelado
}

model Cliente {
  id           Int      @id @default(autoincrement())
  nome         String   @db.VarChar(100)
  email        String   @unique @db.VarChar(100)
  cidade       String   @db.VarChar(50)
  dataCadastro DateTime @map("data_cadastro") @db.Date
  pedidos      Pedido[]

  @@map("clientes")
}

model Pedido {
  id         Int          @id @default(autoincrement())
  clienteId  Int          @map("cliente_id")
  dataPedido DateTime     @map("data_pedido") @db.Date
  status     StatusPedido @default(pendente)

  cliente    Cliente      @relation(fields: [clienteId], references: [id])
  itens      ItemPedido[]

  @@map("pedidos")
}

model ItemPedido {
  id            Int     @id @default(autoincrement())
  pedidoId      Int     @map("pedido_id")
  produtoId     Int     @map("produto_id")
  quantidade    Int
  precoUnitario Decimal @map("preco_unitario") @db.Decimal(10, 2)

  pedido        Pedido  @relation(fields: [pedidoId], references: [id])
  produto       Produto @relation(fields: [produtoId], references: [id])

  @@map("itens_pedido")
}

model Produto {
  id          Int          @id @default(autoincrement())
  nome        String       @db.VarChar(100)
  preco       Decimal      @db.Decimal(10, 2)
  estoque     Int          @default(0)
  categoriaId Int          @map("categoria_id")

  categoria   Categoria    @relation(fields: [categoriaId], references: [id])
  itens       ItemPedido[]

  @@map("produtos")
}

model Categoria {
  id       Int       @id @default(autoincrement())
  nome     String    @unique @db.VarChar(50)
  produtos Produto[]

  @@map("categorias")
}
```

#### Passo 2: Rodar `npx prisma generate`
Quando você roda `npx prisma generate` no terminal, o Prisma **não altera o banco** — ele lê o `schema.prisma` e **gera código TypeScript customizado** dentro de `node_modules/.prisma/client`.
É por isso que, assim que você digita `prisma.pedido.`, o VS Code já sabe que existem os campos `id`, `clienteId`, `dataPedido`, `status`, `cliente` e `itens`. Se você tentar filtrar por uma coluna que não existe, o TypeScript nem compila!

#### Passo 3: Instanciar o `PrismaClient` e chamar métodos TS
No seu código Node/TypeScript, você cria uma instância do cliente gerado:

```ts
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const pedidos = await prisma.pedido.findMany({
  where: { status: "pago" },
});
```

#### Passo 4: Tradução em Tempo de Execução (Query Engine → MySQL → Objetos)
Por baixo dos panos, o `PrismaClient` envia a instrução para a **Query Engine** do Prisma, que:
1. Traduz `{ where: { status: "pago" } }` para SQL parametrizado (`SELECT ... FROM pedidos WHERE status = ?`);
2. Envia a query pela rede para o MySQL (`localhost:3306`);
3. Recebe as linhas brutas do MySQL e as converte em um array de objetos JavaScript/TypeScript tipados.

### 1.4. Comparação Lado a Lado: SQL Puro × Prisma

**Tarefa:** Listar os pedidos entregues do cliente ID 1 (Ana Silva), ordenados do mais recente para o mais antigo.

| SQL Puro (MySQL) | TypeScript + Prisma |
| :--- | :--- |
| ```sql<br>SELECT id, cliente_id, data_pedido, status<br>FROM pedidos<br>WHERE cliente_id = 1<br>  AND status = 'entregue'<br>ORDER BY data_pedido DESC;<br>``` | ```ts<br>const pedidos = await prisma.pedido.findMany({<br>  where: {<br>    clienteId: 1,<br>    status: "entregue",<br>  },<br>  orderBy: { dataPedido: "desc" },<br>});<br>``` |

### 1.5. Produtividade × Perda de Controle (O Trade-off Clássico)

- **O que você ganha com o ORM (Prisma):**
  - **Produtividade alta:** CRUDs, filtros e mapeamento de objetos prontos em poucas linhas.
  - **Segurança de tipos (Type-safety):** Se uma coluna mudar de nome no banco e no schema, o compilador TypeScript avisa todos os arquivos quebrados antes de ir para produção.
  - **Proteção contra SQL Injection:** Valores passados nos métodos do Prisma são automaticamente parametrizados (prepared statements).
  - **Menos código repetitivo (boilerplate):** Você não precisa ficar escrevendo `SELECT col1, col2...` e fazendo *parse* manual de linhas do driver `mysql2`.
- **O que você perde (e onde moram os perigos):**
  - **Perda de controle fino sobre o SQL gerado:** O desenvolvedor para de enxergar o SQL exato que está batendo no MySQL.
  - **Risco de queries ineficientes:** O ORM pode buscar colunas demais (`SELECT *` disfarçado), fazer múltiplas queries quando uma bastaria, ou gerar subqueries pesadas em relatórios analíticos.
  - **Falsa sensação de simplicidade:** Uma função limpa e bonita em TypeScript pode estar derrubando o banco de dados por trás — e é exatamente aí que nasce o **Problema N+1**.

---

## Pilar 2 — O Problema N+1: O Vilão Silencioso

### 2.1. A Analogia da TechStore: As 35 Viagens ao Almoxarifado

Imagine que o gerente da **TechStore** pede ao estagiário:
*"Me traga uma lista com os **35 pedidos** da loja e diga o **nome do cliente** de cada um."*

Um estagiário distraído faz o seguinte:
1. Vai ao almoxarifado **1 vez** e pega a folha com os **35 pedidos** (que só têm o número `cliente_id`, e não o nome).
2. Olha o Pedido 1 (`cliente_id = 1`), caminha até o arquivo de clientes, pergunta *"quem é o cliente 1?"* e volta.
3. Olha o Pedido 2 (`cliente_id = 2`), caminha **de novo** até o arquivo de clientes, pergunta *"quem é o cliente 2?"* e volta.
4. ... Repete isso **35 vezes**, uma viagem para cada pedido!

No final, para montar **1 única lista**, o estagiário fez **1 + 35 = 36 viagens** ao almoxarifado!
E pior: a cliente Ana Silva (`cliente_id = 1`) tem vários pedidos (pedidos 1, 5, 18, 27), e o estagiário foi perguntar quem é a Ana Silva **4 vezes seguidas**!

Isso é o **Problema N+1**:
- **1 query** para buscar a lista principal (que retorna **N** registros);
- **+ N queries** disparadas dentro de um loop (ou `Promise.all`) para buscar os dados relacionados de cada um desses **N** registros.

### 2.2. Caso Clássico na TechStore (2 Níveis: `pedidos` → `clientes`)

Veja como é assustadoramente fácil escrever um código TypeScript que parece inofensivo, mas gera **36 queries** no banco da TechStore (`35` pedidos no `init.sql`):

```ts
// ❌ CÓDIGO COM PROBLEMA N+1 (2 níveis: pedidos -> cliente)
async function listarPedidosComClienteRuim() {
  // Query 1: busca todos os 35 pedidos
  const pedidos = await prisma.pedido.findMany();

  const resultado = [];
  for (const pedido of pedidos) {
    // Dispara +1 query PARA CADA pedido dentro do loop! (35 queries extras)
    const cliente = await prisma.cliente.findUnique({
      where: { id: pedido.clienteId },
    });

    resultado.push({
      pedidoId: pedido.id,
      data: pedido.dataPedido,
      status: pedido.status,
      clienteNome: cliente?.nome,
    });
  }

  return resultado;
}
```

> **Atenção para pegadinha de banca:** *"E se eu trocar o `for` por `Promise.all(pedidos.map(...))`?"*
> **Continua sendo N+1!** O `Promise.all` apenas dispara as **N queries em paralelo** ao mesmo tempo em vez de uma após a outra. A quantidade de queries no MySQL continua sendo `1 + N = 36` — e pior, pode esgotar o pool de conexões do banco de uma só vez!

### 2.3. Caso em Cascata na TechStore (3 Níveis: `pedidos` → `itens_pedido` → `produtos`)

Agora imagine o cenário real de listagem completa da loja: para cada pedido, queremos o cliente, os itens do pedido e o nome de cada produto comprado.

```ts
// ❌ N+1 EM CASCATA (Explosão multiplicativa!)
async function listarPedidosCompletosRuim() {
  // 1 query -> retorna 35 pedidos
  const pedidos = await prisma.pedido.findMany();

  for (const pedido of pedidos) {
    // +35 queries -> busca o cliente de cada pedido
    const cliente = await prisma.cliente.findUnique({
      where: { id: pedido.clienteId },
    });

    // +35 queries -> busca os itens de cada pedido
    const itens = await prisma.itemPedido.findMany({
      where: { pedidoId: pedido.id },
    });

    for (const item of itens) {
      // +80+ queries -> para cada item dos 35 pedidos, busca o produto!
      const produto = await prisma.produto.findUnique({
        where: { id: item.produtoId },
      });
    }
  }
}
```

**Faça a conta no dataset real da TechStore (`banco/init.sql`):**
- `1` query de `pedidos`
- `+ 35` queries de `clientes`
- `+ 35` queries de `itens_pedido`
- `+ 80+` queries de `produtos`
- **Total: mais de 150 queries no MySQL para carregar UMA única listagem de 35 pedidos!**

Se a loja crescer de `35` para `10.000` pedidos, essa tela passa de **~150 queries** para **dezenas de milhares de queries** — cada uma pagando o preço de ida e volta na rede (round-trip), parsing SQL, plano de execução e disputa de conexão. A aplicação congela.

### 2.4. Diagrama de Sequência: A Tragédia do N+1

```mermaid
sequenceDiagram
    autonumber
    participant App as App TypeScript (Prisma)
    participant DB as MySQL 8 (techstore)

    App->>DB: SELECT * FROM pedidos (1ª query)
    DB-->>App: Retorna 35 pedidos (N = 35)

    loop Para cada um dos 35 pedidos
        App->>DB: SELECT * FROM clientes WHERE id = ?
        DB-->>App: Retorna 1 cliente
        App->>DB: SELECT * FROM itens_pedido WHERE pedido_id = ?
        DB-->>App: Retorna itens do pedido
    end

    Note over App,DB: Total: 1 + 35 + 35 = 71 queries (e 150+ se buscar produtos!)
```

### 2.5. Como Provar que o N+1 Está Acontecendo (Logs do Prisma + `general_log` do MySQL)

Na apresentação da AV4, nada convence mais a banca do que **mostrar a prova no log**. Você tem duas formas complementares:

#### Forma A — No próprio TypeScript (Log do Prisma)
Ao instanciar o `PrismaClient`, habilite o log de queries:

```ts
const prisma = new PrismaClient({
  log: ["query"],
});
```

Ao rodar a função com N+1, o terminal é inundado por linhas repetidas:
```text
prisma:query SELECT `pedidos`.`id`, `pedidos`.`cliente_id`, ... FROM `pedidos`
prisma:query SELECT `clientes`.`id`, `clientes`.`nome`, ... FROM `clientes` WHERE `clientes`.`id` = ? LIMIT ?
prisma:query SELECT `clientes`.`id`, `clientes`.`nome`, ... FROM `clientes` WHERE `clientes`.`id` = ? LIMIT ?
... (repete 35 vezes!)
```

#### Forma B — Direto no MySQL 8 (`general_log` no container `techstore-mysql`)
O `general_log` registra **absolutamente toda instrução SQL** que chega ao servidor MySQL, provando que o problema não é impressão do Node.js, e sim tráfego real no banco.

1. Conecte no MySQL (via phpMyAdmin em `http://localhost:8080` ou terminal no container `techstore-mysql` como `root`/`root`):
```sql
-- Grava o log na tabela mysql.general_log (muito prático para filtrar via SQL!)
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

-- Limpa registros antigos antes do teste
TRUNCATE TABLE mysql.general_log;
```
2. Execute a sua função TypeScript com N+1.
3. Consulte o que o MySQL recebeu:
```sql
SELECT event_time, command_type, argument
FROM mysql.general_log
WHERE command_type IN ('Query', 'Execute')
  AND argument NOT LIKE '%mysql.general_log%'
ORDER BY event_time DESC;
```
4. **Importante:** Desligue após o teste para não consumir disco/CPU à toa:
```sql
SET GLOBAL general_log = 'OFF';
```

---

## Pilar 3 — A Correção: Carregamento Antecipado (`include`), Estratégias Internas e `$queryRaw`

### 3.1. A Analogia da TechStore: A Requisição em Lote

Em vez de o atendente ir ao almoxarifado 35 vezes perguntar um cliente por vez, ele:
1. Pega os **35 pedidos**;
2. Anota todos os IDs de clientes envolvidos (`1, 2, 3, 4...` — **sem repetir os duplicados!**);
3. Faz **uma única viagem** dizendo: *"Me dê os dados de todos os clientes cujos IDs estão nesta lista `IN (1, 2, 3, ...)`"*;
4. Ou então já pede para o próprio almoxarife entregar tudo montado de uma só vez.

Em engenharia de software, isso se chama **Eager Loading (Carregamento Antecipado)**: você avisa ao ORM **com antecedência** que vai precisar das relações junto com a consulta principal.

### 3.2. Como Corrigir no Prisma usando `include`

Em vez de fazer `findUnique` dentro de um `for`, declaramos o que queremos carregar na própria chamada do `findMany`:

```ts
// ✅ SEM N+1: Carregamento Antecipado (Eager Loading) com include
async function listarPedidosCompletosCorreto() {
  const pedidos = await prisma.pedido.findMany({
    include: {
      cliente: true,
      itens: {
        include: {
          produto: true,
        },
      },
    },
    orderBy: { id: "asc" },
  });

  return pedidos;
}
```

Olhe o que muda:
- O código fica **menor e mais limpo** (sem loops assíncronos fazendo queries);
- Cada `pedido` já vem com `pedido.cliente.nome` e `pedido.itens[i].produto.nome` tipados;
- A quantidade de queries deixa de crescer com `N`!

### 3.3. Por Baixo dos Panos no MySQL 8: Estratégia `query` (`IN (...)`) vs. `relationLoadStrategy: "join"`

Este é o **ponto de ouro** que diferencia um grupo que apenas decorou `include` de um grupo que domina o Prisma por dentro.

O Prisma oferece duas estratégias internas configuráveis pela propriedade `relationLoadStrategy`:

#### Estratégia 1 — `relationLoadStrategy: "query"` (Padrão do Prisma com `WHERE id IN (...)`)
Se você não especificar nada (ou passar `relationLoadStrategy: "query"`), o Prisma **não gera um `JOIN` SQL**. Ele executa **1 query por tabela envolvida**, em lote, usando `IN (...)`, e junta os objetos na memória do Prisma:

```sql
-- Query 1: busca os pedidos
SELECT id, cliente_id, data_pedido, status FROM pedidos ORDER BY id ASC;

-- Query 2: extrai os cliente_id únicos e busca todos de uma vez
SELECT id, nome, email, cidade, data_cadastro FROM clientes WHERE id IN (1, 2, 3, ..., 20);

-- Query 3: busca todos os itens desses pedidos de uma vez
SELECT id, pedido_id, produto_id, quantidade, preco_unitario FROM itens_pedido WHERE pedido_id IN (1, 2, ..., 35);

-- Query 4: extrai os produto_id únicos dos itens e busca de uma vez
SELECT id, nome, preco, estoque, categoria_id FROM produtos WHERE id IN (1, 2, ..., 30);
```

- **Total de queries:** **4 queries fixas** (`1` de pedidos + `1` de clientes + `1` de itens + `1` de produtos). Se houver `35` pedidos ou `5.000` pedidos, continuam sendo **4 queries** (e não `150+` ou `30.000+`!).
- **Por que o Prisma faz isso por padrão?**
  Porque um `JOIN` SQL tradicional (`pedidos JOIN itens_pedido JOIN clientes`) **repete os dados do pedido e do cliente em toda linha de item**. Se um pedido tem 4 itens, o nome e email do cliente trafegam 4 vezes pela rede. Com `IN (...)`, cada cliente e cada produto trafega **no máximo 1 vez**!

#### Estratégia 2 — `relationLoadStrategy: "join"` (Query Única no MySQL 8)
Com `previewFeatures = ["relationJoins"]` ativo no `schema.prisma`, você pode forçar o Prisma a delegar a junção para o próprio MySQL em **1 única query**:

```ts
const pedidos = await prisma.pedido.findMany({
  relationLoadStrategy: "join", // <-- Muda a estratégia interna!
  include: {
    cliente: true,
    itens: {
      include: {
        produto: true,
      },
    },
  },
});
```

**Detalhe técnico importante sobre o MySQL 8:**
Diferente do PostgreSQL (onde o Prisma usa `LATERAL JOIN`), no **MySQL 8.0** o Prisma implementa `relationLoadStrategy: "join"` gerando **1 única query SQL** com **subqueries correlacionadas + agregação JSON** (`JSON_ARRAYAGG` / `JSON_OBJECT`). Conceitualmente, o que chega ao MySQL parece com isto:

```sql
SELECT
  p.id,
  p.data_pedido,
  p.status,
  (SELECT JSON_OBJECT('id', c.id, 'nome', c.nome, 'cidade', c.cidade)
   FROM clientes c WHERE c.id = p.cliente_id) AS cliente,
  (SELECT JSON_ARRAYAGG(
     JSON_OBJECT('id', ip.id, 'quantidade', ip.quantidade, 'preco_unitario', ip.preco_unitario)
   )
   FROM itens_pedido ip WHERE ip.pedido_id = p.id) AS itens
FROM pedidos p;
```

### 3.4. Diagrama Comparativo: N+1 × `IN (...)` × `join`

```mermaid
sequenceDiagram
    autonumber
    participant App as App TypeScript
    participant DB as MySQL 8 (techstore)

    rect rgb(70, 20, 20)
        Note over App,DB: CENÁRIO 1: N+1 (35 pedidos -> 71 a 150+ queries)
        App->>DB: SELECT * FROM pedidos
        DB-->>App: 35 pedidos
        loop N = 35 vezes
            App->>DB: SELECT * FROM clientes WHERE id = ?
            App->>DB: SELECT * FROM itens_pedido WHERE pedido_id = ?
        end
    end

    rect rgb(20, 55, 75)
        Note over App,DB: CENÁRIO 2: include padrão (query / IN) -> 3 ou 4 queries fixas
        App->>DB: SELECT * FROM pedidos
        DB-->>App: 35 pedidos
        App->>DB: SELECT * FROM clientes WHERE id IN (...)
        DB-->>App: clientes únicos
        App->>DB: SELECT * FROM itens_pedido WHERE pedido_id IN (...)
        DB-->>App: todos os itens
    end

    rect rgb(20, 70, 35)
        Note over App,DB: CENÁRIO 3: relationLoadStrategy: "join" -> 1 única query
        App->>DB: SELECT p.*, (subquery JSON cliente), (subquery JSON itens) FROM pedidos p
        DB-->>App: Tudo montado em 1 único round-trip
    end
```

### 3.5. Quadro Comparativo Completo (TechStore: `pedidos` + `clientes` + `itens_pedido` + `produtos`)

| Abordagem | Qtde de Queries | Onde ocorre a junção | Duplicação de dados na rede | Melhor uso |
| :--- | :--- | :--- | :--- | :--- |
| **Loop sem `include` (N+1)** | `1 + 35 + 35 + 80+` (**~150+**) | Na aplicação (lentamente) | Baixa por query, mas latência absurda | **Nunca usar!** |
| **`include` padrão (`query` / `IN`)** | **4 queries fixas** (`O(níveis)`) | Na memória do Prisma | Zero duplicação de pais/produtos | Padrão seguro para listagens gerais e múltiplos níveis |
| **`include` + `relationLoadStrategy: "join"`** | **1 query fixa** (`O(1)`) | Dentro do MySQL 8 (subquery + JSON) | Baixa (agregado em JSON) | Reduzir latência de rede quando há muitos níveis ou filtros relacionais |
| **SQL Puro com `LEFT JOIN`** | **1 query fixa** (`O(1)`) | Dentro do MySQL 8 (B-Tree / Hash Join) | **Alta** (colunas do pedido/cliente repetem a cada item) | Relatórios, agregações e casos em que precisa de plano SQL exato |

### 3.6. Enxugando o Payload com `select` (Não Basta Evitar N+1!)

Mesmo corrigindo o N+1, `include: { cliente: true }` traz **todas as colunas** (`email`, `data_cadastro`, etc.). Em tabelas grandes, trazer colunas inúteis gasta memória e rede à toa.
Com `select`, você pede **só o necessário** (em SQL equivalente a trocar `SELECT *` por colunas específicas):

```ts
const pedidosEnxutos = await prisma.pedido.findMany({
  select: {
    id: true,
    dataPedido: true,
    status: true,
    cliente: {
      select: {
        nome: true,
        cidade: true,
      },
    },
    itens: {
      select: {
        quantidade: true,
        precoUnitario: true,
        produto: {
          select: {
            nome: true,
          },
        },
      },
    },
  },
});
```

> **Regra de sintaxe do Prisma:** No mesmo nível de um objeto de consulta, você usa **`include` OU `select`**, nunca os dois juntos no mesmo bloco (mas dentro de um `select`, você pode selecionar relações aninhadas normalmente, como mostrado acima!).

### 3.7. Quando Abandonar o ORM e Escrever SQL Manual (`$queryRaw`)

O Prisma brilha em CRUDs e listagens de entidades (`findMany`, `create`, `update`), mas **não substitui o SQL em consultas analíticas complexas**. Veja dois exemplos reais na TechStore onde o SQL manual via `$queryRaw` vence de lavada:

#### Caso A: Ranking de faturamento por cliente (`SUM`, `GROUP BY`, `INNER JOIN`)
No Prisma padrão (`groupBy`), você não consegue facilmente somar `quantidade * preco_unitario` cruzando `itens_pedido` + `pedidos` + `clientes` numa única tacada limpa. Em SQL é direto ao ponto:

```ts
// SQL Puro executado de forma segura via Tagged Template ($queryRaw)
// (Protegido contra SQL Injection porque parâmetros ${...} viram bind parameters)
const ranking = await prisma.$queryRaw<
  Array<{ cliente: string; totalPedidos: number; totalGasto: number }>
>`
  SELECT
    c.nome AS cliente,
    COUNT(DISTINCT p.id) AS totalPedidos,
    SUM(ip.quantidade * ip.preco_unitario) AS totalGasto
  FROM clientes c
  INNER JOIN pedidos p ON p.cliente_id = c.id
  INNER JOIN itens_pedido ip ON ip.pedido_id = p.id
  WHERE p.status <> 'cancelado'
  GROUP BY c.id, c.nome
  ORDER BY totalGasto DESC
`;
```

#### Caso B: Clientes que NUNCA compraram (`LEFT JOIN ... WHERE p.id IS NULL`)
No `init.sql` da TechStore, clientes como `Wagner`, `Xênia`, `Yuri`, `Zuleica` e `Marcelo Augusto` (IDs 21 a 25) nunca fizeram pedidos. No Prisma até dá para fazer `where: { pedidos: { none: {} } }` (que gera `NOT EXISTS`), mas quando você precisa cruzar múltiplas condições de negócio com performance previsível, o `$queryRaw` com `LEFT JOIN` dá controle total do índice e do `EXPLAIN`:

```ts
const inativos = await prisma.$queryRaw<
  Array<{ id: number; nome: string; email: string }>
>`
  SELECT c.id, c.nome, c.email
  FROM clientes c
  LEFT JOIN pedidos p ON p.cliente_id = c.id
  WHERE p.id IS NULL
`;
```

#### Checklist: Quando sair do ORM padrão para `$queryRaw`?
1. Precisa multiplicar ou somar colunas entre tabelas (`SUM(quantidade * preco_unitario)`).
2. Precisa de `GROUP BY` com `HAVING`, `CASE WHEN`, Window Functions (`ROW_NUMBER()`, `RANK()`) ou CTEs (`WITH ...`).
3. O SQL gerado pelo ORM ficou lento no `EXPLAIN` e você precisa reescrever o `JOIN` ou forçar uma ordem/índice específico.
4. **Cuidado de segurança:** Sempre use **`prisma.$queryRaw\`...\``** (crases / tagged template), nunca `$queryRawUnsafe("..." + variavel)`, para evitar **SQL Injection**.

---

## Cola Rápida de Banca (Revisão em 1 Minuto)

- **ORM em 1 frase:** Camada tradutora entre objetos TypeScript e tabelas relacionais (`model` = tabela, objeto = linha, propriedade = coluna, `@relation` = FK).
- **Ciclo do Prisma:** `schema.prisma` (define modelos + `@map`/`@@map`) → `npx prisma generate` (gera `PrismaClient` tipado) → execução traduz TS para SQL parametrizado.
- **Ganho vs. Perda:** Ganha produtividade, type-safety e proteção contra SQL Injection; perde visibilidade e controle fino do SQL gerado.
- **O que é N+1:** `1` query busca `N` registros pais + `N` queries em loop (mesmo com `Promise.all`!) buscam as relações uma a uma. Na TechStore (`35` pedidos): `1 + 35 = 36` queries (ou `150+` em cascata com `itens_pedido` e `produtos`).
- **Como provar:** `log: ['query']` no `PrismaClient` + `SET GLOBAL general_log = 'ON'` no MySQL 8.
- **Como corrigir:** Eager loading com `include` (ou `select` para filtrar colunas).
- **`query` (`IN (...)`) vs. `join` no Prisma (MySQL 8):**
  - Padrão (`query`): **1 query por nível** usando `WHERE id IN (...)`; evita duplicar linhas do pai na rede.
  - `relationLoadStrategy: "join"`: **1 query única** (no MySQL 8 usa subqueries correlacionadas com `JSON_ARRAYAGG`/`JSON_OBJECT`).
- **Quando usar `$queryRaw`:** Agregações entre colunas (`SUM(qtd * preco)`), `GROUP BY` complexo, Window Functions ou quando o `EXPLAIN` mostrar que o SQL do ORM é subótimo.

---

> **Próximos passos nesta conversa:**
> 1. **Tira-Dúvidas Livre:** Pergunte qualquer ponto da apostila acima que ainda não esteja 100% cristalino para qualquer um dos 3 integrantes.
> 2. **Simulado da Banca (Formato Misto):** Assim que quiserem, partimos para o simulado com perguntas orais cruzadas estilo AV4 + análise de código TypeScript/Prisma e trechos do `general_log` do MySQL!
