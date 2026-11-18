import { prisma } from "./lib/prisma";
import { cor, imprimirTabela, subtitulo, titulo } from "./lib/terminal";

/**
 * Parte 1 — O que e um ORM:
 * Demonstra de forma simples e sem alterar dados no banco que:
 * - model Cliente / Produto = tabela no MySQL (via @@map)
 * - objeto retornado = linha da tabela
 * - propriedades em camelCase = colunas em snake_case (via @map)
 */
export async function demonstrarOrmBasico(): Promise<void> {
  titulo("PARTE 1 — O QUE É UM ORM (TypeScript + Prisma no TechStore)");

  console.log(
    `${cor.dim}Equivalencia: model Prisma = tabela MySQL | objeto TS = linha | propriedade = coluna${cor.reset}`
  );

  // 1. Busca de uma unica linha (objeto tipado)
  subtitulo("1) Busca tipada de 1 registro (model Cliente -> tabela clientes)");
  const cliente = await prisma.cliente.findUnique({
    where: { id: 1 },
  });

  if (cliente) {
    console.log("Objeto retornado pelo Prisma (prisma.cliente.findUnique):");
    console.log({
      id: cliente.id,
      nome: cliente.nome,
      email: cliente.email,
      cidade: cliente.cidade,
      dataCadastro: cliente.dataCadastro.toISOString().slice(0, 10),
    });
  }

  // 2. Busca filtrada de produtos da Categoria 1 (Informatica & Computadores)
  subtitulo("2) Listagem filtrada (model Produto -> tabela produtos, categoriaId = 1)");
  const produtos = await prisma.produto.findMany({
    where: { categoriaId: 1 },
    orderBy: { preco: "desc" },
  });

  imprimirTabela(
    ["ID", "Produto", "Preço (R$)", "Estoque"],
    produtos.map((p) => [
      p.id,
      p.nome,
      Number(p.preco).toFixed(2),
      p.estoque,
    ])
  );
}
