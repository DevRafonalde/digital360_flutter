# Digital 360 — AI Logistics Extension API

Backend real (não mock) da camada **AI Logistics Extension**, do projeto Smart HAS / Digital 360
(Enterprise Challenge Leroy Merlin, FIAP). Implementa o contrato descrito em
[`CONTRATO_APIS_AI_LOGISTICS.md`](CONTRATO_APIS_AI_LOGISTICS.md). Fica dentro deste repositório
Flutter (pasta `backend/`), por ser a extensão de um único projeto — ver o
[README principal](../README.md) para a visão geral do app.

## Por que este backend existe

Nas entregas anteriores, a camada AI Logistics era descrita em documentação (recomendação,
detecção de sazonalidade, assistente) mas só existia mockada no app Flutter. Este serviço
implementa essas regras **de verdade**, em Python, para que o app possa apontar para um backend
real (`ApiConstants.useMock = false`) e a documentação deixe de descrever algo que não existe em
código.

## Persistência e autenticação reais

Este backend tem **seu próprio cadastro de usuários, login e autenticação JWT** — não depende
mais de nenhum outro serviço para emitir token. Senhas são armazenadas com hash (`bcrypt`), nunca
em texto puro. Pedidos, cursos, eventos e feedbacks ficam num banco **SQLite real**
(`app/data/digital360.db`, criado automaticamente e nunca versionado no git) — reiniciar o
servidor não apaga mais nada.

Cada endpoint autenticado agora sabe **de verdade** quem é o usuário (o token carrega a
identidade, verificada por assinatura) — por exemplo, `GET /recomendacoes/{userId}` retorna 403
se você tentar consultar as recomendações de outra pessoa, e `POST /eventos` sempre grava o
evento em nome de quem está logado, não de um `userId` que o cliente informa livremente. Essas
duas lacunas existiam nas versões anteriores deste serviço e ficavam documentadas aqui como
limitação consciente — agora estão resolvidas.

## Escopo — MVP heurístico, por decisão consciente

Seguindo a orientação da mentoria Leroy Merlin ("comece simples, escale com consistência"), o
motor de recomendação/risco é **baseado em regras**, não em Machine Learning treinado. Isso é uma
escolha deliberada, não uma limitação escondida:
- Recomendação: ranking por frequência de uso + novidade (não visitado há 14+ dias) + nível.
- Detecção de sazonalidade: comparação estatística (média/desvio-padrão, `statistics` da stdlib)
  entre o volume recente de uma categoria e sua média histórica.
- Assistente logístico: consulta o **risco real** do pedido (não só palavras-chave) antes de responder.

A evolução para modelos treinados com dados reais (scikit-learn, séries temporais com pandas) é o
próximo passo planejado — ver seção "Evolução" abaixo — e não está simulada aqui.

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/usuarios/registrar` | Cadastra um usuário (senha com hash, exige aceite da política de privacidade) |
| POST | `/auth/usuarios/login` | Login — retorna access token + refresh token (JWT reais) |
| POST | `/auth/refresh` | Renova o access token a partir de um refresh token válido |
| GET | `/pedidos` | Lista os pedidos monitorados |
| GET | `/pedidos/{id}/entrega` | Detalhe logístico de um pedido |
| POST | `/entregas/{id}/recalcular-risco` | Recalcula o score de risco (heurística real, considera `impactoClima`) |
| POST | `/pedidos/{id}/reagendar` | Reagenda a entrega (ação recomendada pelo motor de risco) |
| POST | `/assistente-logistico/pergunta` | Assistente que consulta o risco real do pedido |
| POST | `/feedback-entrega` | Registra avaliação do cliente (nota 1-5) |
| POST | `/eventos` | Registra evento de uso (alimenta a recomendação) — identidade vem do token |
| GET | `/recomendacoes/{userId}` | Top 3 recomendações heurísticas — só para o próprio usuário (403 caso contrário) |
| GET | `/tendencias` | Categorias em alta (detecção de picos/sazonalidade) |
| GET | `/cursos` | Lista os cursos publicados — oficiais e comunitários |
| POST | `/perfil/tornar-tutor` | Auto-atribui o papel de tutor ao usuário logado (sem fila de aprovação) |
| POST | `/cursos/gerar-rascunho` | Estrutura inicial de módulos por template heurístico (só tutores, 403 caso contrário) |
| POST | `/cursos` | Cria e publica direto um curso comunitário (só tutores, 403 caso contrário) |
| GET | `/cursos/meus` | Lista os cursos do próprio tutor (inclui rascunhos) |
| POST | `/forum/perguntas` | Publica uma pergunta no fórum da comunidade |
| GET | `/forum/perguntas` | Lista as perguntas (mais recentes primeiro) |
| GET | `/forum/perguntas/{id}` | Detalhe da pergunta com todas as respostas |
| POST | `/forum/perguntas/{id}/respostas` | Responde uma pergunta |
| GET | `/gamificacao/{userId}/resumo` | Cursos concluídos, sequência de dias e pontos — só do próprio usuário (403 caso contrário) |
| GET | `/gamificacao/ranking` | Top 10 usuários por pontos |
| GET | `/metricas/impacto` | Números agregados da base atual (usuários, cursos concluídos/publicados, perguntas) |
| POST | `/cuidador/vincular` | Cuidador se vincula a um idoso pelo código (nomeUser) — vínculo direto, sem fila |
| GET | `/cuidador/vinculos` | Lista os idosos vinculados ao cuidador logado |
| GET | `/cuidador/{idosoId}/resumo` | Progresso do idoso (somente leitura) — só se houver vínculo (403 caso contrário) |
| GET | `/indicacoes/minhas` | Código de indicação (o próprio nomeUser) e total de indicações |
| POST | `/cursos/{id}/avaliar` | Avalia um curso (nota 1-5 + comentário opcional) |
| GET | `/cursos/{id}/avaliacoes` | Lista as avaliações de um curso |
| GET | `/tutores/{autorId}` | Perfil público do tutor: cursos publicados e média de avaliação |
| DELETE | `/perfil/conta` | Exclui a própria conta (LGPD) — apaga rascunhos, orfaniza cursos publicados |

### LGPD — exclusão da própria conta

`DELETE /perfil/conta` apaga a conta do usuário logado. Rascunhos de curso do próprio
tutor são apagados (nunca chegaram a existir para mais ninguém); cursos **já publicados**
ficam órfãos (`autorId=null`) em vez de apagados — remover o registro quebraria o
catálogo de quem já estuda por eles. Vínculos de cuidador (nos dois sentidos) são
removidos. Perguntas/respostas/avaliações permanecem no histórico, mas passam a exibir
"Anônimo" como autor (o relacionamento com o usuário apagado simplesmente não resolve
mais nada).

### Modo cuidador, indicação e marketplace de tutores

O **modo cuidador** é estritamente somente-leitura: o vínculo (`POST /cuidador/vincular`,
usando o `nomeUser` do idoso como código de convite) só dá acesso a um resumo agregado de
progresso — o cuidador nunca age em nome do idoso, que mantém sua própria conta e login.
A **indicação** usa o próprio `nomeUser` como código (já único, sem gerar nada novo); o
registro de um novo usuário credita silenciosamente quem indicou, sem revelar se um
código é válido antes do cadastro. O **marketplace de tutores** (avaliação de cursos +
perfil público do tutor) é extensão direta da Fase 3 — a nota é sempre 1-5, validada no
servidor.

### Fórum, gamificação e painel de impacto

O fórum é aberto a qualquer usuário autenticado — perguntar e responder não exigem o
papel de tutor. A gamificação (`/gamificacao/*`) é calculada a partir dos eventos de uso
já registrados via `POST /eventos`: concluir um curso no app dispara um evento
`tipo=curso_concluido`, e `heuristics.py::calcular_sequencia_dias` calcula a sequência de
dias consecutivos de uso — **outra heurística por regra fixa**, não um sistema de
recomendação treinado. `GET /metricas/impacto` retorna números da base de dados atual
(ambiente de demonstração) e diz isso explicitamente no campo `observacao` — não é uma
alegação de escala real de usuários.

### Cursos comunitários (Nível 2+4)

Qualquer usuário pode se auto-atribuir o papel de tutor (`POST /perfil/tornar-tutor`,
sem fila de aprovação — decisão consciente para o MVP). Como tutor, pode gerar uma
estrutura inicial de módulos via `POST /cursos/gerar-rascunho` — **um gerador por
template/regra fixa (`heuristics.py::gerar_rascunho_curso`), não IA generativa** (não há
chave de LLM disponível neste ambiente, e o projeto não simula uma). O resultado é só um
ponto de partida: o tutor revisa e edita antes de publicar com `POST /cursos`, que já
publica direto (`status=PUBLICADO`), sem moderação.

Todas as rotas (exceto `/`, `/auth/usuarios/registrar` e `/auth/usuarios/login`) exigem um
`Authorization: Bearer <access token>` válido — verificado de verdade (assinatura + expiração),
não apenas presença do header.

### Segurança — decisões conscientes que continuam de propósito

- **CORS restrito** por lista explícita de origens (`ALLOWED_ORIGINS`, variável de ambiente
  separada por vírgula), não mais `allow_origins=["*"]`.
- **`JWT_SECRET`** deve vir de variável de ambiente em qualquer ambiente que não seja
  desenvolvimento local — o código tem um fallback óbvio e sinalizado como inseguro só para o
  servidor subir sem configuração extra em demonstração.
- O motor de recomendação continua **heurístico** (ver seção acima) — decisão deliberada, não
  disfarçada de IA que não existe.

## Como rodar

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

Variáveis de ambiente opcionais (têm default de desenvolvimento se omitidas):
- `JWT_SECRET` — segredo de assinatura dos tokens (defina em qualquer ambiente real).
- `ALLOWED_ORIGINS` — origens liberadas por CORS, separadas por vírgula.
- `DATABASE_URL` — por padrão usa o arquivo `app/data/digital360.db`.

Documentação interativa (Swagger) em `http://localhost:8080/docs`.

Para o app Flutter apontar para este backend real, em
`lib/core/constants/api_constants.dart`:
```dart
static const bool useMock = false;
static const String baseUrl = 'http://10.0.2.2:8080'; // emulador Android
```

## Testes

```bash
pip install -r requirements-dev.txt
pytest -v
```
80 testes cobrindo a lógica de risco (incluindo impacto do clima), recomendação,
detecção de tendências, reagendamento, cadastro/login/refresh reais, autorização por usuário
(403 ao tentar acessar recurso de outra pessoa), cursos comunitários (auto-atribuição de tutor,
403 pra quem não é tutor, geração de rascunho, publicação direta, "meus cursos"), fórum
(criar pergunta, responder, 404 em pergunta inexistente), gamificação (resumo, ranking,
sequência de dias), modo cuidador (vínculo, duplicidade, 403 sem vínculo), indicação
(contador incrementado, código inexistente não quebra o cadastro), marketplace de tutores
(avaliação, perfil público, média) e exclusão de conta (rascunho apagado, curso publicado
orfanizado, vínculos de cuidador removidos, login não funciona mais) e os endpoints HTTP.
Cada teste roda numa transação de banco isolada (SQLite em memória) que é desfeita ao
final — nenhum teste depende de estado deixado por outro.

## Evolução planejada (próximo ciclo)

| Horizonte | Evolução |
|---|---|
| Depois | Substituir o motor de recomendação por filtragem colaborativa (scikit-learn) treinada com eventos reais de uso |
| Depois | NLP para classificação semântica das perguntas do assistente |
