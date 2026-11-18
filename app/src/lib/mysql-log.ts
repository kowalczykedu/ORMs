import { prisma } from "./prisma";
import { cor, linha, subtitulo } from "./terminal";

export interface QueryRegistrada {
  horario: string;
  tipo: string;
  sqlTexto: string;
}

export interface ResultadoMonitorado<T> {
  resultado: T;
  queries: QueryRegistrada[];
  totalQueries: number;
  duracaoMs: number;
}

export interface OpcoesMonitoramento {
  imprimirQueries?: boolean;
  imprimirResumo?: boolean;
}

/**
 * Executa uma operacao Prisma monitorando todas as queries reais recebidas
 * pelo MySQL 8 por meio da tabela `mysql.general_log`.
 */
export async function executarComGeneralLog<T>(
  nomeCenario: string,
  fn: () => Promise<T>,
  opcoes: OpcoesMonitoramento = {}
): Promise<ResultadoMonitorado<T>> {
  const { imprimirQueries = true, imprimirResumo = true } = opcoes;

  // Aquece o pool antes de limpar o log para nao contar queries de handshake inicial.
  await prisma.$queryRawUnsafe("SELECT 1");

  await prisma.$executeRawUnsafe("SET GLOBAL log_output = 'TABLE'");
  await prisma.$executeRawUnsafe("SET GLOBAL general_log = 'ON'");
  await prisma.$executeRawUnsafe("TRUNCATE TABLE mysql.general_log");

  let resultado!: T;
  let duracaoMs = 0;

  try {
    const inicio = performance.now();
    resultado = await fn();
    duracaoMs = performance.now() - inicio;
  } finally {
    await prisma.$executeRawUnsafe("SET GLOBAL general_log = 'OFF'");
  }

  const queries = await prisma.$queryRaw<QueryRegistrada[]>`
    SELECT
      CAST(event_time AS CHAR) AS horario,
      command_type AS tipo,
      CAST(argument AS CHAR) AS sqlTexto
    FROM mysql.general_log
    WHERE command_type IN ('Query', 'Execute')
      AND CAST(argument AS CHAR) NOT LIKE '%mysql.general_log%'
      AND CAST(argument AS CHAR) NOT LIKE 'SET GLOBAL%'
      AND CAST(argument AS CHAR) NOT LIKE 'TRUNCATE TABLE%'
    ORDER BY event_time ASC
  `;

  if (imprimirQueries) {
    subtitulo(`Queries capturadas no mysql.general_log — ${nomeCenario}`);
    if (queries.length === 0) {
      console.log(`${cor.dim}(Nenhuma query registrada)${cor.reset}`);
    } else {
      queries.forEach((q, idx) => {
        const sqlLimpo = q.sqlTexto.replace(/\s+/g, " ").trim();
        console.log(
          `${cor.gray}[${String(idx + 1).padStart(2, "0")}]${cor.reset} ${cor.dim}(${q.tipo})${cor.reset} ${sqlLimpo}`
        );
      });
    }
  }

  if (imprimirResumo) {
    const corContagem =
      queries.length > 5 ? cor.red : queries.length === 1 ? cor.green : cor.cyan;

    console.log("");
    linha();
    console.log(`${cor.bold}  RESUMO DO MYSQL GENERAL_LOG — ${nomeCenario}${cor.reset}`);
    console.log(
      `  • Total de queries executadas no MySQL: ${cor.bold}${corContagem}${queries.length}${cor.reset}`
    );
    console.log(
      `  • Tempo total de execução:              ${cor.bold}${cor.yellow}${duracaoMs.toFixed(2)} ms${cor.reset}`
    );
    linha();
  }

  return {
    resultado,
    queries,
    totalQueries: queries.length,
    duracaoMs,
  };
}
