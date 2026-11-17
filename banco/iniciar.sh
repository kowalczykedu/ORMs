#!/usr/bin/env bash
#
# iniciar.sh — Sobe o ambiente do Banco Relacional (MySQL + phpMyAdmin + Excalidraw)
#             (com liberação prévia automática de portas)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Portas do ambiente SQL: 3306 (MySQL), 8080 (phpMyAdmin), 8081 (Excalidraw)
APP_PORTS=(3306 8080 8081)

echo -e "${CYAN}Verificando e liberando portas para evitar conflitos no Ubuntu...${NC}"

for port in "${APP_PORTS[@]}"; do
    if command -v fuser >/dev/null 2>&1; then
        fuser -k -n tcp "$port" >/dev/null 2>&1 || true
    elif command -v lsof >/dev/null 2>&1; then
        PIDS=$(lsof -ti :"$port" 2>/dev/null || true)
        if [[ -n "$PIDS" ]]; then
            echo -e "${YELLOW}Liberando porta $port (PID: $PIDS)...${NC}"
            kill -9 $PIDS >/dev/null 2>&1 || true
        fi
    fi
done

echo -e "${CYAN}Iniciando ambiente do Banco Relacional...${NC}"

# Testar se o docker roda direto ou precisa do grupo/sudo
if docker info >/dev/null 2>&1; then
    docker compose up -d --remove-orphans
elif sg docker -c "docker info" >/dev/null 2>&1; then
    sg docker -c "docker compose up -d --remove-orphans"
else
    echo -e "${YELLOW}[AVISO] Permissão do Docker pendente no terminal. Executando com sudo...${NC}"
    sudo docker compose up -d --remove-orphans
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║             🚀 AMBIENTE BANCO RELACIONAL PRONTO!                ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "║  ${BOLD}INTERFACES WEB:${NC}                                                 ║"
echo -e "║  • phpMyAdmin:       ${CYAN}http://localhost:8080${NC} (Usuário: root | Senha: root) ║"
echo -e "║  • Excalidraw:       ${CYAN}http://localhost:8081${NC} (Diagramas ER)               ║"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "║  ${BOLD}CONEXÃO DIRETA MYSQL (DBeaver / VS Code / Terminal):${NC}           ║"
echo -e "║  • Host:             ${CYAN}localhost${NC}                                      ║"
echo -e "║  • Porta:            ${CYAN}3306${NC}                                           ║"
echo -e "║  • Banco:            ${CYAN}techstore${NC}                                      ║"
echo -e "║  • Usuário Aluno:    ${CYAN}aluno${NC} / Senha: ${CYAN}aluno123${NC}                         ║"
echo -e "║  • Usuário Admin:    ${CYAN}root${NC}  / Senha: ${CYAN}root${NC}                             ║"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
