import 'package:flutter/foundation.dart';
import '../data/models/usuario.dart';
import '../data/services/analytics_service.dart';
import '../data/services/api_service.dart';
import '../data/services/session_service.dart';
import '../data/services/perfil_local_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

/// Estado de autenticacao (Provider/ChangeNotifier).
/// Equivalente ao AuthViewModel do projeto Kotlin (MVVM).
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final SessionService _session = SessionService();
  final PerfilLocalService _perfilLocal = PerfilLocalService();

  AuthStatus status = AuthStatus.idle;
  Usuario? usuario;
  String? erro;
  String? avisoSessao;

  AuthProvider() {
    // Renovacao automatica de sessao: quando qualquer chamada autenticada
    // recebe 401, o ApiService chama isto antes de desistir.
    _api.onUnauthorized = _renovarSessaoEDevolverBearer;
  }

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
      final perfil = await _perfilLocal.buscar(nomeUser);
      usuario = perfil == null
          ? u
          : Usuario(
              id: u.id,
              nomeAmigavel: u.nomeAmigavel,
              nomeUser: u.nomeUser,
              accessToken: u.accessToken,
              refreshToken: u.refreshToken,
              cpf: perfil['cpf'] ?? '',
              nomeCompleto: perfil['nomeCompleto'] ?? '',
            );
      await _session.salvar(usuario!);
      status = AuthStatus.authenticated;
      notifyListeners();
      AnalyticsService.instance.logEvento('login_realizado');
      return true;
    } catch (e) {
      erro = _mensagemAmigavel(e);
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
      await _perfilLocal.salvar(
        dados['nomeUser'],
        cpf: dados['cpf'] ?? '',
        nomeCompleto: dados['nomeCompleto'] ?? '',
      );
      status = AuthStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      erro = _mensagemAmigavel(e);
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Recuperacao de senha - mensagem sempre generica (nao revela se o
  /// usuario existe ou nao), seguindo boa pratica de seguranca.
  Future<String> solicitarRecuperacaoSenha(String nomeUser) async {
    try {
      await _api.solicitarRecuperacaoSenha(nomeUser);
    } catch (_) {
      // mesmo em falha, a mensagem ao usuario nao muda (nao revela detalhes)
    }
    return 'Se o usuário existir, enviaremos instruções de recuperação em breve.';
  }

  /// Atualiza o nome de exibicao (editar perfil).
  Future<void> atualizarNome(String novoNome) async {
    if (usuario == null || novoNome.trim().isEmpty) return;
    usuario!.nomeAmigavel = novoNome.trim();
    await _session.salvar(usuario!);
    notifyListeners();
  }

  /// Reflete localmente a auto-atribuicao do papel de tutor (feita via
  /// CursoAutoriaProvider.tornarSeTutor) sem precisar de novo login.
  Future<void> marcarComoTutor() async {
    if (usuario == null) return;
    usuario!.isTutor = true;
    await _session.salvar(usuario!);
    notifyListeners();
  }

  Future<void> logout() async {
    await _session.limpar();
    usuario = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  /// Exclui a conta no backend e encerra a sessao local (LGPD - direito de
  /// exclusao). Nao reverte se a sessao local ja tiver sido limpa.
  Future<bool> excluirConta() async {
    if (usuario == null) return false;
    try {
      await _api.excluirConta(usuario!.bearer);
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Chamado pelo ApiService quando uma requisicao autenticada leva 401.
  /// Tenta renovar via refresh token; se falhar, encerra a sessao e sinaliza
  /// para a UI redirecionar ao login com um aviso.
  Future<String?> _renovarSessaoEDevolverBearer() async {
    if (usuario == null) return null;
    try {
      final renovado = await _api.refresh(usuario!);
      usuario = renovado;
      await _session.salvar(renovado);
      notifyListeners();
      return renovado.bearer;
    } catch (_) {
      avisoSessao = 'Sua sessão expirou. Faça login novamente.';
      await logout();
      return null;
    }
  }

  String _mensagemAmigavel(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('TimeoutException') || msg.contains('SocketException') || msg.contains('conexão')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    if (msg.toLowerCase().contains('senha invalida')) {
      return 'Usuário ou senha incorretos.';
    }
    return 'Não foi possível concluir agora. Tente novamente em instantes.';
  }
}
