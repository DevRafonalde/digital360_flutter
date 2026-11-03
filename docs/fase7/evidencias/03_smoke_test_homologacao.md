# Smoke test - http://localhost:8080

| Resultado | Verificação | HTTP | Esperado |
|---|---|---|---|
| ✅ OK | Swagger publica os novos endpoints | 200 | 200 |
| ✅ OK | Rota Oracle sem token é recusada | 403 | 403 |
| ✅ OK | H2 da Fase 5 continua funcionando | 200 | 200 |
| ✅ OK | View com risco calculado pelo package | 200 | 200 |
| ✅ OK | Dynamic SQL: filtro por status | 200 | 200 |
| ✅ OK | Dynamic SQL: filtros combinados e ordem | 200 | 200 |
| ✅ OK | Dynamic SQL: injection na ordenação é recusada | 400 | 400 |
| ✅ OK | Dynamic SQL: injection no filtro não retorna dados | 200 | 200 |
| ✅ OK | Parâmetro numérico inválido vira 400 | 400 | 400 |
| ✅ OK | Dynamic SQL: resumo por parceiro | 200 | 200 |
| ✅ OK | Dynamic SQL: dimensão inválida é recusada | 400 | 400 |
| ✅ OK | PKG_SH_RISCO: recálculo do pedido 2 | 200 | 200 |
| ✅ OK | PKG_SH_RISCO: pedido inexistente | 404 | 404 |
| ✅ OK | PKG_SH_IOT: leitura crítica gera alerta | 201 | 201 |
| ✅ OK | PKG_SH_IOT: alertas abertos | 200 | 200 |
| ✅ OK | Resolver alerta exige ADMIN | 403 | 403 |
| ✅ OK | PKG_SH_IOT: resolver alerta | 204 | 204 |
| ✅ OK | PKG_SH_IOT: alerta inexistente | 404 | 404 |
| ✅ OK | Trigger: auditoria registrou a resolução | 200 | 200 |
| ✅ OK | PKG_SH_USUARIO: relatório | 200 | 200 |

**Resultado: 20 OK, 0 falha(s).**
