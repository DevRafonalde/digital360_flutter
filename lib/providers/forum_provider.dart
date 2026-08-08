import 'package:flutter/foundation.dart';
import '../data/models/pergunta_forum.dart';
import '../data/services/api_service.dart';

/// Estado do forum de perguntas e respostas da comunidade.
class ForumProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  bool enviando = false;
  String? erro;
  List<PerguntaForum> perguntas = [];
  PerguntaForum? perguntaAtual;

  Future<void> carregarPerguntas(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      perguntas = await _api.getPerguntas(bearer);
    } catch (_) {
      erro = 'Não foi possível carregar as perguntas agora.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> criarPergunta(String bearer, String autorNome, String titulo, String corpo) async {
    enviando = true;
    erro = null;
    notifyListeners();
    try {
      final criada = await _api.criarPergunta(bearer, autorNome, titulo, corpo);
      perguntas = [criada, ...perguntas];
      return true;
    } catch (_) {
      erro = 'Não foi possível publicar sua pergunta agora.';
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  Future<void> carregarDetalhe(String bearer, int perguntaId) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      perguntaAtual = await _api.getDetalhePergunta(bearer, perguntaId);
    } catch (_) {
      erro = 'Não foi possível carregar esta pergunta agora.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> responder(String bearer, int perguntaId, String autorNome, String corpo) async {
    enviando = true;
    erro = null;
    notifyListeners();
    try {
      perguntaAtual = await _api.responderPergunta(bearer, perguntaId, autorNome, corpo);
      return true;
    } catch (_) {
      erro = 'Não foi possível enviar sua resposta agora.';
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
