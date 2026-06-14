import 'package:flutter/foundation.dart';
import '../data/models/usuario.dart';
import '../data/services/api_service.dart';
import '../data/services/session_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

/// Estado de autenticacao (Provider/ChangeNotifier).
/// Equivalente ao AuthViewModel do projeto Kotlin (MVVM).
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SessionService _session = SessionService();

  AuthStatus status = AuthStatus.idle;
  Usuario? usuario;
  String? erro;

  bool get autenticado => usuario != null;

  Future<void> tentarSessaoSalva() async {
    usuario = await _session.carregar();
    if (usuario != null) status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login(String nomeUser, String senha) async {
    status = AuthStatus.loading;
    erro = null;
    notifyListeners();
    try {
      final u = await _api.login(nomeUser, senha);
      usuario = u;
      await _session.salvar(u);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Modo demonstracao (sem credenciais), como no app Kotlin.
  Future<bool> entrarDemo() => login('Visitante', 'demo');

  Future<bool> registrar(Map<String, dynamic> dados) async {
    status = AuthStatus.loading;
    erro = null;
    notifyListeners();
    try {
      await _api.register(dados);
      status = AuthStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _session.limpar();
    usuario = null;
    status = AuthStatus.idle;
    notifyListeners();
  }
}
