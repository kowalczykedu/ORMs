# Ambiente de Desenvolvimento — Banco de Dados Relacional

Ambiente pré-configurado com **Docker**, **MySQL 8**, **phpMyAdmin** e **Excalidraw** para a disciplina de **Banco de Dados Relacional (TSI33D-TSI3)** da UTFPR Campus Guarapuava.

---

## ⚡ Passo 1: Instalação e Configuração do Docker (Apenas 1 vez por máquina)

Se você está em um computador do laboratório ou no seu notebook pessoal com **Ubuntu / Linux Mint**, execute o instalador automatizado que configura todas as permissões de usuário:

```bash
# 1. Conceder permissão de execução a todos os scripts
chmod +x *.sh

# 2. Executar o instalador (solicitará sua senha de sudo apenas se o Docker não estiver instalado)
./setup.sh
```

### 🔑 Como funciona a permissão sem `sudo` no Ubuntu:
O script adiciona automaticamente o seu usuário ao grupo `docker` e ajusta as permissões do socket `/var/run/docker.sock`.
- **Se abrir um novo terminal e der erro de permissão**, basta rodar uma única vez:
  ```bash
  newgrp docker
  ```
  *(Ou faça logout e login na sua sessão do sistema)*.

---

## 🚀 Passo 2: Subir o Ambiente Completo com 1 Comando

Com o terminal aberto dentro da pasta `ambiente/`, execute:

```bash
./iniciar.sh
```

> [!NOTE]
> O script `./iniciar.sh` possui um mecanismo que **libera automaticamente as portas 3306, 8080 e 8081 antes de iniciar**, evitando qualquer erro de conflito de portas com outros serviços MySQL locais no Ubuntu.

### 🛑 Parar os serviços
Para pausar os containers sem perder seus dados, tabelas ou exercícios criados em aula:

```bash
./parar.sh
```

### 🔄 Resetar para o estado original (TechStore de fábrica)
Se você quiser limpar todas as alterações e recriar o banco do zero a partir do [`init.sql`](init.sql):

```bash
./reset.sh
```

---

## 🌐 Serviços e Acessos Web

| Serviço / Ferramenta | Endereço Web / Conexão | Finalidade | Credenciais |
| :--- | :--- | :--- | :--- |
| **phpMyAdmin** | [http://localhost:8080](http://localhost:8080) | Interface visual para gerenciar o MySQL e rodar queries | Conecta autenticado automaticamente |
| **Excalidraw** | [http://localhost:8081](http://localhost:8081) | Quadro branco para desenho de DER e modelo lógico | Sem necessidade de login |
| **MySQL 8 (Conexão direta)** | `localhost:3306` | Para DBeaver, DataGrip, VS Code ou terminal | **Aluno:** `aluno` / `aluno123`<br>**Admin:** `root` / `root` |

---

## 💾 Persistência de Dados & Inicialização

- **Primeira execução:** O MySQL executa automaticamente o script [`init.sql`](init.sql), criando o banco de dados `techstore`, todas as tabelas e o dataset completo.
- **Persistência garantida:** Os dados são armazenados no volume Docker nomeado `techstore_mysql_data`. Suas tabelas criadas em aula, inserts e alterações **NÃO** serão apagadas ao reiniciar o computador ou dar `./parar.sh`.

---

## 🛒 O Banco de Dados de Referência: TechStore

O **TechStore** simula uma loja virtual completa de tecnologia e é utilizado em todos os exemplos de aula, listas de exercícios e atividades práticas.

### 📐 Modelo Relacional (Diagrama Simplificado)

```
[categorias] (1) ────< (N) [produtos] (1) ────< (N) [itens_pedido]
                                                          ^
                                                          | (N)
                                                          |
[clientes]   (1) ─────────────────────────────< (N) [pedidos]
```

### 📋 Estrutura das Tabelas & Estatísticas do Dataset

- **`categorias` (9 registros):** Informática, Smartphones, Áudio/Vídeo, Games, Periféricos, Hardware, Livros, Móveis e Softwares.
- **`clientes` (25 registros):** Clientes com compras recorrentes, compras únicas e clientes cadastrados sem pedidos (perfeitos para `LEFT JOIN` e `NOT IN`).
- **`produtos` (30 registros):** Preços variando de R$ 79,90 a R$ 7.499,00, diferentes níveis de estoque (incluindo produtos com estoque zero e produtos sem histórico de vendas).
- **`pedidos` (35 registros):** Distribuídos entre 2025 e 2026, com status diversificados (`'entregue'`, `'enviado'`, `'pago'`, `'pendente'`, `'cancelado'`).
- **`itens_pedido` (80+ registros):** Carrinhos variados (compras simples e pedidos com múltiplos itens e quantidades).

---

## 🔍 Exemplos de Consultas para Praticar no phpMyAdmin

Abra [http://localhost:8080](http://localhost:8080), selecione o banco `techstore` na barra lateral esquerda e clique na aba **SQL**:

### 1. Produtos mais caros com suas categorias (`INNER JOIN` + `ORDER BY`)
```sql
SELECT 
    p.id,
    p.nome AS produto,
    c.nome AS categoria,
    p.preco,
    p.estoque
FROM produtos p
INNER JOIN categorias c ON p.categoria_id = c.id
ORDER BY p.preco DESC
LIMIT 10;
```

### 2. Clientes que NUNCA fizeram nenhum pedido (`LEFT JOIN` com `IS NULL`)
```sql
SELECT 
    c.id,
    c.nome,
    c.email,
    c.cidade,
    c.data_cadastro
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.cliente_id
WHERE p.id IS NULL;
```

### 3. Faturamento total e ticket médio por cliente VIP (`GROUP BY` + `HAVING`)
```sql
SELECT 
    cli.nome AS cliente,
    cli.cidade,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(ip.quantidade * ip.preco_unitario) AS total_gasto,
    ROUND(AVG(ip.quantidade * ip.preco_unitario), 2) AS ticket_medio_item
FROM clientes cli
INNER JOIN pedidos p ON cli.id = p.cliente_id
INNER JOIN itens_pedido ip ON p.id = ip.pedido_id
WHERE p.status = 'entregue'
GROUP BY cli.id, cli.nome, cli.cidade
HAVING total_gasto > 2000
ORDER BY total_gasto DESC;
```

### 4. Vendas consolidadas por ano e mês (`YEAR` + `MONTH` + `SUM`)
```sql
SELECT 
    YEAR(p.data_pedido) AS ano,
    MONTH(p.data_pedido) AS mes,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(ip.quantidade * ip.preco_unitario) AS faturamento_mes
FROM pedidos p
INNER JOIN itens_pedido ip ON p.id = ip.pedido_id
WHERE p.status <> 'cancelado'
GROUP BY YEAR(p.data_pedido), MONTH(p.data_pedido)
ORDER BY ano, mes;
```

---

## 🎨 Diagramação no Excalidraw

Acesse [http://localhost:8081](http://localhost:8081) para desenhar diagramas conceituais (DER) e lógicos.  
- Salve seus arquivos `.excalidraw` na pasta `diagramas/` do seu repositório para manter seus modelos versionados.
