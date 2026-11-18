import { buscarPedidosComClienteN1 } from "./02-problema-n1";
import {
  buscarPedidosComClienteIncludeIN,
  buscarPedidosComClienteJoin,
} from "./03-eager-loading";
import { executarComGeneralLog } from "./lib/mysql-log";
import { cor, imprimirTabela, subtitulo, titulo } from "./lib/terminal";

/**
 * Executa as 3 abordagens em sequencia e apresenta uma tabela comparativa
 * com contagem real de queries no MySQL (`general_log`) e tempo de execucao.
 */
export async function demonstrarComparativo(): Promise<void> {
  titulo("COMPARATIVO LADO A LADO — N+1 × include (IN) × relationLoadStrategy: 'join'");

  console.log(
    `${cor.dim}Executando os 3 cenários sobre a mesma listagem (35 pedidos + cliente) com medição no mysql.general_log...${cor.reset}`
  );

  const n1 = await executarComGeneralLog(
    "N+1 Clássico",
    buscarPedidosComClienteN1,
    { imprimirQueries: false, imprimirResumo: false }
  );

  const includeIn = await executarComGeneralLog(
    "include padrão (IN)",
    buscarPedidosComClienteIncludeIN,
    { imprimirQueries: false, imprimirResumo: false }
  );

  const joinStrategy = await executarComGeneralLog(
    "relationLoadStrategy: 'join'",
    buscarPedidosComClienteJoin,
    { imprimirQueries: false, imprimirResumo: false }
  );

  subtitulo("Resultado Real Medido no MySQL 8 (TechStore)");
  imprimirTabela(
    ["Abordagem", "Queries no MySQL", "Tempo (ms)", "Estratégia SQL Gerada"],
    [
      [
        "1. Loop sem include (N+1)",
        n1.totalQueries,
        n1.duracaoMs.toFixed(2),
        "1 SELECT pedidos + N SELECTs clientes WHERE id = ?",
      ],
      [
        "2. include padrão (query)",
        includeIn.totalQueries,
        includeIn.duracaoMs.toFixed(2),
        "1 SELECT pedidos + 1 SELECT clientes WHERE id IN (...)",
      ],
      [
        "3. relationLoadStrategy: 'join'",
        joinStrategy.totalQueries,
        joinStrategy.duracaoMs.toFixed(2),
        "1 query única (subquery correlacionada + JSON no MySQL 8)",
      ],
    ]
  );

  const reducaoIn = (((n1.totalQueries - includeIn.totalQueries) / n1.totalQueries) * 100).toFixed(1);
  const reducaoJoin = (((n1.totalQueries - joinStrategy.totalQueries) / n1.totalQueries) * 100).toFixed(1);

  console.log("");
  console.log(
    `  ${cor.green}✔ Redução de queries (N+1 → include IN):${cor.reset} ${n1.totalQueries} → ${includeIn.totalQueries} (${cor.bold}-${reducaoIn}%${cor.reset})`
  );
  console.log(
    `  ${cor.green}✔ Redução de queries (N+1 → join):${cor.reset}       ${n1.totalQueries} → ${joinStrategy.totalQueries} (${cor.bold}-${reducaoJoin}%${cor.reset})`
  );
}
