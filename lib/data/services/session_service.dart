import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

/// Persistencia de sessao. Tokens ficam no armazenamento seguro do SO
/// (Keystore/Keychain via flutter_secure_storage), ja que sao credenciais
/// que concedem acesso a API. O resto do perfil (nome, CPF, id) fica em
/// SharedPreferences normal - mesmo nivel de sensibilidade de um cadastro
/// local, sem chave de API nenhuma em jogo.
class SessionService {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kNome = 'nome_amigavel';
  static const _kUser = 'nome_user';
  static const _kId = 'user_id';
  static const _kCpf = 'cpf';
  static const _kNomeCompleto = 'nome_completo';
  static const _kIsTutor = 'is_tutor';

  Future<void> salvar(Usuario u) async {
    try {
      await _storage.write(key: _kToken, value: u.accessToken);
      await _storage.write(key: _kRefresh, value: u.refreshToken);
    } catch (_) {
      // plataforma sem suporte a secure storage - a sessao so nao sobrevive
      // a um reinicio do app, mas o login em si continua funcionando.
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_kNome, u.nomeAmigavel);
    await p.setString(_kUser, u.nomeUser);
    await p.setInt(_kId, u.id);
    await p.setString(_kCpf, u.cpf);
    await p.setString(_kNomeCompleto, u.nomeCompleto);
    await p.setBool(_kIsTutor, u.isTutor);
  }

  Future<Usuario?> carregar() async {
    String? token;
    try {
      token = await _storage.read(key: _kToken);
    } catch (_) {
      // plataforma sem suporte a secure storage (ex.: alguns ambientes web
      // sem HTTPS) - trata como sessao nao encontrada, sem quebrar o app.
      return null;
    }
    if (token == null) return null;
    final p = await SharedPreferences.getInstance();
    return Usuario(
      id: p.getInt(_kId) ?? 0,
      nomeAmigavel: p.getString(_kNome) ?? '',
      nomeUser: p.getString(_kUser) ?? '',
      accessToken: token,
      refreshToken: await _storage.read(key: _kRefresh) ?? '',
      cpf: p.getString(_kCpf) ?? '',
      nomeCompleto: p.getString(_kNomeCompleto) ?? '',
      isTutor: p.getBool(_kIsTutor) ?? false,
    );
  }

  Future<void> limpar() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kRefresh);
    } catch (_) {/* ignora se a plataforma nao suportar */}
    final p = await SharedPreferences.getInstance();
    await p.remove(_kNome);
    await p.remove(_kUser);
    await p.remove(_kId);
    await p.remove(_kCpf);
    await p.remove(_kNomeCompleto);
    await p.remove(_kIsTutor);
  }
}
