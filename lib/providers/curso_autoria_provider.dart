import 'package:flutter/foundation.dart';
import '../data/models/curso.dart';
import '../data/services/api_service.dart';

/// Estado da autoria de cursos comunitarios (Nivel 2+4 do plano de evolucao):
/// papel de tutor auto-atribuivel, rascunho por heuristica de template
/// (NAO IA generativa - ver ApiService.gerarRascunhoCurso) e publicacao
/// direta, sem fila de moderacao.
class CursoAutoriaProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool ativandoTutor = false;
  bool gerandoRascunho = false;
  bool publicando = false;
  bool carregandoMeusCursos = false;
  String? erro;

  List<String> rascunhoSugerido = [];
  List<Curso> meusCursos = [];

  Future<bool> tornarSeTutor(String bearer) async {
    ativandoTutor = true;
    erro = null;
    notifyListeners();
    try {
      await _api.tornarTutor(bearer);
      return true;
    } catch (_) {
      erro = 'Não foi possível ativar o modo tutor agora. Tente novamente.';
      return false;
    } finally {
      ativandoTutor = false;
      notifyListeners();
    }
  }

  Future<void> gerarRascunho(String bearer, String titulo, String nivel) async {
    gerandoRascunho = true;
    erro = null;
    notifyListeners();
    try {
      rascunhoSugerido = await _api.gerarRascunhoCurso(bearer, titulo, nivel);
    } catch (_) {
      erro = 'Não foi possível gerar a estrutura inicial agora. '
          'Você ainda pode montar os módulos manualmente.';
    } finally {
      gerandoRascunho = false;
      notifyListeners();
    }
  }

  void limparRascunho() {
    rascunhoSugerido = [];
  }

  Future<bool> publicarCurso(
    String bearer, {
    required String autorId,
    required String titulo,
    required String descricao,
    required String nivel,
    required int cargaHoraria,
    required List<String> topicosModulos,
  }) async {
    publicando = true;
    erro = null;
    notifyListeners();
    try {
      final criado = await _api.criarCurso(
        bearer,
        Curso(
          id: 0,
          titulo: titulo,
          descricao: descricao,
          nivel: nivel,
          cargaHoraria: cargaHoraria,
          totalModulos: topicosModulos.length,
          topicosModulos: topicosModulos,
        ),
        autorId: autorId,
      );
      meusCursos = [criado, ...meusCursos];
      return true;
    } catch (_) {
      erro = 'Não foi possível publicar o curso agora. Tente novamente em instantes.';
      return false;
    } finally {
      publicando = false;
      notifyListeners();
    }
  }

  Future<void> carregarMeusCursos(String bearer, String autorId) async {
    carregandoMeusCursos = true;
    erro = null;
    notifyListeners();
    try {
      meusCursos = await _api.getMeusCursos(bearer, autorId);
    } catch (_) {
      erro = 'Não foi possível carregar seus cursos agora.';
    } finally {
      carregandoMeusCursos = false;
      notifyListeners();
    }
  }
}
