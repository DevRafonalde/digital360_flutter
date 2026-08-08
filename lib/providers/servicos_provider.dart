import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/servico.dart';
import '../data/services/api_service.dart';

class ServicosProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  static const _kFav = 'favoritos_servicos';
  static const _kHistorico = 'historico_buscas_guia';
  static const _maxHistorico = 8;

  bool carregando = false;
  String? erro;
  List<Servico> _todos = [];
  String _busca = '';
  bool apenasFavoritos = false;
  final Set<int> favoritos = {};
  List<String> historicoBuscas = [];

  ServicosProvider() {
    _carregarFavoritos();
    _carregarHistorico();
  }

  String get busca => _busca;

  List<Servico> get servicos {
    var lista = _todos;
    if (apenasFavoritos) {
      lista = lista.where((s) => favoritos.contains(s.id)).toList();
    }
    if (_busca.isNotEmpty) {
      final q = _busca.toLowerCase();
      lista = lista
          .where((s) =>
              s.titulo.toLowerCase().contains(q) ||
              s.orgao.toLowerCase().contains(q) ||
              s.categoria.toLowerCase().contains(q))
          .toList();
    }
    return lista;
  }

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      _todos = await _api.getServicos(bearer);
    } catch (e) {
      erro = _mensagemAmigavel(e);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void filtrar(String texto) {
    _busca = texto;
    notifyListeners();
  }

  void alternarFiltroFavoritos() {
    apenasFavoritos = !apenasFavoritos;
    notifyListeners();
  }

  /// Registra um termo no historico de buscas recentes (mais recente
  /// primeiro, sem duplicatas, limitado a [_maxHistorico] itens) - mesmo
  /// padrao de persistencia local ja usado pelos favoritos.
  void registrarBusca(String termo) {
    final t = termo.trim();
    if (t.isEmpty) return;
    historicoBuscas.removeWhere((h) => h.toLowerCase() == t.toLowerCase());
    historicoBuscas.insert(0, t);
    if (historicoBuscas.length > _maxHistorico) {
      historicoBuscas = historicoBuscas.sublist(0, _maxHistorico);
    }
    _salvarHistorico();
    notifyListeners();
  }

  void limparHistorico() {
    historicoBuscas.clear();
    _salvarHistorico();
    notifyListeners();
  }

  Future<void> _carregarHistorico() async {
    try {
      final p = await SharedPreferences.getInstance();
      historicoBuscas = p.getStringList(_kHistorico) ?? [];
      notifyListeners();
    } catch (_) {/* primeira execucao */}
  }

  Future<void> _salvarHistorico() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_kHistorico, historicoBuscas);
    } catch (_) {/* ignora falha de disco */}
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
      // Uniao (nao substituicao): o carregamento e assincrono no construtor,
      // entao um toggle do usuario pode acontecer antes dele terminar - um
      // clear() aqui apagaria esse toggle silenciosamente.
      favoritos.addAll(list.map(int.parse));
      notifyListeners();
    } catch (_) {/* primeira execucao */}
  }

  Future<void> _salvarFavoritos() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_kFav, favoritos.map((e) => e.toString()).toList());
    } catch (_) {/* ignora falha de disco */}
  }

  String _mensagemAmigavel(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('TimeoutException') || msg.contains('SocketException')) {
      return 'Sem conexão no momento. Mostrando o que já temos salvo.';
    }
    return 'Não conseguimos atualizar o guia de serviços agora.';
  }
}
