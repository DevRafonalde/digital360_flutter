#!/usr/bin/env bash
# Executa um script de database-oracle/ no Oracle da homologacao.
# Para no primeiro erro de SQL, com codigo de saida diferente de zero.
# Uso: deploy/oracle_aplicar.sh <script.sql> <arquivo-de-log>
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash no Windows: nao converter /work

script="$1"
log="$2"
cd "$(dirname "$0")"
compose=(docker compose -f docker-compose.homolog.yml)

mkdir -p "$(dirname "$log")"
printf 'WHENEVER SQLERROR EXIT FAILURE\nWHENEVER OSERROR EXIT FAILURE\nSET LINESIZE 220\nSET PAGESIZE 200\nSET TRIMSPOOL ON\n@%s\nEXIT\n' "$script" \
  | "${compose[@]}" exec -T oracle bash -c \
      "cd /work && sqlplus -s \"\$APP_USER/\$APP_USER_PASSWORD@localhost/FREEPDB1\"" \
  | tee "$log"
