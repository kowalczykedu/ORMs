#!/usr/bin/env bash
#
# setup.sh — Prepara a aplicacao TypeScript + Prisma (TechStore) no notebook ou PC do laboratorio.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== Setup TechStore CLI (TypeScript + Prisma) ===${NC}"

# 1. Verificar Node.js e npm
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}[ERRO] Node.js e npm precisam estar instalados (recomendado Node 20+).${NC}"
    exit 1
fi
echo -e "${GREEN}[OK]${NC} Node $(node -v) | npm $(npm -v)"

# 2. Garantir .env a partir do .env.example
if [[ ! -f .env ]]; then
    cp .env.example .env
    echo -e "${GREEN}[OK]${NC} Arquivo .env criado a partir de .env.example (modo root)."
else
    echo -e "${GREEN}[OK]${NC} Arquivo .env ja existe."
fi

# 3. Instalar dependencias e gerar PrismaClient
echo -e "${CYAN}[INFO]${NC} Instalando dependencias npm..."
npm install

echo -e "${CYAN}[INFO]${NC} Gerando PrismaClient tipado (npx prisma generate)..."
npx prisma generate

# 4. Verificar se o MySQL do TechStore esta respondendo na porta 3306
MYSQL_OK=0
if timeout 2 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/3306' 2>/dev/null; then
    MYSQL_OK=1
fi

if [[ "$MYSQL_OK" -eq 1 ]]; then
    echo -e "${CYAN}[INFO]${NC} Testando conexao com o banco TechStore..."
    if npx tsx -e "import { prisma } from './src/lib/prisma'; (async () => { const total = await prisma.pedido.count(); console.log('Pedidos encontrados no TechStore:', total); await prisma.\$disconnect(); })();"; then
        echo -e "${GREEN}[OK]${NC} Conexao com MySQL + Prisma validada!"
    else
        echo -e "${YELLOW}[AVISO]${NC} Porta 3306 aberta, mas houve erro ao consultar o banco techstore."
        echo -e "Verifique se o container subiu com ${CYAN}../banco/iniciar.sh${NC} e se .env esta correto."
    fi
else
    echo -e "${YELLOW}[AVISO]${NC} MySQL nao detectado em localhost:3306."
    echo -e "Antes de rodar a aplicacao, suba o banco com:"
    echo -e "  ${CYAN}cd ../banco && ./iniciar.sh${NC}"
fi

echo ""
echo -e "${GREEN}Setup concluido!${NC} Para abrir o menu interativo, execute:"
echo -e "  ${CYAN}npm start${NC}"
echo ""
