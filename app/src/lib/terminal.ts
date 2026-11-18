import { createInterface } from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

export const cor = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  cyan: "\x1b[36m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  magenta: "\x1b[35m",
  gray: "\x1b[90m",
};

const rl = createInterface({ input, output });
let readlineFechado = false;
rl.on("close", () => {
  readlineFechado = true;
});

export function linha(largura = 74): void {
  console.log(`${cor.gray}${"─".repeat(largura)}${cor.reset}`);
}

export function titulo(texto: string): void {
  console.log("");
  linha();
  console.log(`${cor.bold}${cor.cyan}  ${texto}${cor.reset}`);
  linha();
}

export function subtitulo(texto: string): void {
  console.log(`\n${cor.bold}${cor.yellow}▸ ${texto}${cor.reset}`);
}

export function imprimirTabela(
  cabecalhos: string[],
  linhas: Array<Array<string | number>>
): void {
  if (linhas.length === 0) {
    console.log(`${cor.dim}(Nenhum registro retornado)${cor.reset}`);
    return;
  }

  const formatadas = linhas.map((l) => l.map((cel) => String(cel)));
  const larguras = cabecalhos.map((cab, idx) =>
    Math.max(cab.length, ...formatadas.map((l) => l[idx].length))
  );

  const montarLinha = (celulas: string[]) =>
    celulas.map((cel, idx) => cel.padEnd(larguras[idx])).join("  │  ");

  const separador = larguras.map((w) => "─".repeat(w)).join("──┼──");

  console.log(`${cor.bold}${montarLinha(cabecalhos)}${cor.reset}`);
  console.log(`${cor.gray}${separador}${cor.reset}`);
  for (const l of formatadas) {
    console.log(montarLinha(l));
  }
}

export async function lerOpcao(prompt: string): Promise<string> {
  if (readlineFechado) return "0";
  try {
    const resposta = await rl.question(`${cor.bold}${cor.cyan}${prompt}${cor.reset}`);
    return resposta.trim();
  } catch {
    return "0";
  }
}

export async function pausar(): Promise<void> {
  if (readlineFechado) return;
  console.log("");
  try {
    await rl.question(`${cor.dim}Pressione ENTER para voltar ao menu...${cor.reset}`);
  } catch {
    // Ignora se o usuario pressionar Ctrl+D (EOF)
  }
}

export function fecharTerminal(): void {
  rl.close();
}
