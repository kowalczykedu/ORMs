import { demonstrarOrmBasico } from "./01-orm-basico";
import { demonstrarProblemaN1 } from "./02-problema-n1";
import {
  demonstrarIncludeIN,
  demonstrarSelectEnxuto,
  demonstrarStrategyJoin,
} from "./03-eager-loading";
import { demonstrarSqlManual } from "./04-sql-manual";
import { demonstrarComparativo } from "./05-comparativo";
import { desconectarPrisma } from "./lib/prisma";
import { cor, fecharTerminal, lerOpcao, pausar } from "./lib/terminal";

function exibirMenu(): void {
  const largura = 74;
  const separador = `${cor.gray}${"─".repeat(largura)}${cor.reset}`;
  const menu = [
    "",
    separador,
    `${cor.bold}${cor.cyan}  TECHSTORE CLI — TEMA 6: ORM (TypeScript + Prisma) & N+1${cor.reset}`,
    separador,
    `  ${cor.bold}1)${cor.reset} Parte 1  — O que é um ORM (model = tabela, objeto = linha)`,
    `  ${cor.bold}2)${cor.reset} Parte 2  — Problema N+1 Clássico (pedidos -> clientes + general_log)`,
    `  ${cor.bold}3)${cor.reset} Parte 3a — Correção com include padrão (WHERE id IN (...))`,
    `  ${cor.bold}4)${cor.reset} Parte 3b — Correção com relationLoadStrategy: "join" (1 query)`,
    `  ${cor.bold}5)${cor.reset} Parte 3c — Enxugando colunas com select (pedidos + clientes + itens)`,
    `  ${cor.bold}6)${cor.reset} Parte 3d — SQL Manual seguro via $queryRaw (Ranking + Sem pedidos)`,
    `  ${cor.bold}7)${cor.reset} Comparativo Lado a Lado (N+1 × include IN × relationLoadStrategy: "join")`,
    `  ${cor.bold}0)${cor.reset} Sair`,
    separador,
  ].join("\n");

  console.log(menu);
}

async function main(): Promise<void> {
  let executando = true;

  while (executando) {
    exibirMenu();
    const opcao = await lerOpcao("Escolha uma opção [0-7]: ");

    try {
      switch (opcao) {
        case "1":
          await demonstrarOrmBasico();
          await pausar();
          break;
        case "2":
          await demonstrarProblemaN1();
          await pausar();
          break;
        case "3":
          await demonstrarIncludeIN();
          await pausar();
          break;
        case "4":
          await demonstrarStrategyJoin();
          await pausar();
          break;
        case "5":
          await demonstrarSelectEnxuto();
          await pausar();
          break;
        case "6":
          await demonstrarSqlManual();
          await pausar();
          break;
        case "7":
          await demonstrarComparativo();
          await pausar();
          break;
        case "0":
          executando = false;
          break;
        default:
          console.log(`\n${cor.red}Opção inválida. Escolha entre 0 e 7.${cor.reset}`);
          await pausar();
      }
    } catch (erro) {
      const mensagem = erro instanceof Error ? erro.message : String(erro);
      console.error(`\n${cor.red}${cor.bold}Erro ao executar a demonstração:${cor.reset} ${mensagem}`);
      console.error(
        `${cor.yellow}Dica:${cor.reset} verifique se o container MySQL está rodando (../banco/iniciar.sh) e se .env usa o usuário root.`
      );
      await pausar();
    }
  }

  await desconectarPrisma();
  fecharTerminal();
  console.log(`\n${cor.green}Conexão encerrada. Boa apresentação na AV4!${cor.reset}\n`);
}

main().catch(async (erro) => {
  console.error("Erro fatal:", erro);
  await desconectarPrisma();
  fecharTerminal();
  process.exit(1);
});
