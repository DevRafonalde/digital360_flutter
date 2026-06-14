import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

/// Persistencia de sessao (equivalente ao SharedPreferences do Kotlin).
class SessionService {
  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kNome = 'nome_amigavel';
  static const _kUser = 'nome_user';
  static const _kId = 'user_id';

  Future<void> salvar(Usuario u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, u.accessToken);
    await p.setString(_kRefresh, u.refreshToken);
    await p.setString(_kNome, u.nomeAmigavel);
    await p.setString(_kUser, u.nomeUser);
    await p.setInt(_kId, u.id);
  }

  Future<Usuario?> carregar() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kToken);
    if (token == null) return null;
    return Usuario(
      id: p.getInt(_kId) ?? 0,
      nomeAmigavel: p.getString(_kNome) ?? '',
      nomeUser: p.getString(_kUser) ?? '',
      accessToken: token,
      refreshToken: p.getString(_kRefresh) ?? '',
    );
  }

  Future<void> limpar() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
