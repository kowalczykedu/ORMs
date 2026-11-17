#!/usr/bin/env bash
#
# setup.sh — Instalação e configuração automatizada do Docker Engine + Docker Compose
#             Suporta: Ubuntu, Linux Mint, Debian, Pop!_OS e derivados
#
# Pode ser executado localmente:
#   chmod +x setup.sh && ./setup.sh
#
# Ou via comando único (curl):
#   curl -fsSL https://raw.githubusercontent.com/MarceloVichar/base-banco-sql-docker/main/setup.sh | bash
#
set -euo pipefail

# ──────────────────────────────────────────────────
# Cores para output
# ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_error()   { echo -e "${RED}[ERRO]${NC}  $*"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Instalador e Verificador Docker + Docker Compose   ║${NC}"
echo -e "${CYAN}║   UTFPR — Banco de Dados Relacional                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ──────────────────────────────────────────────────
# 1. Verificação de privilégios
# ──────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    log_error "Não execute este script diretamente como root (ex: sudo ./setup.sh)."
    log_error "Execute como seu usuário normal. O script solicitará sudo quando necessário."
    exit 1
fi

log_info "Verificando permissões de administrador (sudo)..."
if ! sudo -v; then
    log_error "Falha ao obter privilégios de sudo. Abortando."
    exit 1
fi

# Manter sudo ativo durante a execução
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

# ──────────────────────────────────────────────────
# 2. Detecção do Sistema Operacional
# ──────────────────────────────────────────────────
log_info "Detectando sistema operacional..."

if [[ ! -f /etc/os-release ]]; then
    log_error "Arquivo /etc/os-release não encontrado. Distribuição não suportada."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

DISTRO_ID="${ID:-ubuntu}"
DISTRO_NAME="${PRETTY_NAME:-Linux}"

# Detectar codename correto (especialmente para Linux Mint e Pop!_OS)
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
if [[ -z "$CODENAME" ]] && command -v lsb_release &>/dev/null; then
    CODENAME="$(lsb_release -cs 2>/dev/null || true)"
fi

if [[ -z "$CODENAME" ]]; then
    CODENAME="noble" # Fallback para Ubuntu 24.04 LTS se não detectar
fi

ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
fi

log_ok "Sistema: $DISTRO_NAME"
log_ok "Base: $DISTRO_ID ($CODENAME) | Arquitetura: $ARCH"

# ──────────────────────────────────────────────────
# 3. Verificação prévia: Docker já está instalado?
# ──────────────────────────────────────────────────
NEED_INSTALL=false

if command -v docker &>/dev/null && docker compose version &>/dev/null; then
    CURRENT_DOCKER_VER="$(docker --version 2>/dev/null || echo '')"
    CURRENT_COMPOSE_VER="$(docker compose version 2>/dev/null || echo '')"
    log_ok "Docker já instalado: $CURRENT_DOCKER_VER"
    log_ok "Docker Compose já instalado: $CURRENT_COMPOSE_VER"
    log_info "Pulando etapa de instalação de pacotes..."
else
    NEED_INSTALL=true
fi

# ──────────────────────────────────────────────────
# 4. Instalação do Docker (se necessário)
# ──────────────────────────────────────────────────
if [ "$NEED_INSTALL" = true ]; then
    log_info "Iniciando instalação oficial do Docker Engine e Compose..."

    # Remover versões antigas ou conflitantes
    log_info "Removendo possíveis pacotes conflitantes..."
    CONFLICTING_PACKAGES=(
        docker.io
        docker-doc
        docker-compose
        docker-compose-v2
        podman-docker
        containerd
        runc
    )
    PACKAGES_TO_REMOVE=()
    for pkg in "${CONFLICTING_PACKAGES[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            PACKAGES_TO_REMOVE+=("$pkg")
        fi
    done

    if [[ ${#PACKAGES_TO_REMOVE[@]} -gt 0 ]]; then
        log_warn "Removendo pacotes obsoletos: ${PACKAGES_TO_REMOVE[*]}"
        sudo apt-get remove -y "${PACKAGES_TO_REMOVE[@]}" >/dev/null 2>&1 || true
    fi

    # Instalar dependências
    log_info "Instalando pré-requisitos do apt..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release >/dev/null

    # Configurar chave GPG oficial do Docker
    log_info "Configurando chave GPG oficial do Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Adicionar repositório oficial
    log_info "Adicionando repositório oficial do Docker..."
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualizar repositório e instalar
    log_info "Instalando Docker Engine, CLI, containerd e Docker Compose Plugin..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin >/dev/null

    log_ok "Pacotes do Docker instalados com sucesso!"
fi

# ──────────────────────────────────────────────────
# 5. Configurar Grupo Docker e Permissões de Usuário
# ──────────────────────────────────────────────────
log_info "Configurando permissões do usuário '$USER'..."

if ! getent group docker &>/dev/null; then
    sudo groupadd docker
    log_ok "Grupo 'docker' criado."
fi

USER_IN_GROUP=false
if id -nG "$USER" | grep -qw docker; then
    USER_IN_GROUP=true
    log_ok "Usuário '$USER' já pertence ao grupo 'docker'."
else
    sudo usermod -aG docker "$USER"
    log_ok "Usuário '$USER' adicionado ao grupo 'docker'."
fi

# Ajustar permissões do socket do Docker e ~/.docker
if [[ -S /var/run/docker.sock ]]; then
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi

if [[ -d "$HOME/.docker" ]]; then
    sudo chown -R "$USER":"$USER" "$HOME/.docker" 2>/dev/null || true
    sudo chmod -R g+rwx "$HOME/.docker" 2>/dev/null || true
fi

# ──────────────────────────────────────────────────
# 6. Iniciar e Habilitar o Serviço
# ──────────────────────────────────────────────────
log_info "Verificando serviço do Docker (systemd)..."

if ! systemctl is-enabled docker.service &>/dev/null; then
    sudo systemctl enable docker.service >/dev/null 2>&1
    sudo systemctl enable containerd.service >/dev/null 2>&1
    log_ok "Docker habilitado para iniciar no boot."
else
    log_ok "Docker já habilitado na inicialização."
fi

if ! systemctl is-active docker.service &>/dev/null; then
    log_info "Iniciando serviço do Docker..."
    sudo systemctl start docker
    log_ok "Serviço Docker iniciado."
else
    log_ok "Serviço Docker já está em execução."
fi

# ──────────────────────────────────────────────────
# 7. Validação Final
# ──────────────────────────────────────────────────
echo ""
log_info "Executando teste de integridade..."

DOCKER_FINAL_VER="$(docker --version 2>/dev/null || sudo docker --version 2>/dev/null || echo 'indisponível')"
COMPOSE_FINAL_VER="$(docker compose version 2>/dev/null || sudo docker compose version 2>/dev/null || echo 'indisponível')"

log_ok "Docker:         $DOCKER_FINAL_VER"
log_ok "Docker Compose: $COMPOSE_FINAL_VER"

# Teste com hello-world
if sg docker -c "docker run --rm hello-world" >/dev/null 2>&1 || sudo docker run --rm hello-world >/dev/null 2>&1; then
    log_ok "Teste do container 'hello-world': SUCESSO!"
else
    log_warn "Não foi possível rodar o container de teste. Verifique sua conexão à internet."
fi

# ──────────────────────────────────────────────────
# 8. Resumo e Instruções
# ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           TUDO PRONTO PARA AS AULAS!                 ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "║                                                      ║"
echo -e "║  ${BOLD}Para subir o banco TechStore e o phpMyAdmin:${NC}        ║"
echo -e "║     ${CYAN}./iniciar.sh${NC}                                     ║"
echo -e "║     ${CYAN}(ou docker compose up -d)${NC}                        ║"
echo -e "║                                                      ║"
echo -e "║  ${BOLD}Acesse no navegador:${NC}                                ║"
echo -e "║     ${CYAN}http://localhost:8080${NC} (phpMyAdmin)               ║"
echo -e "║     ${CYAN}http://localhost:8081${NC} (Excalidraw)               ║"
echo -e "║                                                      ║"
if [ "$USER_IN_GROUP" = false ]; then
echo -e "║  ${YELLOW}DICA:${NC} Se abrir um NOVO terminal e der erro:         ║"
echo -e "║  Execute: ${BOLD}newgrp docker${NC} ou faça logout/login.         ║"
fi
echo -e "║                                                      ║"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Se executado interativamente no terminal, ativar grupo docker
if [ -t 0 ]; then
    log_info "Ativando grupo 'docker' na sessão atual..."
    exec sg docker -c "bash"
fi
