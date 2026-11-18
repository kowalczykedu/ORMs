import { executarComGeneralLog } from "./lib/mysql-log";
import { prisma } from "./lib/prisma";
import { cor, imprimirTabela, subtitulo, titulo } from "./lib/terminal";

export interface PedidoComClienteResumo {
  pedidoId: number;
  dataPedido: string;
  status: string;
  clienteNome: string;
}

/**
 * Busca classica COM problema N+1:
 * 1 query para listar todos os pedidos + N queries individuais dentro do loop
 * para descobrir o cliente de cada pedido.
 */
export async function buscarPedidosComClienteN1(): Promise<PedidoComClienteResumo[]> {
  const pedidos = await prisma.pedido.findMany({
    orderBy: { id: "asc" },
  });

  const resultado: PedidoComClienteResumo[] = [];

  for (const pedido of pedidos) {
    const cliente = await prisma.cliente.findUnique({
      where: { id: pedido.clienteId },
    });

    resultado.push({
      pedidoId: pedido.id,
      dataPedido: pedido.dataPedido.toISOString().slice(0, 10),
      status: pedido.status,
      clienteNome: cliente?.nome ?? "(Desconhecido)",
    });
  }

  return resultado;
}

export async function demonstrarProblemaN1(): Promise<void> {
  titulo("PARTE 2 — O PROBLEMA N+1 CLÁSSICO (pedidos -> clientes)");

  console.log(
    `${cor.red}Cenário:${cor.reset} listar todos os pedidos e buscar o cliente de cada um dentro de um loop (1 + N queries).`
  );

  const { resultado } = await executarComGeneralLog(
    "N+1 Clássico (pedidos -> clientes)",
    buscarPedidosComClienteN1
  );

  subtitulo(`Amostra dos registros retornados (primeiros 8 de ${resultado.length} pedidos)`);
  imprimirTabela(
    ["Pedido", "Data", "Status", "Cliente"],
    resultado.slice(0, 8).map((r) => [r.pedidoId, r.dataPedido, r.status, r.clienteNome])
  );
}
