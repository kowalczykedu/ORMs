import { executarComGeneralLog } from "./lib/mysql-log";
import { prisma } from "./lib/prisma";
import { cor, imprimirTabela, subtitulo, titulo } from "./lib/terminal";

/**
 * Busca usando a estrategia em lote "query" (`WHERE id IN (...)`),
 * que e o padrao do Prisma quando `relationJoins` nao esta ativo.
 */
export async function buscarPedidosComClienteIncludeIN() {
  return prisma.pedido.findMany({
    relationLoadStrategy: "query",
    include: { cliente: true },
    orderBy: { id: "asc" },
  });
}

/**
 * Busca usando `relationLoadStrategy: "join"` (no MySQL 8 gera 1 query unica com subquery/JSON).
 */
export async function buscarPedidosComClienteJoin() {
  return prisma.pedido.findMany({
    relationLoadStrategy: "join",
    include: { cliente: true },
    orderBy: { id: "asc" },
  });
}

export async function demonstrarIncludeIN(): Promise<void> {
  titulo("PARTE 3A — CARREGAMENTO ANTECIPADO COM include PADRÃO (WHERE id IN (...))");

  console.log(
    `${cor.cyan}Cenário:${cor.reset} mesma listagem de pedidos + cliente usando ${cor.bold}include: { cliente: true }${cor.reset} com estratégia ${cor.bold}"query"${cor.reset} (WHERE id IN (...)).`
  );

  const { resultado } = await executarComGeneralLog(
    "include padrão (WHERE id IN (...))",
    buscarPedidosComClienteIncludeIN
  );

  subtitulo(`Amostra dos registros retornados (primeiros 8 de ${resultado.length} pedidos)`);
  imprimirTabela(
    ["Pedido", "Data", "Status", "Cliente"],
    resultado.slice(0, 8).map((p) => [
      p.id,
      p.dataPedido.toISOString().slice(0, 10),
      p.status,
      p.cliente.nome,
    ])
  );
}

export async function demonstrarStrategyJoin(): Promise<void> {
  titulo("PARTE 3B — CARREGAMENTO ANTECIPADO COM relationLoadStrategy: 'join'");

  console.log(
    `${cor.green}Cenário:${cor.reset} mesma listagem forçando ${cor.bold}relationLoadStrategy: "join"${cor.reset} (1 única query no MySQL 8).`
  );

  const { resultado } = await executarComGeneralLog(
    "relationLoadStrategy: 'join' (MySQL 8)",
    buscarPedidosComClienteJoin
  );

  subtitulo(`Amostra dos registros retornados (primeiros 8 de ${resultado.length} pedidos)`);
  imprimirTabela(
    ["Pedido", "Data", "Status", "Cliente"],
    resultado.slice(0, 8).map((p) => [
      p.id,
      p.dataPedido.toISOString().slice(0, 10),
      p.status,
      p.cliente.nome,
    ])
  );
}

export async function demonstrarSelectEnxuto(): Promise<void> {
  titulo("PARTE 3C — ENXUGANDO COLUNAS COM select (pedidos + clientes + itens_pedido)");

  console.log(
    `${cor.cyan}Cenário:${cor.reset} buscando somente as colunas necessárias de ${cor.bold}pedidos, clientes e itens_pedido${cor.reset} (evita SELECT *).`
  );

  const { resultado } = await executarComGeneralLog(
    "select enxuto (pedidos + clientes + itens_pedido)",
    () =>
      prisma.pedido.findMany({
        relationLoadStrategy: "query",
        select: {
          id: true,
          dataPedido: true,
          status: true,
          cliente: {
            select: {
              nome: true,
            },
          },
          itens: {
            select: {
              quantidade: true,
              precoUnitario: true,
            },
          },
        },
        orderBy: { id: "asc" },
      })
  );

  subtitulo(`Amostra dos registros retornados (primeiros 8 de ${resultado.length} pedidos)`);
  imprimirTabela(
    ["Pedido", "Data", "Status", "Cliente", "Qtd Itens", "Total (R$)"],
    resultado.slice(0, 8).map((p) => {
      const total = p.itens.reduce(
        (acc, item) => acc + item.quantidade * Number(item.precoUnitario),
        0
      );
      return [
        p.id,
        p.dataPedido.toISOString().slice(0, 10),
        p.status,
        p.cliente.nome,
        p.itens.length,
        total.toFixed(2),
      ];
    })
  );
}
