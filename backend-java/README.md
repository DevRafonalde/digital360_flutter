# Smart HAS / Digital 360 — Backend (Spring Boot)

API REST em Java 17 + Spring Boot 3, construida para a Fase 5 da FIAP (Parte 2:
"Back-end Escalavel com Spring Boot"). Implementa **o contrato completo** que o
app Flutter consome em `lib/data/services/api_service.dart`: autenticacao
(login, registro com LGPD, refresh), trilhas de curso (oficiais e comunitarias),
guia de servicos, a camada **AI Logistics Extension** (pedidos, risco,
reagendamento, feedback, assistente), e as areas de comunidade — fórum,
gamificação, modo cuidador, indicação de amigos, marketplace de tutores,
recomendações, tendências, painel de impacto e exclusão de conta.

## Por que um backend novo, se o projeto ja tem um backend real em Python?
O repositorio do app (`digital360_flutter`, GitHub `DevRafonalde/digital360_flutter`)
ja tem um backend real em Python/FastAPI (`backend/` naquele repo) cobrindo o
mesmo dominio. Este backend Spring Boot **nao substitui** o Python — ele existe
porque a Fase 5 pede explicitamente Java + Spring Boot. Os dois implementam o
mesmo contrato de API de formas independentes; podem coexistir (o app mobile
pode continuar em produção no Python, e este Java servir o Swagger + o
dashboard Angular desta entrega), ou o time pode decidir convergir para um só
mais adiante — ver a seção de roadmap na documentação da Fase 5.

**Contrato verificado contra o codigo atual do app** (nao contra uma versao
antiga): nomes de campo como `senhaUser` (nao `senha`), `impactoClima` no
recalculo de risco, e o corpo de `/auth/usuarios/registrar` (`aceitouPolitica`
obrigatorio, `codigoIndicacao` opcional) foram conferidos linha a linha contra
`api_service.dart`, `db_models.py` e `heuristics.py` do backend Python.

## Stack
- Java 17, Spring Boot 3.3 (Web, Data JPA, Security, Validation)
- Banco H2 em arquivo (`./data/smarthas.mv.db`) — sem dependencia de servidor externo
- Autenticacao stateless com JWT (io.jsonwebtoken)
- Autorizacao por perfil (`ADMIN`/`USUARIO`) e por atributo (`isTutor`, dono do
  recurso) onde o dominio exige — ex.: só o próprio usuário vê suas
  recomendações/gamificação, só um tutor publica curso comunitário
- Documentacao OpenAPI/Swagger via springdoc

## Validado de verdade (rodando, não só por leitura de código)
`mvn compile` e `mvn spring-boot:run` executados de fato (JDK 21 do Android
Studio + Maven 3.9.14). Fluxos exercitados via `curl` num servidor local real,
incluindo dois bugs reais encontrados e corrigidos nesse processo
(`LazyInitializationException` em `topicosModulos` — corrigido com fetch
`EAGER`; e um corpo JSON malformado que devolvia 500 em vez de 400 — corrigido
no `GlobalExceptionHandler`):
- Login (`admin`/`admin123`), senha errada → 401, registro sem aceitar a
  política de privacidade → 422, código de indicação credita quem indicou.
- CRUD de cursos/serviços/pedidos, recálculo de risco com `impactoClima`,
  reagendamento, autorização por perfil (`joao` USUARIO recebe 403 tentando
  criar curso oficial; sem token recebe 403).
- **Cursos comunitários**: `joao` (com `isTutor=true`) gera um rascunho por
  template, publica um curso com `topicosModulos`, e ele aparece em `GET
  /cursos` (público) e em `GET /cursos/meus`; um usuário sem `isTutor` recebe
  403 tentando publicar.
- **Eventos + recomendações + gamificação**: registrar um evento
  `curso_concluido` reflete corretamente em `GET /gamificacao/joao/resumo`
  (`cursosConcluidos: 1`, `pontos: 110`) e no ranking; `GET
  /recomendacoes/joao` funciona para o próprio usuário e dá 403 para outro.
- **Fórum**: criar pergunta, listar, responder — nomes de autor resolvidos
  corretamente.
- **Cuidador**: vincular por código (nomeUser), listar vínculos, ver resumo do
  idoso vinculado; usuário sem vínculo recebe 403.
- **Marketplace de tutores**: avaliar um curso, `GET /tutores/joao` retorna
  `mediaAvaliacao: 5.0` depois da avaliação.
- **LGPD**: `DELETE /perfil/conta` remove o usuário de verdade — login
  seguinte com as mesmas credenciais retorna 401.
- Preflight CORS de `http://localhost:4200` (dashboard) e `/v3/api-docs`
  (Swagger) validados.

## Como rodar localmente
Pre-requisito: JDK 17+ e Maven instalados (`java -version`, `mvn -version`).

```bash
cd backend-java
mvn spring-boot:run
```

A API sobe em `http://localhost:8080`. Na primeira execução, o `DataSeeder`
popula usuários e dados de demonstração (`admin`/`admin123` como ADMIN, `joao`/
`123456` como USUARIO com `isTutor=true`, para já poder demonstrar o fluxo
comunitário sem precisar chamar `/perfil/tornar-tutor` primeiro).

- Swagger UI: http://localhost:8080/swagger-ui.html
- Console H2 (dev): http://localhost:8080/h2-console (JDBC URL `jdbc:h2:file:./data/smarthas`, user `sa`, senha em branco)

## Usuarios de demonstracao
| nomeUser | senha    | perfil  | isTutor |
|----------|----------|---------|---------|
| admin    | admin123 | ADMIN   | não     |
| joao     | 123456   | USUARIO | sim     |

## Endpoints

### Autenticação e perfil
| Metodo | Rota | Auth | Descricao |
|---|---|---|---|
| POST | /auth/usuarios/login | publico | Login (`nomeUser` + `senhaUser`) |
| POST | /auth/usuarios/registrar | publico | Cadastro (exige `aceitouPolitica=true`; credita `codigoIndicacao`) |
| POST | /auth/refresh | publico | Renova o access token |
| POST | /perfil/tornar-tutor | Bearer | Auto-atribuição de tutor, sem fila |
| GET | /indicacoes/minhas | Bearer | Código de indicação e total de indicados |
| DELETE | /perfil/conta | Bearer | Exclusão da própria conta (LGPD) |

### Cursos, serviços e AI Logistics (núcleo)
| Metodo | Rota | Auth | Descricao |
|---|---|---|---|
| GET | /cursos | Bearer | Lista trilhas publicadas |
| GET | /cursos/meus | Bearer | Cursos do próprio tutor (qualquer status) |
| POST | /cursos | Bearer | ADMIN cadastra oficial, ou tutor publica comunitário |
| POST | /cursos/gerar-rascunho | Bearer (tutor) | Rascunho de módulos por template |
| PUT/DELETE | /cursos/{id} | Bearer ADMIN | Editar/remover do catálogo |
| GET | /servicos | Bearer | Guia de serviços públicos |
| POST/PUT/DELETE | /servicos[/{id}] | Bearer ADMIN | CRUD do guia |
| GET | /pedidos | Bearer | Pedidos logísticos monitorados |
| POST/PUT/DELETE | /pedidos[/{id}] | Bearer ADMIN | CRUD de pedidos |
| POST | /entregas/{id}/recalcular-risco | Bearer | Risco de atraso (`impactoClima` opcional) |
| POST | /pedidos/{id}/reagendar | Bearer | Reagenda uma entrega |
| POST | /feedback-entrega | Bearer | Feedback pós-entrega |
| POST | /assistente-logistico/pergunta | Bearer | Assistente por regras |

### Comunidade, gamificação e inteligência
| Metodo | Rota | Auth | Descricao |
|---|---|---|---|
| POST | /eventos | Bearer | Registra uso (alimenta recomendação/tendências/gamificação) |
| GET | /recomendacoes/{userId} | Bearer (dono) | Top 3 recomendações heurísticas |
| GET | /tendencias | Bearer | Picos de uso por categoria (7 dias vs. histórico) |
| POST/GET | /forum/perguntas | Bearer | Criar/listar perguntas |
| GET | /forum/perguntas/{id} | Bearer | Detalhe + respostas |
| POST | /forum/perguntas/{id}/respostas | Bearer | Responder |
| GET | /gamificacao/{userId}/resumo | Bearer (dono) | Cursos concluídos, sequência, pontos |
| GET | /gamificacao/ranking | Bearer | Top 10 |
| GET | /metricas/impacto | Bearer | Números agregados da base atual |
| POST | /cuidador/vincular | Bearer | Vínculo somente-leitura com um idoso |
| GET | /cuidador/vinculos | Bearer | Vínculos do cuidador |
| GET | /cuidador/{idosoId}/resumo | Bearer (com vínculo) | Progresso do idoso |
| POST | /cursos/{id}/avaliar | Bearer | Avalia um curso |
| GET | /cursos/{id}/avaliacoes | Bearer | Avaliações de um curso |
| GET | /tutores/{autorId} | Bearer | Perfil público do tutor |

## Ligar o app Flutter neste backend
Em `digital360_flutter/lib/core/constants/api_constants.dart`:
```dart
static const bool useMock = false;
static const String baseUrl = 'http://10.0.2.2:8080'; // emulador Android
// ou http://localhost:8080 rodando Flutter Web na mesma maquina do backend
```
Com a cobertura completa, todas as telas do app (incluindo Comunidade/Fórum,
Gamificação, Cuidador, Indicação, Recomendações, Tendências e exclusão de
conta) funcionam apontando para este backend — não só o núcleo.

## Ligar o dashboard Angular neste backend
Já vem configurado em `dashboard/src/environments/environment.ts` apontando
para `http://localhost:8080`.
