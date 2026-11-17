#!/usr/bin/env bash
#
# parar.sh — Para todos os containers do banco relacional (sem apagar dados)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if docker info >/dev/null 2>&1; then
    docker compose down
elif sg docker -c "docker info" >/dev/null 2>&1; then
    sg docker -c "docker compose down"
else
    sudo docker compose down
fi

echo "Containers do banco relacional pausados com sucesso."
