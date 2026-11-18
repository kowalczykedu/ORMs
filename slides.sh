#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIDES_FILE="$SCRIPT_DIR/docs/slides-exemplo.html"

if [ ! -f "$SLIDES_FILE" ]; then
  echo "Erro: arquivo não encontrado em $SLIDES_FILE" >&2
  exit 1
fi

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$SLIDES_FILE" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$SLIDES_FILE"
elif command -v powershell.exe >/dev/null 2>&1; then
  WIN_PATH="$(cygpath -w "$SLIDES_FILE" 2>/dev/null || wslpath -w "$SLIDES_FILE" 2>/dev/null || echo "$SLIDES_FILE")"
  powershell.exe -NoProfile -Command "Start-Process -FilePath '$WIN_PATH'" >/dev/null 2>&1
elif command -v cmd.exe >/dev/null 2>&1; then
  WIN_PATH="$(cygpath -w "$SLIDES_FILE" 2>/dev/null || wslpath -w "$SLIDES_FILE" 2>/dev/null || echo "$SLIDES_FILE")"
  cmd.exe /c start "" "$WIN_PATH"
else
  echo "Abra manualmente no navegador: file://$SLIDES_FILE"
fi
