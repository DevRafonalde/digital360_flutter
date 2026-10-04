# Roteiro do vídeo — Fase 6 (máx. 5 min)
Smart HAS / Digital 360 • Banco de Dados na Sociedade 5.0
Publicar no YouTube como **Não listado** e testar o link em aba anônima.

## Antes de gravar (checklist)
- [ ] Rodar `database-oracle/testar_no_docker.ps1` (sobe Oracle + scripts + `backend-java` com a camada Oracle ligada). Depois rode `00_executar_tudo.sql` de novo para zerar os dados antes de gravar.
- [ ] `backend-java` no ar em http://localhost:8080 (Swagger em `/swagger-ui.html`, login `admin`/`admin123` → botão **Authorize**)
- [ ] App Flutter rodando (emulador ou Chrome) com o ambiente **Java** em Configurações → Conexão (avançado)
- [ ] SQL Developer ou DBeaver conectado em `localhost:1521/FREEPDB1` (`smarthas`/`smarthas`)
- [ ] Gravação: Win+G (Xbox Game Bar) ou OBS, 1080p, microfone testado

## 0:00 – 0:25 | Abertura (slide 1)
"Olá, somos o grupo do Smart HAS — Digital 360: Eduardo, Otávio, Enzo, Rafael e Guilherme. Nesta Fase 6, levamos a inteligência do sistema para o banco de dados Oracle, com PL/SQL integrado ao nosso back-end Java."

## 0:25 – 1:05 | O que mudou e arquitetura (slides 2 e 3)
"Antes, o cálculo de risco de entrega ficava só dentro do app. Agora ele roda no Oracle: o back-end Java da Fase 5 ganhou um pacote que chama as procedures via JDBC e o banco devolve o resultado. Uma regra, um lugar, com histórico de cada decisão. Criamos 11 tabelas, 4 functions, 3 procedures e 6 endpoints."

## 1:05 – 1:35 | Modelo de dados (slides 4 e 5)
"O modelo cobre inclusão digital, logística e IoT. Importamos dados simulados: 6 usuários, 5 pedidos e 5 sensores com 19 leituras, sendo 6 fora da faixa segura."

## 1:35 – 2:45 | Demonstração no Oracle (SQL Developer)
1. Mostrar as tabelas criadas e `SELECT` em `T_SH_PEDIDO`.
2. Rodar a consulta A1 do script 05: "a function FN_CALCULA_RISCO dá 100 para a tinta atrasada e sem estoque, nível CRITICO".
3. Rodar o bloco B1: "a procedure de sensores gerou 6 alertas". Mostrar `T_SH_ALERTA`.
4. Rodar o bloco B3 com DBMS_OUTPUT: "o relatório classifica cada usuário: a Ana está ENGAJADA, o Antônio é INICIANTE e precisa de tutoria".
5. Rodar um bloco da Parte C: "erros tratados com códigos padronizados".

## 2:45 – 4:00 | Demonstração do back-end + app (parte obrigatória: app rodando)
1. Swagger → **Authorize** com o token do admin → `GET /oracle/pedidos`: "esta lista vem da view do Oracle, já com o risco calculado pelas functions".
2. `POST /oracle/entregas/2/recalcular-risco` → CRITICO / score 100.
3. Voltar ao SQL Developer: `SELECT * FROM T_SH_RISCO_HIST ORDER BY ID_RISCO DESC;` → "a chamada REST virou um registro de auditoria no banco: REST → Java → JDBC → procedure".
4. Swagger: `POST /oracle/sensores/1/leituras` com `{"valor": 60}` → `alertasGerados: 1`. Depois `GET /oracle/alertas?status=ABERTO`.
5. `POST /oracle/entregas/999/recalcular-risco` → HTTP 404 com a mensagem da procedure.
6. **App rodando:** abrir o app (ambiente Java), fazer login e navegar por Cursos e Logística — "o mesmo back-end que atende o app agora também tem a camada Oracle".

## 4:00 – 4:40 | Melhorias e boas práticas (slides 7 a 9)
"Aplicamos arquitetura em camadas, transação controlada pela API, tradução dos erros ORA em HTTP e testes automatizados com JUnit e Mockito. No PL/SQL usamos cursor com FOR UPDATE, LOOP, IF, %TYPE e exceções nomeadas."

## 4:40 – 5:00 | Encerramento (slide 10)
"Próximos passos: autenticação JWT na API, painel administrativo de alertas e um job agendado no Oracle. Obrigado!"

> Se passar de 5 min: encurte a parte 1:05–1:35 e mostre só os passos 2, 3 e 4 do Oracle.
