#!/usr/bin/env bash
#
# reset.sh — Reinicia o banco TechStore para o estado de fábrica
#
# Uso: ./reset.sh
#

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}[AVISO]${NC} Este script irá apagar todos os dados atuais do banco e recriar o TechStore com os dados iniciais do init.sql."
read -p "Deseja continuar? (s/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo -e "${BLUE}[INFO]${NC} Parando serviços e removendo volume antigo..."
docker compose down -v

echo -e "${BLUE}[INFO]${NC} Subindo novos containers e executando init.sql..."
docker compose up -d

echo -e "${GREEN}[OK]${NC} Banco TechStore restaurado com sucesso!"
echo -e "Acesse o phpMyAdmin em: ${BLUE}http://localhost:8080${NC}"
