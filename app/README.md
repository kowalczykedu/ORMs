# TechStore CLI — TypeScript + Prisma (AV4 / Tema 6)

Aplicação simples de terminal em **TypeScript + Prisma** conectada ao banco relacional **TechStore** (`../banco/init.sql`) para demonstrar na prática:

1. **Parte 1:** O que é um ORM (`model` = tabela, objeto = linha, `@map` / `@@map`);
2. **Parte 2:** O Problema N+1 clássico (`pedidos` → `clientes`) provado ao vivo via `mysql.general_log`;
3. **Parte 3:** Carregamento antecipado (`include` padrão com `WHERE id IN (...)`, `relationLoadStrategy: "join"`, `select` enxuto) e SQL manual seguro com `$queryRaw`.

---

## Como preparar no Notebook ou no PC do Laboratório

### 1. Subir o banco MySQL da disciplina
Na pasta `banco/`, inicie os containers (não altera nem modifica os arquivos originais):

```bash
cd ../banco
./iniciar.sh
```

### 2. Preparar a aplicação `app/`
```bash
cd ../app
chmod +x setup.sh
./setup.sh
```

> O `setup.sh` cria o `.env` a partir de `.env.example` (usando `root` para permitir habilitar e ler `mysql.general_log` automaticamente), instala as dependências, roda `npx prisma generate` e testa a conexão com o TechStore.

### 3. Executar o menu interativo
```bash
npm start
```

---

## Roteiro da Apresentação no Menu (`npm start`)

| Opção | Arquivo | Pilar do Tema 6 | O que mostra ao vivo |
| :---: | :--- | :--- | :--- |
| **1** | `src/01-orm-basico.ts` | **Parte 1 (ORM)** | Busca tipada de 1 `Cliente` (objeto = linha) e listagem filtrada de `Produto`s |
| **2** | `src/02-problema-n1.ts` | **Parte 2 (N+1)** | Loop `pedidos` → `clientes`, imprimindo **todas as 36 queries** do `mysql.general_log` + resumo |
| **3** | `src/03-eager-loading.ts` | **Parte 3a (`include`)** | Correção com `include: { cliente: true }` usando `WHERE id IN (...)` (**2 queries**) |
| **4** | `src/03-eager-loading.ts` | **Parte 3b (`join`)** | Correção com `relationLoadStrategy: "join"` (**1 única query** no MySQL 8) |
| **5** | `src/03-eager-loading.ts` | **Parte 3c (`select`)** | `select` aninhado em `pedidos`, `clientes` e `itens_pedido` evitando `SELECT *` |
| **6** | `src/04-sql-manual.ts` | **Parte 3d (`$queryRaw`)** | Ranking de faturamento (`SUM` + `GROUP BY`) e clientes sem pedidos (`LEFT JOIN ... IS NULL`) |
| **7** | `src/05-comparativo.ts` | **Comparativo** | Tabela lado a lado com contagem real de queries (`general_log`) e tempo (ms) |

---

## Estrutura e Manutenção do Banco

- A aplicação executa **apenas leituras** (não insere, altera ou apaga registros do TechStore).
- Em cada demonstração monitorada, `src/lib/mysql-log.ts` liga `mysql.general_log` (`TABLE`), limpa com `TRUNCATE`, mede a execução e **desliga automaticamente** (`SET GLOBAL general_log = 'OFF'`) ao final.
- Caso precise restaurar o banco TechStore para o estado original de fábrica em algum momento, execute o script da disciplina:

```bash
cd ../banco
./reset.sh
```
