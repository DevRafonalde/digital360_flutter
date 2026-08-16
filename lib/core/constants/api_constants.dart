/// Ambientes de backend que o app sabe falar. PYTHON e o backend real do
/// time (FastAPI, cobre todo o app); JAVA e o backend Spring Boot construido
/// na Fase 5, que cobre autenticacao, cursos, servicos e AI Logistics.
enum AmbienteBackend { mock, python, java }

/// Constantes de rede e configuracao da camada cliente-servidor.
///
/// [useMock] e [baseUrl] deixaram de ser `const`: agora sao configuraveis em
/// tempo de execucao (ver [aplicarAmbiente]), persistidos pelo
/// SettingsProvider e trocaveis pela tela de Configuracoes, sem precisar
/// recompilar o app para apontar para um backend diferente.
class ApiConstants {
  ApiConstants._();

  /// 10.0.2.2 = localhost da maquina host quando o app roda no emulador
  /// Android (mesmo valor do projeto Kotlin original).
  static const String pythonBaseUrl = 'http://10.0.2.2:8080';

  /// Backend Spring Boot (Fase 5) - mesma porta 8080, pois cada um roda numa
  /// maquina/momento diferente; o usuario escolhe qual apontar em Configuracoes.
  static const String javaBaseUrl = 'http://10.0.2.2:8080';

  /// URL efetivamente usada pelo ApiService. Comeca apontando para o Python
  /// (ambiente default historico do app) ate [aplicarAmbiente] rodar.
  static String baseUrl = pythonBaseUrl;

  /// Quando true, o app usa dados mock locais e roda sem backend no ar.
  static bool useMock = true;

  static AmbienteBackend ambienteAtual = AmbienteBackend.mock;

  /// Aplica o ambiente escolhido (mock/python/java) ajustando [useMock] e
  /// [baseUrl] de uma vez so. Chamado pelo SettingsProvider ao carregar a
  /// preferencia salva e sempre que o usuario troca de ambiente na tela de
  /// Configuracoes.
  static void aplicarAmbiente(AmbienteBackend ambiente) {
    ambienteAtual = ambiente;
    switch (ambiente) {
      case AmbienteBackend.mock:
        useMock = true;
        baseUrl = pythonBaseUrl;
      case AmbienteBackend.python:
        useMock = false;
        baseUrl = pythonBaseUrl;
      case AmbienteBackend.java:
        useMock = false;
        baseUrl = javaBaseUrl;
    }
  }

  // ---- Web Services externos reais (Parte 6) ----
  // Open-Meteo: previsao do tempo SEM necessidade de API key.
  static const String openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';
  // ViaCEP: resolucao de endereco por CEP, SEM API key.
  static const String viaCepUrl = 'https://viacep.com.br/ws';
}
