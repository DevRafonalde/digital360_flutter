#!/usr/bin/env bash
# Compila o app Flutter para web e serve em http://localhost:5000.
# So precisa de Docker: nao exige Flutter instalado na maquina.
# A primeira execucao baixa a imagem do Flutter (cerca de 4,5 GB) e leva
# alguns minutos. Pare o app com: docker rm -f smarthas-app-web
#
# No app, escolha Configuracoes -> Conexao (avancado) -> Java para usar o
# back-end de deploy/deploy_homolog.sh em http://localhost:8080.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash no Windows: nao converter caminhos do container

raiz="$(cd "$(dirname "$0")/.." && pwd)"
# Git Bash devolve /c/...; o Docker Desktop no Windows espera C:/...
if command -v cygpath > /dev/null; then raiz="$(cygpath -m "$raiz")"; fi

docker run --rm -m 3g \
  -v "$raiz:/src:ro" \
  -v smarthas-pub:/root/.pub-cache \
  -v smarthas-app-web:/out \
  ghcr.io/cirruslabs/flutter:3.44.0 \
  bash -c 'mkdir /app && cd /src \
    && tar cf - --exclude=build --exclude=.dart_tool --exclude=backend --exclude=backend-java \
         --exclude=dashboard --exclude=docs --exclude=database-oracle --exclude=relatorios --exclude=.git . \
       | tar xf - -C /app \
    && cd /app && flutter pub get > /dev/null \
    && flutter build web --release --no-web-resources-cdn \
    && rm -rf /out/* && cp -r build/web/. /out/'

docker rm -f smarthas-app-web > /dev/null 2>&1 || true
docker run -d --name smarthas-app-web -p 5000:80 \
  -v smarthas-app-web:/usr/share/nginx/html:ro nginx:alpine > /dev/null

echo "App em http://localhost:5000"
