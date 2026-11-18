import { executarComGeneralLog } from "./lib/mysql-log";
import { prisma } from "./lib/prisma";
import { cor, imprimirTabela, subtitulo, titulo } from "./lib/terminal";

interface RankingClienteRow {
  cliente: string;
  totalPedidos: bigint | number;
  totalGasto: string | number;
}

interface ClienteSemPedidoRow {
  id: number;
  nome: string;
  email: string;
  cidade: string;
}

/**
 * Parte 3D — SQL Manual via $queryRaw (tagged template seguro contra SQL Injection):
 * Demonstra dois cenarios analiticos onde SQL puro e mais direto e eficiente que o ORM:
 * 1) Ranking de faturamento com SUM(quantidade * preco_unitario) e GROUP BY
 * 2) Clientes que nunca compraram usando LEFT JOIN ... WHERE p.id IS NULL
 */
export async function demonstrarSqlManual(): Promise<void> {
  titulo("PARTE 3D — QUANDO ABANDONAR O ORM E USAR SQL MANUAL ($queryRaw)");

  console.log(
    `${cor.yellow}Cenário:${cor.reset} agregação com cálculo entre colunas (SUM) e LEFT JOIN para clientes sem pedidos.`
  );

  const { resultado } = await executarComGeneralLog(
    "SQL manual seguro via $queryRaw (2 consultas analíticas)",
    async () => {
      const ranking = await prisma.$queryRaw<RankingClienteRow[]>`
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
        LIMIT 10
      `;

      const semPedidos = await prisma.$queryRaw<ClienteSemPedidoRow[]>`
        SELECT c.id, c.nome, c.email, c.cidade
        FROM clientes c
        LEFT JOIN pedidos p ON p.cliente_id = c.id
        WHERE p.id IS NULL
        ORDER BY c.id ASC
      `;

      return { ranking, semPedidos };
    }
  );

  subtitulo("1) Top 10 Clientes por Faturamento (excluindo cancelados)");
  imprimirTabela(
    ["Cliente", "Pedidos", "Total Gasto (R$)"],
    resultado.ranking.map((r) => [
      r.cliente,
      Number(r.totalPedidos),
      Number(r.totalGasto).toFixed(2),
    ])
  );

  subtitulo("2) Clientes cadastrados que NUNCA compraram (LEFT JOIN ... IS NULL)");
  imprimirTabela(
    ["ID", "Cliente", "E-mail", "Cidade"],
    resultado.semPedidos.map((c) => [c.id, c.nome, c.email, c.cidade])
  );
}
