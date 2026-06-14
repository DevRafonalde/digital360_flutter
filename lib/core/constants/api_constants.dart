/// Constantes de rede e configuracao da camada cliente-servidor.
class ApiConstants {
  ApiConstants._();

  /// Backend Smart HAS (Spring/Python). 10.0.2.2 = localhost da maquina host
  /// quando o app roda no emulador Android (mesmo valor do projeto Kotlin).
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// Quando true, o app usa dados mock locais e roda sem backend no ar.
  /// Coloque false para apontar para o backend real do Smart HAS.
  static const bool useMock = true;

  // ---- Web Services externos reais (Parte 6) ----
  // Open-Meteo: previsao do tempo SEM necessidade de API key.
  static const String openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';
  // ViaCEP: resolucao de endereco por CEP, SEM API key.
  static const String viaCepUrl = 'https://viacep.com.br/ws';
}
