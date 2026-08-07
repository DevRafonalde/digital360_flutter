import 'package:flutter/foundation.dart';
import '../data/models/curso.dart';
import '../data/services/analytics_service.dart';
import '../data/services/api_service.dart';

class CursosProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  String? erro;
  List<Curso> cursos = [];

  /// Curso que acabou de ser concluido nesta sessao (100%), para a tela
  /// mostrar a microanimacao de parabens uma unica vez.
  Curso? cursoRecemConcluido;

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      cursos = await _api.getCursos(bearer);
    } catch (e) {
      erro = _mensagemAmigavel(e);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// Avanca o progresso do curso (o que o botao "Continuar curso" deveria
  /// fazer desde o inicio). Avanca 1 modulo por vez, ou 20% se o curso nao
  /// informar o total de modulos.
  void avancar(int cursoId) {
    final idx = cursos.indexWhere((c) => c.id == cursoId);
    if (idx == -1) return;
    final c = cursos[idx];
    final passo = c.totalModulos > 0 ? (100 / c.totalModulos).ceil() : 20;
    final novoProgresso = (c.progresso + passo).clamp(0, 100);
    final concluiuAgora = c.progresso < 100 && novoProgresso == 100;
    c.progresso = novoProgresso;
    if (concluiuAgora) cursoRecemConcluido = c;
    notifyListeners();
  }

  void limparConclusaoRecente() {
    cursoRecemConcluido = null;
  }

  /// Registra o evento "curso_concluido" (alimenta o resumo de gamificacao)
  /// - fogo-e-esquece, chamado pela tela junto com o dialogo de parabens.
  void registrarConclusao(String bearer, String userId, int cursoId) {
    _api.registrarEvento(bearer, userId: userId, tipo: 'curso_concluido', referenceId: cursoId);
    AnalyticsService.instance.logEvento('curso_concluido', parametros: {'cursoId': cursoId});
  }

  String _mensagemAmigavel(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('TimeoutException') || msg.contains('SocketException')) {
      return 'Sem conexão no momento. Mostrando o que já temos salvo.';
    }
    return 'Não conseguimos atualizar seus cursos agora. Puxe para tentar de novo.';
  }
}
