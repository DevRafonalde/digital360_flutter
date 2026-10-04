# Smart HAS - Fase 6: testa tudo no Docker Desktop
#   Oracle Free + scripts PL/SQL + mvn test/package do backend-java + endpoints /oracle/**
# Uso (PowerShell, na raiz do repositorio ou em qualquer pasta):
#   pwsh -ExecutionPolicy Bypass -File .\database-oracle\testar_no_docker.ps1          # tudo
#   pwsh -ExecutionPolicy Bypass -File .\database-oracle\testar_no_docker.ps1 sql      # so os scripts Oracle
#   pwsh -ExecutionPolicy Bypass -File .\database-oracle\testar_no_docker.ps1 api      # so as chamadas da API
# Logs em %USERPROFILE%\smarthas_teste_logs. API em http://localhost:8080 (Swagger: /swagger-ui.html),
# Oracle em localhost:1521/FREEPDB1 (smarthas/smarthas).
# Para parar:  docker rm -f smarthas-api oracle-free
$ErrorActionPreference = 'Continue'
$T = Split-Path -Parent $MyInvocation.MyCommand.Path      # database-oracle/
$R = Split-Path -Parent $T                                  # raiz do repositorio
$L = Join-Path $env:USERPROFILE 'smarthas_teste_logs'
New-Item -ItemType Directory -Force $L | Out-Null
function Log($m) { "$(Get-Date -Format HH:mm:ss) $m" | Tee-Object -Append -FilePath "$L\00_status.txt" }
Log "inicio | R=$R"
'{ "valor": 60.0 }' | Out-File -Encoding ascii "$L\leitura.json"
'{ "nomeUser": "admin", "senhaUser": "admin123" }' | Out-File -Encoding ascii "$L\login.json"

$etapa = $args[0]
if (-not $etapa) { $etapa = 'tudo' }

if ($etapa -in 'tudo','oracle') {
  docker network create smarthas 2>&1 | Out-Null
  docker rm -f oracle-free 2>&1 | Out-Null
  Log 'subindo Oracle Free'
  docker run -d --name oracle-free --network smarthas -p 1521:1521 -e ORACLE_PASSWORD=Fiap2026 -e APP_USER=smarthas -e APP_USER_PASSWORD=smarthas -v "${T}:/work:ro" gvenzl/oracle-free:slim-faststart 2>&1 | Out-File -Append "$L\00_status.txt"
  $ok = $false
  for ($i = 0; $i -lt 120; $i++) {
    if ((docker logs oracle-free 2>&1 | Out-String) -match 'DATABASE IS READY TO USE') { $ok = $true; break }
    Start-Sleep 5
  }
  Log "oracle pronto=$ok"
}

if ($etapa -in 'tudo','sql') {
  Log 'executando scripts SQL'
  $cmd = "cd /work && printf 'set echo on\nset linesize 220\nset pagesize 200\nset trimspool on\n@00_executar_tudo.sql\nprompt === USER_ERRORS ===\nselect name, type, line, position, text from user_errors order by name, sequence;\nexit\n' | sqlplus -s smarthas/smarthas@localhost/FREEPDB1"
  docker exec oracle-free bash -c $cmd 2>&1 | Out-File -Encoding utf8 "$L\02_sqlplus.txt"
  Log 'scripts SQL concluidos'
}

if ($etapa -in 'tudo','java') {
  docker rm -f smarthas-api 2>&1 | Out-Null
  Log 'mvn test + package (backend-java)'
  docker run --rm -v "${R}\backend-java:/src:ro" -v smarthas-m2:/root/.m2 -v smarthas-out:/out maven:3.9-eclipse-temurin-17 bash -c "rm -rf /app && cp -r /src /app && rm -rf /app/target /app/data && cd /app && mvn -B test && mvn -B -q -DskipTests package && cp target/backend-1.0.0.jar /out/app.jar && echo BUILD_JAR_OK" 2>&1 | Out-File -Encoding utf8 "$L\03_mvn.txt"
  Log 'subindo backend-java com ORACLE_ENABLED=true'
  docker run -d --name smarthas-api --network smarthas -p 8080:8080 -v smarthas-out:/out -w /tmp -e ORACLE_ENABLED=true -e ORACLE_URL=jdbc:oracle:thin:@oracle-free:1521/FREEPDB1 -e ORACLE_USER=smarthas -e ORACLE_PASSWORD=smarthas maven:3.9-eclipse-temurin-17 java -jar /out/app.jar 2>&1 | Out-File -Append "$L\00_status.txt"
  for ($i = 0; $i -lt 60; $i++) { if ((docker logs smarthas-api 2>&1 | Out-String) -match 'Started BackendApplication') { break }; Start-Sleep 3 }
  docker logs smarthas-api 2>&1 | Out-File -Encoding utf8 "$L\04_api_boot.txt"
}

if ($etapa -in 'tudo','java','api') {
  Log 'testando endpoints'
  $o = "$L\05_endpoints.txt"
  $login = curl.exe -s -X POST -H "Content-Type: application/json" --data-binary "@$L\login.json" http://localhost:8080/auth/usuarios/login
  $tok = ($login | ConvertFrom-Json).accessToken
  $auth = "Authorization: Bearer $tok"
  "### POST /auth/usuarios/login (admin) -> token obtido: $([bool]$tok)" | Out-File -Encoding utf8 $o
  function Chamar($titulo, [string[]]$curlArgs) {
    "`n### $titulo" | Out-File -Append -Encoding utf8 $o
    curl.exe -s -i @curlArgs 2>&1 | Out-File -Append -Encoding utf8 $o
  }
  Chamar 'GET /pedidos (Fase 5, H2 - regressao)' @('-H', $auth, 'http://localhost:8080/pedidos')
  Chamar 'GET /oracle/pedidos' @('-H', $auth, 'http://localhost:8080/oracle/pedidos')
  Chamar 'POST /oracle/entregas/2/recalcular-risco' @('-X', 'POST', '-H', $auth, 'http://localhost:8080/oracle/entregas/2/recalcular-risco')
  Chamar 'POST /oracle/sensores/1/leituras {valor:60}' @('-X', 'POST', '-H', $auth, '-H', 'Content-Type: application/json', '--data-binary', "@$L\leitura.json", 'http://localhost:8080/oracle/sensores/1/leituras')
  Chamar 'GET /oracle/alertas?status=ABERTO' @('-H', $auth, 'http://localhost:8080/oracle/alertas?status=ABERTO')
  Chamar 'POST /oracle/relatorios/usuarios' @('-X', 'POST', '-H', $auth, 'http://localhost:8080/oracle/relatorios/usuarios')
  Chamar 'POST /oracle/entregas/999/recalcular-risco (esperado 404)' @('-X', 'POST', '-H', $auth, 'http://localhost:8080/oracle/entregas/999/recalcular-risco')
  Chamar 'GET /oracle/alertas?status=XYZ (esperado 400)' @('-H', $auth, 'http://localhost:8080/oracle/alertas?status=XYZ')
  Chamar 'POST /oracle/sensores/99/leituras (esperado 404)' @('-X', 'POST', '-H', $auth, '-H', 'Content-Type: application/json', '--data-binary', "@$L\leitura.json", 'http://localhost:8080/oracle/sensores/99/leituras')
  Chamar 'GET /oracle/pedidos sem token (esperado 401/403)' @('http://localhost:8080/oracle/pedidos')
}
Log 'FIM'
