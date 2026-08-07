# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Unreleased]

### Added
- `AnalyticsService` (Firebase Analytics + Crashlytics), mesmo padrão defensivo já
  usado pro FCM em `NotificationService` — não verificável ponta-a-ponta neste ambiente
  (`google-services.json` é placeholder). Loga `login_realizado` e `curso_concluido` como
  demonstração de uso; captura erros não tratados via `FlutterError.onError` e
  `PlatformDispatcher.instance.onError`.
- Login biométrico (`BiometriaService`, pacote `local_auth`) — reautentica uma sessão
  **já salva** ao reabrir o app; não substitui o login por usuário/senha. Toggle em
  Configurações (só habilitado se o dispositivo suportar); se a confirmação falhar, a
  `SplashScreen` oferece "Tentar novamente" ou "Entrar com usuário e senha", sem apagar
  a sessão salva sozinha.
- Deep link de notificação: tocar num alerta de risco ALTO/CRÍTICO abre direto a tela do
  pedido. `NotificationService` ganhou um parâmetro `payload` e um callback
  `onNotificacaoTocada` — o serviço só repassa o payload, a navegação (via
  `navigatorKey` global) fica em `main.dart`, mantendo a camada de dados independente de UI.
- Bump do `flutter_local_notifications` (17→19.5.0, adiado desde a Fase 0 por ser um
  salto grande) — feito agora que o serviço já estava sendo mexido para o deep link.
  Verificado com `dart analyze` limpo e suíte completa passando.
- Histórico de buscas recentes no Guia de Serviços (`ServicosProvider.registrarBusca`),
  mesmo padrão de persistência local já usado pelos favoritos — chips clicáveis abaixo
  do campo de busca, com opção de limpar.
- Golden test do `RiskBadge` (`test/risk_badge_golden_test.dart`) — verificado estável
  em duas rodadas locais seguidas; documentado como execução local, não em CI
  compartilhado (fonte/DPI variam entre máquinas).
- Widget tests para `AssistenteScreen`, `TendenciasScreen`, `RecomendacoesScreen` e
  `ConfiguracoesScreen`; teste do `CpfInputFormatter` (a máscara aplicada durante a
  digitação, distinto do `cpfMascarado()` de exibição).
- `integration_test/app_test.dart`: teste ponta-a-ponta (login demo → Cursos → avançar
  progresso → Perfil → logout). Escrito e correto, mas não executável neste ambiente de
  desenvolvimento por restrições de infraestrutura (documentado no README com o mesmo
  princípio de honestidade já usado no projeto).
- Tema em 3 vias (sistema/claro/escuro) — `SettingsProvider.definirTema()` substitui o
  antigo switch binário claro/escuro; `ConfiguracoesScreen` ganha um `SegmentedButton`.
- Onboarding com passo inicial de perfil (idoso sozinho / cuidador / pessoa com
  deficiência), obrigatório para avançar, que personaliza a dica final do tour e fica
  salvo em `SharedPreferences` para uso futuro.
- `LibrasVideoPlaceholder`: gancho visual para vídeo em Libras nos cursos, com estado
  "em breve" — ainda não há vídeos reais de intérprete gravados, e isso é dito de forma
  explícita na tela. A pasta `assets/libras/` já fica preparada para recebê-los.
- Tela `PrivacidadeScreen` (Política de Privacidade) e checkbox obrigatório no cadastro
  (`aceitouPolitica`) — o backend já exigia esse campo desde a Fase 2, mas a UI de
  cadastro nunca o enviava; cadastros reais (não-mock) sempre falhariam com 422.
- `cpfMascarado()` em `cpf_utils.dart` — CPF exibido mascarado por padrão no Perfil
  ("123.***.**9-35"), com botão para revelar/ocultar.
- `DELETE /perfil/conta` (exclusão da própria conta, LGPD): apaga rascunhos do próprio
  tutor, orfaniza cursos já publicados (`autorId=null`), remove vínculos de cuidador nos
  dois sentidos. Botão "Excluir minha conta" no Perfil, com confirmação explícita.
- Modo cuidador: vínculo somente-leitura (`POST /cuidador/vincular`, código = nomeUser
  do idoso), `GET /cuidador/vinculos` e `GET /cuidador/{idosoId}/resumo` — o cuidador
  nunca age em nome do idoso, só acompanha o progresso agregado.
- Certificado de conclusão de curso em PDF (`CertificadoService`, pacotes `pdf` +
  `printing`, gerado só no cliente), oferecido no dialog de parabéns e na tela de
  detalhe do curso quando concluído.
- Indicação de amigos: código de indicação (o próprio nomeUser), `GET
  /indicacoes/minhas`, contador creditado no cadastro (`codigoIndicacao` opcional),
  compartilhamento via `share_plus` (share sheet genérico do SO, não um link direto de
  nenhum app específico).
- Cupom de recompensa simbólico (Leroy Merlin) exibido na tela de Conquistas ao atingir
  3 cursos concluídos — rotulado explicitamente como demonstração, sem backend de resgate.
- Marketplace de tutores: `POST /cursos/{id}/avaliar`, `GET /cursos/{id}/avaliacoes` e
  `GET /tutores/{autorId}` (perfil público com cursos e média de avaliação), integrados
  à tela de detalhe do curso.
- Novas telas Flutter `AcompanhamentoScreen`, `IndicacaoScreen` e `TutorPerfilScreen`,
  provider `CuidadorProvider`.
- Fórum de perguntas e respostas da comunidade (`POST/GET /forum/perguntas`,
  `POST /forum/perguntas/{id}/respostas`), aberto a qualquer usuário autenticado.
- Gamificação: `GET /gamificacao/{userId}/resumo` (cursos concluídos, sequência de dias,
  pontos) e `GET /gamificacao/ranking` (top 10). Concluir um curso no app agora dispara
  um evento `curso_concluido`; a sequência de dias é calculada por
  `heuristics.py::calcular_sequencia_dias` — outra heurística de regra fixa, não ML.
- Painel de impacto (`GET /metricas/impacto`): números agregados da base atual, com
  observação explícita de que são dados da demonstração, não uma métrica de escala real.
- Novas telas Flutter `ForumScreen`, `DetalhePerguntaScreen`, `ConquistasScreen` e
  `ImpactoScreen`, providers `ForumProvider` e `GamificacaoProvider`, widget `StatCard`,
  e 3 novos atalhos ("Comunidade") na tela Início.
- Sistema de cursos comunitários (Nível 2+4): qualquer usuário pode se auto-atribuir
  o papel de tutor (`POST /perfil/tornar-tutor`, sem fila de aprovação) e criar cursos
  próprios com publicação direta. Rascunho inicial de módulos gerado por heurística de
  template (`heuristics.py::gerar_rascunho_curso`) — deliberadamente **não** é IA
  generativa, apenas um ponto de partida editável.
- Novas telas Flutter `CriarCursoScreen` e `MeusCursosScreen`, provider
  `CursoAutoriaProvider`, badge "Criado pela comunidade" e FAB "Criar curso" (só
  visível para tutores) em `CursosScreen`.
- Persistência real no backend via SQLite (SQLAlchemy) — pedidos, cursos, eventos e
  feedbacks agora sobrevivem a um reinício do servidor.
- Autenticação JWT real (access + refresh, `pyjwt` + `bcrypt`): `POST
  /auth/usuarios/registrar`, `POST /auth/usuarios/login`; `/auth/refresh` agora valida
  o token de verdade.
- Autorização por identidade: `GET /recomendacoes/{userId}` retorna 403 ao tentar
  acessar recomendações de outro usuário; `POST /eventos` usa a identidade do token,
  não mais um campo informado livremente pelo cliente.
- `.github/workflows/ci.yml`: pipeline de CI (analyze + test + build web no Flutter;
  pytest no backend) rodando em push/PR.
- `backend/requirements-dev.txt` com as dependências de teste (`pytest`, `httpx`),
  que já eram necessárias mas não estavam declaradas em lugar nenhum.

### Changed
- Redesign visual "Minimal Tech": paleta grafite + acento verde elétrico único, novo
  wordmark "digital360", novo ícone de app (monograma "D360").
- CORS do backend restrito por lista explícita de origens (`ALLOWED_ORIGINS`), em vez
  de `allow_origins=["*"]`.
- `usuario.dart` ganhou o campo `isTutor`, persistido também na sessão local.
- Dependências Flutter atualizadas para versões seguras (uma por vez, com `dart
  analyze` + `flutter test` rodados entre cada bump): `flutter_secure_storage`
  9.2.4→10.3.1, `geolocator` 13.0.4→14.0.3, `google_fonts` 6.3.3→8.2.1, `intl`
  0.19.0→0.20.3, `flutter_map` 7.0.2→8.3.1, `latlong2` 0.9.1→0.10.1, `flutter_lints`
  4.0.0→6.0.0. `flutter_local_notifications` (17→22) foi deliberadamente adiado para
  a fase em que esse serviço volta a ser mexido, por ser um salto de 5 majors.

### Fixed
- `ApiService.login()` enviava a senha no campo `senha`, mas o backend espera
  `senhaUser` — login real (não-mock) estava quebrado desde sempre nesse ponto,
  mascarado porque `ApiConstants.useMock` sempre esteve `true` por padrão.
- `CpfInputFormatter` deixava um ponto/traço "pendurado" ao completar um grupo de
  dígitos (ex.: digitar "123" mostrava "123." em vez de "123") — corrigido pra só
  inserir o separador quando há mais dígitos depois.
