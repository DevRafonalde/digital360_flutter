#!/usr/bin/env bash
# Deploy na homologacao: sobe o Oracle, instala a camada PL/SQL, sobe o
# back-end e valida a integracao com o smoke test.
#   SMARTHAS_IMAGE  imagem do back-end (sem ela, usa a construida localmente)
#   RELATORIOS      pasta dos relatorios (padrao: relatorios/deploy)
# Para encerrar: docker compose -f deploy/docker-compose.homolog.yml down -v
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
cd "$raiz"
relatorios="${RELATORIOS:-$raiz/relatorios/deploy}"
mkdir -p "$relatorios"
compose=(docker compose -f deploy/docker-compose.homolog.yml)

coletar_logs() {
  "${compose[@]}" ps > "$relatorios/containers.txt" 2>&1 || true
  "${compose[@]}" logs --no-color api > "$relatorios/api.log" 2>&1 || true
  "${compose[@]}" logs --no-color oracle > "$relatorios/oracle.log" 2>&1 || true
}
trap coletar_logs EXIT

echo "==> [1/4] Subindo o Oracle"
"${compose[@]}" up -d --wait oracle

echo "==> [2/4] Instalando a camada PL/SQL"
bash deploy/oracle_aplicar.sh 00_instalar.sql "$relatorios/oracle_instalacao.log" > /dev/null

echo "==> [3/4] Subindo o back-end"
if [ -n "${SMARTHAS_IMAGE:-}" ]; then
  "${compose[@]}" up -d --no-build api
else
  "${compose[@]}" up -d --build api
fi

for _ in $(seq 1 60); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/v3/api-docs)" = "200" ] && break
  sleep 3
done

echo "==> [4/4] Validando a integracao"
bash deploy/smoke_test.sh http://localhost:8080 "$relatorios/smoke_test.md"

cat > "$relatorios/manifesto.txt" <<EOF
imagem: ${SMARTHAS_IMAGE:-smarthas-backend:local (build local)}
commit: $(git rev-parse HEAD)
data:   $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
echo "==> Deploy concluido. Relatorios em $relatorios"
