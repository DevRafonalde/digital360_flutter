================================================================================
 DIGITAL 360 - SMART HAS
 Inclusao digital para idosos e pessoas com deficiencia
 Global Solution 2 - 2026 | CitizenTech: tecnologia centrada no cidadao
 FIAP - Turma 3SIOA
================================================================================

GRUPO
  - Eduardo Andrade Martins Vasques ...... RM 556970
  - Otavio Ramos dos Santos Souza ........ RM 550361
  - Enzo Miranda Ward de Paiva ........... RM 557632
  - Rafael Pinto de Albuquerque .......... RM 559136
  - Guilherme Leoni Vidigal Tiburcio ..... RM 557500

Repositorio: https://github.com/DevRafonalde/digital360_flutter/tree/GlobalSolution2

--------------------------------------------------------------------------------
1. O PROBLEMA E A SOLUCAO
--------------------------------------------------------------------------------
Servicos essenciais migraram para o celular: extrato do INSS, agendamento no
SUS, 2a via de documentos, Bolsa Familia, Pix. Quem nao domina o aparelho
depende de terceiros, fica mais exposto a golpes e deixa de exercer direitos
que ja tem. Esse publico inclui idosos, pessoas com deficiencia e adultos com
baixo letramento digital.

O Digital 360 e um app Flutter com interface simples e acessivel (fonte
ajustavel, alto contraste, leitura em voz alta e busca por voz) que:
  1. ENSINA o uso do celular e dos servicos digitais em trilhas curtas;
  2. ORIENTA o acesso a servicos publicos e direitos, com passo a passo
     lido em voz alta;
  3. ACOMPANHA as compras e entregas do cidadao, com alerta de risco de
     atraso e reagendamento com 1 toque;
  4. CONECTA a pessoa a uma rede de apoio: modo cuidador e forum.

Publico beneficiado: idosos, pessoas com deficiencia, cidadaos com baixo
letramento digital e os cuidadores e familiares que os apoiam.

--------------------------------------------------------------------------------
2. ODS DA ONU
--------------------------------------------------------------------------------
  - ODS 10 (principal) - Reducao das desigualdades, meta 10.2: inclusao de
    todos, independentemente da idade e da deficiencia.
  - ODS 4 - Educacao de qualidade, metas 4.4 (competencias digitais) e 4.5
    (acesso de pessoas com deficiencia e vulneraveis).
  - ODS 9 - Industria, inovacao e infraestrutura, meta 9.c (acesso as TICs).
Detalhes na secao "Relacao com os ODS" do README.md.

--------------------------------------------------------------------------------
3. FUNCIONALIDADES PRINCIPAIS (alem de login e cadastro)
--------------------------------------------------------------------------------
  1. Trilhas de aprendizagem digital: cursos com progresso, conteudo lido em
     voz alta, certificado em PDF e cursos criados pela comunidade.
     (lib/ui/screens/cursos_screen.dart, lib/providers/cursos_provider.dart)
  2. Guia de servicos publicos e direitos: INSS, SUS, documentos, Bolsa
     Familia e Estatuto do Idoso, com busca por texto ou voz, favoritos e
     leitura em voz alta.
     (lib/ui/screens/guia_screen.dart, lib/providers/servicos_provider.dart)
  3. Acompanhamento de entregas: risco de atraso calculado com o clima real
     (API Open-Meteo), notificacao nos riscos ALTO e CRITICO, reagendamento,
     avaliacao da entrega e mapa.
     (lib/ui/screens/logistica_screen.dart, lib/providers/logistica_provider.dart)
Complementares: modo cuidador, forum, gamificacao, assistente baseado em
regras (nao usa IA generativa) e painel de impacto.

--------------------------------------------------------------------------------
4. COMO EXECUTAR
--------------------------------------------------------------------------------
OPCAO A - Sem instalar o Flutter (so precisa do Docker Desktop)
  Na raiz do repositorio, em um terminal bash (Git Bash no Windows):

    bash deploy/deploy_homolog.sh      # sobe Oracle + API Java, instala o PL/SQL e valida
    bash deploy/app_web_docker.sh      # compila o app e serve em http://localhost:5000

  No app, va em Configuracoes > Conexao (avancado) e escolha "Java".
  Login de teste: joao / 123456
  Swagger da API: http://localhost:8080/swagger-ui.html (admin / admin123)
  Oracle: localhost:1521/FREEPDB1, usuario smarthas / senha smarthas

  Para encerrar:
    docker compose -f deploy/docker-compose.homolog.yml down -v
    docker rm -f smarthas-app-web

  Obs.: a primeira execucao baixa a imagem do Flutter (cerca de 4,5 GB).

OPCAO B - Com o Flutter instalado (SDK compativel com Dart 3.4 ou superior)
    flutter pub get
    flutter run -d chrome              # navegador (mapa via OpenStreetMap, sem chave)
    flutter run                        # emulador ou celular Android

  O app abre no modo "Mock" (dados de exemplo, sem back-end). Nesse modo
  qualquer usuario com senha nao vazia entra. Para usar um back-end real,
  troque o ambiente em Configuracoes > Conexao (avancado).

Back-ends (opcionais):
  - Java/Spring Boot (backend-java/): JDK 17+ e Maven
        cd backend-java && mvn spring-boot:run          # porta 8080, banco H2
        (com ORACLE_ENABLED=true usa o Oracle e os endpoints /oracle/**)
  - Python/FastAPI (backend/): Python 3 e pip
        cd backend && pip install -r requirements.txt
        uvicorn app.main:app --reload --port 8080

Banco Oracle (rodando os scripts manualmente, no SQL Developer ou SQL*Plus):
        @database-oracle/00_executar_tudo.sql

Testes:
        flutter test                                     # app (providers, telas, golden)
        cd backend-java && mvn verify                    # API Java
        cd backend && pytest                             # API Python
        @database-oracle/09_testes_automatizados.sql     # PL/SQL

--------------------------------------------------------------------------------
5. JUSTIFICATIVAS TECNICAS
--------------------------------------------------------------------------------
  - Flutter/Dart: um unico codigo para Android, iOS e web, com interface
    identica nas tres plataformas. Componentes Material 3 suportam escala de
    fonte e leitores de tela, o que e essencial para o publico.
  - Provider: gestao de estado recomendada pela documentacao do Flutter. Ha
    um ChangeNotifier por dominio e so as telas interessadas sao redesenhadas.
  - flutter_tts e speech_to_text: leitura em voz alta e busca por voz para
    quem tem dificuldade de ler ou digitar.
  - flutter_secure_storage e local_auth: tokens no Keystore/Keychain e login
    por digital, sem precisar digitar a senha toda vez.
  - Open-Meteo e ViaCEP: APIs publicas e gratuitas. O clima entra de fato no
    calculo de risco da entrega.
  - Firebase (FCM, Analytics, Crashlytics): avisos de risco com deep link e
    monitoramento de falhas.
  - Java/Spring Boot + Oracle PL/SQL: regras de negocio perto dos dados
    (calculo de risco, alertas de sensores, relatorios, auditoria por trigger)
    expostas por API REST com JWT.
  - Docker + GitHub Actions: ambiente reproduzivel e pipeline que testa e
    publica a cada push.
Tabela completa de tecnologias e beneficios: README.md, secao "Tecnologias
adotadas e beneficios".

--------------------------------------------------------------------------------
6. GERENCIAMENTO DE MEMORIA E EFICIENCIA (resumo)
--------------------------------------------------------------------------------
  - dispose() dos controllers em todas as telas com estado (25 recursos
    liberados em 10 telas);
  - checagem de "mounted" apos cada await antes de usar setState ou context;
  - cerca de 740 construtores const, que o Flutter reaproveita sem reconstruir;
  - ListView.builder/separated nas 7 telas com listas (so constroi o visivel);
  - Provider com rebuild seletivo (context.watch so onde precisa e
    context.read nos callbacks);
  - ApiService singleton com um unico http.Client reutilizado;
  - timeout de 8 a 10 s em toda chamada de rede;
  - historico de buscas limitado a 8 itens;
  - build de release com tree shaking.
Ponto de melhoria conhecido e o detalhamento completo: README.md, secao
"Gerenciamento de memoria e eficiencia".

--------------------------------------------------------------------------------
7. MODELO DE DADOS E PL/SQL
--------------------------------------------------------------------------------
  - MER (conceitual): database-oracle/MER_SmartHAS.md
  - DER (12 tabelas): database-oracle/DER_SmartHAS.png
  - DDL e dados:      database-oracle/01_ddl_tabelas.sql, 02_dados_simulados.sql
  - Packages:         PKG_SH_RISCO (risco de entrega), PKG_SH_IOT (alertas de
                      sensores), PKG_SH_USUARIO (indicadores por usuario),
                      PKG_SH_CONSULTA (busca dinamica de pedidos)
  - Triggers:         TRG_SH_ALERTA_AUDITORIA, TRG_SH_PEDIDO_ENTREGUE

--------------------------------------------------------------------------------
8. ESTRUTURA DO REPOSITORIO
--------------------------------------------------------------------------------
  lib/               app Flutter (core, data/models, data/services, providers, ui)
  test/              testes unitarios, de widget e golden do app
  backend-java/      API Java/Spring Boot (H2 + integracao Oracle)
  backend/           API Python/FastAPI (heuristicas de recomendacao e risco)
  database-oracle/   scripts Oracle, PL/SQL, MER e DER
  dashboard/         painel web administrativo (Angular)
  deploy/            scripts Docker de homologacao
  docs/gs2/          roteiros dos videos e arquivos .txt com os links da entrega

--------------------------------------------------------------------------------
9. DOCUMENTACAO DO CODIGO
--------------------------------------------------------------------------------
Classes, metodos e funcoes do app tem comentarios de documentacao (///) em 63
dos 72 arquivos Dart de lib/. A arquitetura segue o fluxo
UI -> Provider (estado) -> Service (rede) -> Model.
