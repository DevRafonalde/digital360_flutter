import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';

/// Estado de gamificacao (cursos concluidos, sequencia de dias, pontos e
/// ranking) - baseado nos eventos de uso ja registrados, regra fixa (ver
/// heuristics.py::calcular_sequencia_dias no backend).
class GamificacaoProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  String? erro;
  int cursosConcluidos = 0;
  int sequenciaDias = 0;
  int pontos = 0;
  List<Map<String, dynamic>> ranking = [];

  Future<void> carregarResumo(String bearer, String userId) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final resumo = await _api.getResumoGamificacao(bearer, userId);
      cursosConcluidos = resumo['cursosConcluidos'] ?? 0;
      sequenciaDias = resumo['sequenciaDias'] ?? 0;
      pontos = resumo['pontos'] ?? 0;
    } catch (_) {
      erro = 'Não foi possível carregar suas conquistas agora.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> carregarRanking(String bearer) async {
    try {
      ranking = await _api.getRankingGamificacao(bearer);
      notifyListeners();
    } catch (_) {/* ranking e complementar - falha silenciosa nao bloqueia a tela */}
  }
}
