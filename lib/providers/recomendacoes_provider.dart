import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';

/// Estado do motor de recomendacao da AI Logistics Extension. Ate esta
/// correcao, o backend calculava recomendacoes (GET /recomendacoes/{userId})
/// mas nenhuma tela do app consumia isso - o motor mais citado nos
/// documentos do projeto ficava invisivel pro usuario.
class RecomendacoesProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  String? erro;
  List<Map<String, dynamic>> itens = [];

  Future<void> carregar(String bearer, String userId) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      itens = await _api.getRecomendacoes(bearer, userId);
    } catch (e) {
      erro = 'Não conseguimos calcular suas recomendações agora.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// Registra que o usuario acessou um curso/servico - e o que alimenta o
  /// motor de recomendacao com dados reais de uso (em vez de ficar sempre
  /// em modo cold-start). Fogo-e-esquece: nunca deve travar a navegacao.
  void registrarVisita(
    String bearer, {
    required String userId,
    required String tipo,
    required int referenceId,
    String? categoria,
  }) {
    _api.registrarEvento(
      bearer,
      userId: userId,
      tipo: tipo,
      referenceId: referenceId,
      categoria: categoria,
    );
  }
}
