#!/usr/bin/env bash
# Valida o back-end implantado contra o Oracle de verdade: exercita
# REST -> Java -> JDBC -> packages, Dynamic SQL e triggers.
# Espera uma base recem-instalada (00_instalar.sql).
# Uso: deploy/smoke_test.sh <url-base> <relatorio.md>
set -uo pipefail

base="${1:-http://localhost:8080}"
relatorio="${2:-smoke_test.md}"
mkdir -p "$(dirname "$relatorio")"
resposta="$(mktemp)"
trap 'rm -f "$resposta"' EXIT
ok=0
falhas=0

{
  echo "# Smoke test - $base"
  echo
  echo "| Resultado | Verificação | HTTP | Esperado |"
  echo "|---|---|---|---|"
} > "$relatorio"

# verificar <nome> <status esperado> <trecho esperado ou ""> <token ou ""> <metodo> <rota> [corpo]
verificar() {
  local nome="$1" esperado="$2" trecho="$3" token="$4" metodo="$5" rota="$6" corpo="${7:-}"
  local args=(-s -m 30 -o "$resposta" -w '%{http_code}' -X "$metodo")
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$corpo" ] && args+=(-H 'Content-Type: application/json' -d "$corpo")

  local status
  status="$(curl "${args[@]}" "$base$rota")"

  if [ "$status" = "$esperado" ] && { [ -z "$trecho" ] || grep -qF "$trecho" "$resposta"; }; then
    ok=$((ok + 1))
    echo "| ✅ OK | $nome | $status | $esperado |" >> "$relatorio"
    echo "[OK]    $nome ($status)"
  else
    falhas=$((falhas + 1))
    echo "| ❌ FALHA | $nome | $status | $esperado |" >> "$relatorio"
    echo "[FALHA] $nome: HTTP $status, esperado $esperado${trecho:+ com '$trecho'}"
    head -c 500 "$resposta"; echo
  fi
}

login() {
  curl -s -m 30 -X POST -H 'Content-Type: application/json' \
    -d "{\"nomeUser\":\"$1\",\"senhaUser\":\"$2\"}" "$base/auth/usuarios/login" \
    | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p'
}

verificar "Swagger publica os novos endpoints" 200 '/oracle/pedidos/busca' "" GET /v3/api-docs
verificar "Rota Oracle sem token é recusada" 403 "" "" GET /oracle/pedidos

admin="$(login admin admin123)"
joao="$(login joao 123456)"
[ -n "$admin" ] && [ -n "$joao" ] || { echo "Falha no login"; exit 1; }

verificar "H2 da Fase 5 continua funcionando" 200 'LM-2026-0001' "$admin" GET /pedidos
verificar "View com risco calculado pelo package" 200 '"riscoNivel":"CRITICO"' "$admin" GET /oracle/pedidos

verificar "Dynamic SQL: filtro por status" 200 'LM-2026-0002' "$admin" GET '/oracle/pedidos/busca?status=ATRASADO'
verificar "Dynamic SQL: filtros combinados e ordem" 200 'LM-2026-0005' "$admin" GET '/oracle/pedidos/busca?regiao=leste&nivel=MEDIO&ordenarPor=distancia&direcao=ASC'
verificar "Dynamic SQL: injection na ordenação é recusada" 400 "" "$admin" GET '/oracle/pedidos/busca?ordenarPor=ID_PEDIDO%3BDROP%20TABLE%20T_SH_PEDIDO'
verificar "Dynamic SQL: injection no filtro não retorna dados" 200 '[]' "$admin" GET '/oracle/pedidos/busca?regiao=%27%20OR%20%271%27%3D%271'
verificar "Parâmetro numérico inválido vira 400" 400 "" "$admin" GET '/oracle/pedidos/busca?scoreMin=abc'
verificar "Dynamic SQL: resumo por parceiro" 200 'Total Express' "$admin" GET '/oracle/pedidos/resumo?dimensao=parceiro'
verificar "Dynamic SQL: dimensão inválida é recusada" 400 "" "$admin" GET '/oracle/pedidos/resumo?dimensao=NR_CPF'

verificar "PKG_SH_RISCO: recálculo do pedido 2" 200 '"riscoNivel":"CRITICO"' "$admin" POST /oracle/entregas/2/recalcular-risco
verificar "PKG_SH_RISCO: pedido inexistente" 404 "" "$admin" POST /oracle/entregas/999/recalcular-risco

verificar "PKG_SH_IOT: leitura crítica gera alerta" 201 '"alertasGerados":' "$admin" POST /oracle/sensores/1/leituras '{"valor":60}'
verificar "PKG_SH_IOT: alertas abertos" 200 '"status":"ABERTO"' "$admin" GET '/oracle/alertas?status=ABERTO'

alerta="$(sed -n 's/^\[{"id":\([0-9]*\).*/\1/p' "$resposta")"
verificar "Resolver alerta exige ADMIN" 403 "" "$joao" POST "/oracle/alertas/$alerta/resolver"
verificar "PKG_SH_IOT: resolver alerta" 204 "" "$admin" POST "/oracle/alertas/$alerta/resolver"
verificar "PKG_SH_IOT: alerta inexistente" 404 "" "$admin" POST /oracle/alertas/999999/resolver
verificar "Trigger: auditoria registrou a resolução" 200 '"statusNovo":"RESOLVIDO"' "$admin" GET "/oracle/alertas/auditoria?alertaId=$alerta"

verificar "PKG_SH_USUARIO: relatório" 200 'Maria Aparecida Lima' "$admin" POST /oracle/relatorios/usuarios

{
  echo
  echo "**Resultado: $ok OK, $falhas falha(s).**"
} >> "$relatorio"
echo "=== Smoke test: $ok OK, $falhas falha(s) ==="
[ "$falhas" -eq 0 ]
