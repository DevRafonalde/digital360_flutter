# Roteiro do vídeo — Consolidando o Smart HAS (máx. 5 min)

Publicar no YouTube como **Não listado** e testar o link em uma aba anônima.

## Antes de gravar

- [ ] Docker Desktop aberto e, na raiz do repositório: `bash deploy/deploy_homolog.sh`
- [ ] Swagger em http://localhost:8080/swagger-ui.html, login `admin`/`admin123` em `POST /auth/usuarios/login` e token em **Authorize**
- [ ] SQL Developer ou DBeaver em `localhost:1521/FREEPDB1` (`smarthas`/`smarthas`)
- [ ] App no ar: `bash deploy/app_web_docker.sh` e abra http://localhost:5000 no Chrome (não precisa ter Flutter instalado). Escolha **Java** em Configurações → Conexão (avançado). Login: `joao`/`123456`
- [ ] Aba **Actions** do GitHub aberta em uma execução concluída
- [ ] Gravação em 1080p, com o microfone testado

## 0:00 – 0:25 | Abertura (slide 1)
"Somos o grupo do Smart HAS — Digital 360: Eduardo, Otávio, Enzo, Rafael e Guilherme. Nesta etapa, consolidamos o banco Oracle e automatizamos a entrega do projeto."

## 0:25 – 0:50 | Visão geral (slide 2)
"Criamos quatro packages, duas triggers, consultas com Dynamic SQL e um pipeline de oito jobs, que vai do teste até o deploy."

## 0:50 – 1:15 | Packages (slide 3)
"As rotinas estavam soltas no schema. Agora cada assunto tem o seu package: risco, IoT, usuários e consultas."
No SQL Developer, abra a pasta **Packages** e mostre a especificação do `PKG_SH_RISCO`.

## 1:15 – 2:00 | Dynamic SQL (slide 4 + Swagger)
"O operador combina filtros em tempo real, e só os filtros informados entram no SQL."
1. `GET /oracle/pedidos/busca` com `regiao=leste` e `ordenarPor=distancia`.
2. `GET /oracle/pedidos/resumo` com `dimensao=parceiro`.
3. `GET /oracle/pedidos/busca` com `ordenarPor=ID_PEDIDO; DROP TABLE T_SH_PEDIDO` → HTTP 400: "a tentativa de SQL Injection é recusada".

## 2:00 – 2:45 | Triggers (slide 5 + banco)
1. Swagger: `POST /oracle/entregas/2/recalcular-risco` → CRITICO.
2. Swagger: `GET /oracle/alertas?status=ABERTO`, copie o `id` e chame `POST /oracle/alertas/{id}/resolver`.
3. Swagger: `GET /oracle/alertas/auditoria` → "a trigger registrou quem mudou, quando e de onde".
4. Banco:
   ```sql
   UPDATE T_SH_PEDIDO SET ST_PEDIDO = 'ENTREGUE' WHERE ID_PEDIDO = 2;
   COMMIT;
   SELECT ID_ALERTA, ST_ALERTA FROM T_SH_ALERTA WHERE ID_PEDIDO = 2;
   ```
   "Ao entregar o pedido, a outra trigger encerra os alertas abertos sozinha."

## 2:45 – 3:45 | Pipeline (slides 6 a 8 + GitHub)
1. Aba **Actions**: mostre o grafo dos jobs. "A imagem só é publicada se todas as camadas passarem."
2. Abra o job de deploy: "sobe um Oracle real, instala os objetos, sobe o back-end e roda o smoke test".
3. Mostre o resumo da execução e os artefatos `relatorio-*`: "cada execução deixa logs e relatórios".

## 3:45 – 4:35 | Resultados e app rodando (slide 9) — parte obrigatória
"Foram 47 testes PL/SQL, 17 testes JUnit, 85 testes do app e 22 verificações no smoke test, todos sem falhas."
Abra o app, faça login e navegue por Cursos e Logística. Abra o pedido LM-2026-0002 e toque em **Recalcular risco de entrega** → CRÍTICO, 100.

## 4:35 – 5:00 | Encerramento (slide 10)
"Agora temos regras organizadas, rastreabilidade e uma entrega repetível. Obrigado!"

> Se passar de 5 min, corte o passo 2 do Dynamic SQL e o passo 2 do pipeline.
