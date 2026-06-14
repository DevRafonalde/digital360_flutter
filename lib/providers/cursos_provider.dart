import 'package:flutter/foundation.dart';
import '../data/models/curso.dart';
import '../data/services/api_service.dart';

class CursosProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool carregando = false;
  String? erro;
  List<Curso> cursos = [];

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      cursos = await _api.getCursos(bearer);
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }
}
