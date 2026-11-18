# Roteiro Visual dos Slides — AV4 (Tema 6: ORM, Problema N+1 e Carregamento Antecipado)

Documento consolidado a partir do questionário `/slides` para orientar a criação da apresentação no **Canva ou Google Slides**, mantendo **pouco texto por slide**, alto contraste para projetor e integração fluida com a **Demo ao Vivo** (`app/` conectado ao banco `techstore`).

---

## 1. Diretrizes Visuais e Decisões do Trio

- **Ferramenta de montagem:** Canva ou Google Slides (edição colaborativa em trio; blocos de código gerados no [Ray.so](https://ray.so) ou [Carbon](https://carbon.now.sh) em tema claro).
- **Estilo visual:** **Tema Claro Minimalista** (ideal para projetores em sala iluminada).
  - **Fundo principal:** Branco (`#FFFFFF`) ou Cinza Gelo (`#F8FAFC`).
  - **Texto principal:** Grafite escuro (`#0F172A`) e secundário (`#475569`).
  - **Cores semânticas (consistentes do início ao fim):**
    - **Azul/Ciano (`#0284C7`):** Prisma / TypeScript / Estrutura ORM.
    - **Vermelho (`#DC2626`):** Problema N+1 / Alertas de latência (`36 queries`).
    - **Verde (`#16A34A`):** Carregamento Antecipado / Eager Loading (`2` ou `1` query).
    - **Âmbar/Laranja (`#D97706`):** SQL Manual (`$queryRaw`) / Trade-offs.
- **Quantidade e ritmo:** **12 slides** para **~15 minutos** (~11 min nos slides + ~4 min distribuídos em **3 micro-demos intercaladas**).
- **Ordem dos blocos:** Ordem tradicional direta (**Pilar 1: O que é um ORM** → **Pilar 2: Problema N+1** → **Pilar 3: Carregamento Antecipado & SQL Manual**).
- **Nível de código:** Comparativo **lado a lado ultra curto** (3 a 6 linhas de TypeScript/Prisma à esquerda + SQL equivalente à direita).
- **Diagramas e `general_log`:**
  - Diagramas de **setas `App <-> MySQL`** (`1 + 35` setas vermelhas vs. `2` setas `IN (...)` vs. `1` seta `JOIN`).
  - **Sem trechos de log colados nos slides:** usar apenas o badge **"Demo ao Vivo"** + cartões numéricos grandes (`36` vs. `2` vs. `1` query), deixando a prova real do `mysql.general_log` acontecer ao vivo no terminal.
- **3 Analogias do Cotidiano escolhidas:**
  1. **ORM:** *Tradutor simultâneo / Adaptador de tomada* (TypeScript ↔ SQL/MySQL).
  2. **Problema N+1:** *Almoxarifado / Mercado* (pegar a lista de 35 pedidos e fazer 35 viagens individuais buscando 1 cliente por vez).
  3. **Eager Loading vs. SQL Manual:** *Pedido consolidado em lista única no carrinho* (`include` / `join`) + *Acesso direto ao cofre / relatório gerencial* (`$queryRaw`).

---

## 2. Visão Geral: Cronograma Slides + Micro-Demos (~15 min)

| Bloco | Slides | Demo ao Vivo (Terminal `npm start`) | Tempo |
| :--- | :--- | :--- | :---: |
| **Abertura** | Slides 1 e 2 | — | 1m 15s |
| **Pilar 1 — O que é um ORM** | Slides 3, 4 e 5 | **Micro-Demo 1:** Opção `1` (`01-orm-basico.ts`) após Slide 4 | 3m 15s |
| **Pilar 2 — Problema N+1** | Slides 6 e 7 | **Micro-Demo 2:** Opção `2` (`02-problema-n1.ts`) no Slide 7 | 3m 15s |
| **Pilar 3 — Eager Loading & SQL** | Slides 8, 9 e 10 | **Micro-Demo 3:** Opções `3`, `4`, `6` e `7` nos Slides 8 e 10 | 5m 30s |
| **Fechamento** | Slides 11 e 12 | — | 1m 45s |
| **Total** | **12 slides** | **3 micro-demos** | **15m 00s** |

---

## 3. Roteiro Detalhado Slide a Slide

### Slide 1 — Capa
- **Tempo estimado:** `0:30`
- **Layout sugerido:** Fundo branco limpo, barra lateral fina azul-ciano, tipografia grande centralizada à esquerda e mini-diagrama discreto `TS + Prisma ↔ MySQL` à direita.
- **Conteúdo exato na tela:**
  - **Tag superior:** `TSI33D-TSI3 • Banco de Dados Relacional • AV4 — Tema 6`
  - **Título:** `ORM, Problema N+1 e Carregamento Antecipado`
  - **Subtítulo:** `Na prática com TypeScript, Prisma e MySQL (TechStore)`
  - **Rodapé:** Nomes dos 3 integrantes do trio

---

### Slide 2 — Roteiro e Cenário TechStore
- **Tempo estimado:** `0:45`
- **Objetivo visual:** Situar a banca nos 3 pilares e mostrar o domínio do banco antes de entrar no código.
- **Layout sugerido:** 3 cartões numerados no topo + faixa inferior com as tabelas principais do `techstore`.
- **Conteúdo exato na tela:**
  - **Título:** `O que vamos demonstrar hoje`
  - **3 Blocos (Cartões):**
    1. `1. ORM & Prisma` — Como objetos TypeScript viram queries SQL.
    2. `2. Problema N+1` — O gargalo oculto das queries em loop.
    3. `3. Eager Loading & SQL` — Como corrigir (`IN`, `JOIN`) e quando usar `$queryRaw`.
  - **Diagrama inferior (Mini-ER simplificado):**
    `[clientes] 1 ──▶ N [pedidos] 1 ──▶ N [itens_pedido] N ◀── 1 [produtos]`
  - **Destaque numérico:** `Base TechStore: 35 pedidos reais no MySQL 8`

---

### Slide 3 — Pilar 1: O que é um ORM? (Analogia + Mapeamento)
- **Tempo estimado:** `1:00`
- **Objetivo visual:** Explicar ORM de forma intuitiva em 15 segundos com a analogia do tradutor/adaptador e conectar com a estrutura do `schema.prisma`.
- **Layout sugerido:** Esquerda = ícone/analogia visual; Direita = tabela de equivalência 2 colunas.
- **Conteúdo exato na tela:**
  - **Título:** `ORM: A ponte entre Objetos e Tabelas`
  - **Card de Analogia (Esquerda):**
    - Ícone de **Adaptador de Tomada / Tradutor Simultâneo**
    - `App TypeScript (Objetos)` ⇄ **ORM (Prisma)** ⇄ `MySQL (Tabelas & SQL)`
    - *“Você escreve em objetos; o ORM traduz para SQL.”*
  - **Tabela de Equivalência (Direita):**
    | No Código (Prisma / TS) | No Banco (MySQL) |
    | :--- | :--- |
    | `model Cliente` | Tabela `clientes` (`@@map`) |
    | Objeto `cliente` | 1 Linha (registro) |
    | `dataCadastro` | Coluna `data_cadastro` (`@map`) |
    | `@relation` | Chave Estrangeira (`FK`) |

---

### Slide 4 — Pilar 1: Prisma na Prática + Micro-Demo 1
- **Tempo estimado:** `1:30` *(~45s explicação + ~45s demo no terminal)*
- **Objetivo visual:** Mostrar o primeiro comparativo curto `TypeScript × SQL` e rodar a Opção 1 no terminal.
- **Layout sugerido:** Duas caixas de código lado a lado + faixa de chamada da demo no rodapé.
- **Conteúdo exato na tela:**
  - **Título:** `Do TypeScript para o SQL em 3 linhas`
  - **Esquerda — Prisma (TypeScript):**
    ```ts
    const cliente = await prisma.cliente.findUnique({
      where: { id: 1 },
    });
    ```
  - **Direita — SQL Equivalente (MySQL):**
    ```sql
    SELECT id, nome, email, cidade, data_cadastro
    FROM clientes
    WHERE id = 1 LIMIT 1;
    ```
  - **Badge no rodapé (Azul):** `▶ DEMO AO VIVO — TechStore CLI: Opção 1 (01-orm-basico.ts)`
- **Na Demo (Terminal):** Executar a **Opção 1**, apontar o objeto tipado impresso para `cliente` (`id: 1`) e a tabela de produtos da categoria 1.

---

### Slide 5 — Pilar 1: Trade-offs do ORM
- **Tempo estimado:** `0:45`
- **Objetivo visual:** Responder antecipadamente à pergunta clássica de banca sobre prós e contras antes de abrir o Pilar 2.
- **Layout sugerido:** Duas colunas contrastantes (Verde = Ganhos | Âmbar/Vermelho = Riscos).
- **Conteúdo exato na tela:**
  - **Título:** `ORM não é mágica: Ganhos × Riscos`
  - **Coluna 1 (Verde — Por que usar):**
    - Tipagem forte e autocompletar no TypeScript
    - Produtividade no CRUD do dia a dia
    - Proteção padrão contra SQL Injection
  - **Coluna 2 (Âmbar — O que exige atenção):**
    - Distanciamento do SQL realmente executado
    - Risco de consultas ineficientes escondidas no código
    - **Gancho:** *“E o caso mais famoso é o Problema N+1...”*

---

### Slide 6 — Pilar 2: O Problema N+1 (Analogia + Fluxo de Setas)
- **Tempo estimado:** `1:15`
- **Objetivo visual:** Tornar visível o desperdício de round-trips com a analogia do almoxarifado e o diagrama de setas.
- **Layout sugerido:** Topo = Analogia curta; Centro = Diagrama de setas `App <-> MySQL`; Direita = Cartão vermelho gigante `36`.
- **Conteúdo exato na tela:**
  - **Título:** `O Problema N+1: 1 + 35 viagens ao banco`
  - **Analogia (Faixa superior):**
    - Ícone de **Lista / Carrinho no Almoxarifado**
    - *“Pegar a lista com 35 pedidos e fazer **35 viagens individuais** para buscar 1 cliente por vez.”*
  - **Diagrama de Setas (Centro):**
    ```text
    [ App Node.js ] ── (1) SELECT * FROM pedidos ──────────▶ [ MySQL ]
                    ── (2) SELECT * FROM clientes WHERE id=1 ▶
                    ── (3) SELECT * FROM clientes WHERE id=2 ▶
                    ... (+ 33 idas e vindas dentro do loop)
    ```
    *(No Canva/Slides: desenhar `1 seta azul` no topo + um feixe de `setas vermelhas` abaixo indicando `N = 35`)*
  - **Cartão de Impacto (Vermelho):**
    - **`1 + 35 = 36 queries`**
    - *Custo real:* latência de rede + sobrecarga de conexões.

---

### Slide 7 — Pilar 2: N+1 no Código + Micro-Demo 2
- **Tempo estimado:** `2:00` *(~45s slide + ~1m 15s demo)*
- **Objetivo visual:** Mostrar que o código parece inocente no TypeScript, e comprovar ao vivo no `mysql.general_log`.
- **Layout sugerido:** Esquerda = código TS com destaque vermelho no `await` dentro do `for`; Direita = SQL repetido + Badge da Demo.
- **Conteúdo exato na tela:**
  - **Título:** `Código “inocente”, explosão no MySQL`
  - **Esquerda — TypeScript (Prisma em loop):**
    ```ts
    const pedidos = await prisma.pedido.findMany(); // 1 query

    for (const p of pedidos) {
      const cli = await prisma.cliente.findUnique({ // +N queries!
        where: { id: p.clienteId },
      });
    }
    ```
  - **Direita — O que chega no MySQL:**
    ```sql
    -- [1] SELECT ... FROM pedidos
    -- [2] SELECT ... FROM clientes WHERE id = ?
    -- [3] SELECT ... FROM clientes WHERE id = ?
    -- ... repetido 35 vezes!
    ```
  - **Cartão-resumo:** `N = 35 pedidos` → **`36 queries`** no `general_log`
  - **Badge no rodapé (Vermelho):** `▶ DEMO AO VIVO — Opção 2 (02-problema-n1.ts + general_log)`
- **Na Demo (Terminal):** Executar a **Opção 2** e mostrar as **36 queries numeradas** capturadas em tempo real no `mysql.general_log`.

---

### Slide 8 — Pilar 3: Carregamento Antecipado (`include` vs. `join`) + Micro-Demo 3a
- **Tempo estimado:** `2:30` *(~1m 15s slide + ~1m 15s demo)*
- **Objetivo visual:** Comparar visualmente as duas estratégias do Prisma (`query` com `IN` vs. `join`) usando o diagrama de setas e a analogia do pedido consolidado.
- **Layout sugerido:** 2 cards horizontais ou 2 colunas verdes comparando `include` padrão (`2 queries`) × `relationLoadStrategy: "join"` (`1 query`).
- **Conteúdo exato na tela:**
  - **Título:** `Carregamento Antecipado (Eager Loading)`
  - **Analogia (Subtítulo):** *“Pedido consolidado em lista única — buscar tudo de uma vez antes do loop.”*
  - **Coluna 1 (Verde Claro) — Estratégia Padrão (`query` / `IN`):**
    - **Diagrama de setas:** `App ── 2 setas verdes ──▶ MySQL`
    - **Código (4 linhas):**
      ```ts
      prisma.pedido.findMany({
        include: { cliente: true }
      });
      ```
    - **SQL gerado (resumo):**
      1. `SELECT ... FROM pedidos`
      2. `SELECT ... FROM clientes WHERE id IN (1,2,3...)`
    - **Métrica:** **`2 queries`** *(sem repetição de dados do pai)*
  - **Coluna 2 (Verde Escuro) — `relationLoadStrategy: "join"`:**
    - **Diagrama de setas:** `App ── 1 seta verde ──▶ MySQL`
    - **Código (4 linhas):**
      ```ts
      prisma.pedido.findMany({
        relationLoadStrategy: "join",
        include: { cliente: true }
      });
      ```
    - **SQL gerado (resumo):**
      1. `SELECT ... LEFT JOIN / JSON lateral ...` (MySQL 8)
    - **Métrica:** **`1 query`** *(menor round-trip de rede)*
  - **Badge no rodapé (Verde):** `▶ DEMO AO VIVO — Opções 3 e 4 (2 queries vs. 1 query no general_log)`
- **Na Demo (Terminal):** Rodar **Opção 3** (mostrar o `WHERE id IN (...)` em 2 queries) e **Opção 4** (mostrar a query única de `relationLoadStrategy: "join"`).

---

### Slide 9 — Pilar 3: Enxugando Colunas com `select` (e Risco de Cascata)
- **Tempo estimado:** `0:45`
- **Objetivo visual:** Mostrar rapidamente a boa prática de não trafegar colunas inúteis (`select` vs. `include`) e lembrar da cascata `pedidos → itens → produtos`.
- **Layout sugerido:** Código curto `select` à esquerda + 2 bullets visuais de boas práticas à direita.
- **Conteúdo exato na tela:**
  - **Título:** `Boa prática: puxe só o que vai usar (select)`
  - **Esquerda — Prisma com `select` aninhado:**
    ```ts
    prisma.pedido.findMany({
      select: {
        id: true,
        status: true,
        cliente: { select: { nome: true } },
        itens:   { select: { quantidade: true } }
      }
    });
    ```
  - **Direita — 2 Regras Práticas:**
    - **Evite `SELECT *` disfarçado:** `include` traz todas as colunas; `select` reduz tráfego de rede.
    - **Atenção à cascata:** `pedidos → itens → produtos` em loop multiplica as queries exponencialmente.
  - **Nota discreta:** *(Disponível na Opção 5 do CLI se a banca pedir)*

---

### Slide 10 — Pilar 3: Quando Abandonar o ORM (`$queryRaw`) + Micro-Demo 3b
- **Tempo estimado:** `2:15` *(~1m slide + ~1m 15s demo)*
- **Objetivo visual:** Mostrar maturidade técnica: saber a hora de escrever SQL puro seguro via `$queryRaw` e fechar as demos com o comparativo lado a lado.
- **Layout sugerido:** Esquerda = Analogia + 3 critérios objetivos; Direita = Mini-snippet `$queryRaw` (`LEFT JOIN ... IS NULL`) + Badge Demo.
- **Conteúdo exato na tela:**
  - **Título:** `Quando abandonar o ORM e ir de SQL Manual`
  - **Esquerda — Analogia & Critérios:**
    - **Analogia:** *Acesso direto ao cofre / relatório gerencial*
    - **3 casos claros para usar `$queryRaw`:**
      1. Agregações com cálculo entre colunas (`SUM(qtd * preco)`)
      2. Filtros relacionais diretos (`LEFT JOIN ... WHERE p.id IS NULL`)
      3. Relatórios pesados ou queries críticas onde o ORM gera SQL subótimo
  - **Direita — Código curto (`$queryRaw` seguro):**
    ```ts
    // Clientes que nunca compraram
    const semPedidos = await prisma.$queryRaw`
      SELECT c.id, c.nome, c.email
      FROM clientes c
      LEFT JOIN pedidos p ON p.cliente_id = c.id
      WHERE p.id IS NULL
    `;
    ```
  - **Badge no rodapé (Âmbar/Verde):** `▶ DEMO AO VIVO — Opção 6 ($queryRaw) + Opção 7 (Comparativo Final)`
- **Na Demo (Terminal):** Rodar **Opção 6** (Ranking de Faturamento + Clientes sem pedidos) e encerrar o terminal na **Opção 7** (tabela comparativa automática `N+1 × include IN × join`).

---

### Slide 11 — Fechamento (1/2): Tabela-Resumo Comparativa
- **Tempo estimado:** `0:45`
- **Objetivo visual:** Consolidar todos os números e estratégias em um único quadro fácil de fotografar e consultar durante as perguntas da banca.
- **Layout sugerido:** Tabela limpa ocupando a largura do slide com cores semânticas na coluna de queries.
- **Conteúdo exato na tela:**
  - **Título:** `Resumo Comparativo na TechStore (35 pedidos)`
  - **Tabela:**
    | Abordagem | Queries no MySQL | Como o SQL funciona | Quando usar |
    | :--- | :---: | :--- | :--- |
    | **Loop (N+1)** | **`36`** *(Vermelho)* | `1` busca pai + `N` buscas por ID | **Nunca** (anti-pattern) |
    | **`include` (`query`)** | **`2`** *(Verde)* | `SELECT` + `WHERE id IN (...)` | Padrão seguro p/ listas |
    | **`include` (`join`)** | **`1`** *(Verde)* | Query única (`JOIN`/JSON MySQL 8) | Reduzir round-trips |
    | **`$queryRaw`** | **`1`** *(Âmbar)* | SQL puro parametrizado | Relatórios, `SUM`, `LEFT JOIN` |

---

### Slide 12 — Fechamento (2/2): Lições-Chave & Perguntas
- **Tempo estimado:** `1:00`
- **Objetivo visual:** Deixar uma mensagem final marcante para a banca e abrir para arguição.
- **Layout sugerido:** Frase-âncora grande no topo + 3 takeaways curtos em cards + chamada de perguntas no rodapé.
- **Conteúdo exato na tela:**
  - **Frase-âncora:**
    `“O ORM acelera o TypeScript, mas você continua respondendo pelo SQL no MySQL.”`
  - **3 Takeaways:**
    1. **ORM é produtividade** — não substitui o conhecimento de Banco de Dados.
    2. **Sempre meça as queries** — logs do Prisma e `general_log` revelam o N+1 escondido.
    3. **Escolha a ferramenta certa** — `include`/`select` no CRUD e `$queryRaw` no analítico.
  - **Encerramento:** `Obrigado! Perguntas da banca?`

---

## 4. Checklist Rápido Pré-Apresentação (Lab ou Notebook)

1. **Banco no ar antes de abrir os slides:** rodar `cd banco && ./iniciar.sh` e confirmar que `techstore-mysql` está saudável.
2. **Terminal preparado em outra janela/aba:** deixar `cd app && npm start` já aberto no menu principal (`[0-7]`) com **fonte grande** (`Ctrl + +`) para leitura à distância no projetor.
3. **Reset garantido (se precisar):** todas as opções do menu são somente leitura, mas caso testem algo extra no banco antes da banca, rodar `../banco/reset.sh`.
4. **Plano B sem pânico:** se o projetor demorar para espelhar o terminal, os cartões numéricos nos Slides 7, 8 e 11 já carregam os resultados exatos (`36` × `2` × `1` query) para manter a explicação fluida.
