import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/servico.dart';
import '../data/services/api_service.dart';

class ServicosProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  static const _kFav = 'favoritos_servicos';

  bool carregando = false;
  String? erro;
  List<Servico> _todos = [];
  String _busca = '';
  final Set<int> favoritos = {};

  ServicosProvider() {
    _carregarFavoritos();
  }

  String get busca => _busca;

  List<Servico> get servicos {
    if (_busca.isEmpty) return _todos;
    final q = _busca.toLowerCase();
    return _todos
        .where((s) =>
            s.titulo.toLowerCase().contains(q) ||
            s.orgao.toLowerCase().contains(q) ||
            s.categoria.toLowerCase().contains(q))
        .toList();
  }

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      _todos = await _api.getServicos(bearer);
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void filtrar(String texto) {
    _busca = texto;
    notifyListeners();
  }

  void alternarFavorito(int id) {
    if (favoritos.contains(id)) {
      favoritos.remove(id);
    } else {
      favoritos.add(id);
    }
    _salvarFavoritos();
    notifyListeners();
  }

  // ---- Persistencia local dos favoritos (shared_preferences) ----
  Future<void> _carregarFavoritos() async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList(_kFav) ?? [];
      favoritos
        ..clear()
        ..addAll(list.map(int.parse));
      notifyListeners();
    } catch (_) {/* primeira execucao */}
  }

  Future<void> _salvarFavoritos() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_kFav, favoritos.map((e) => e.toString()).toList());
    } catch (_) {/* ignora falha de disco */}
  }
}
