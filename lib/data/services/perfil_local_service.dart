import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda localmente os dados coletados no cadastro (CPF, nome completo) por
/// nome de usuario. Necessario porque o backend mock nao persiste o
/// cadastro - sem isso, o Perfil nunca teria CPF/nome completo para exibir
/// apos o login (o login mock so recebe usuario/senha).
class PerfilLocalService {
  static const _prefixo = 'perfil_local_';

  Future<void> salvar(String nomeUser, {required String cpf, required String nomeCompleto}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('$_prefixo$nomeUser', jsonEncode({'cpf': cpf, 'nomeCompleto': nomeCompleto}));
  }

  Future<Map<String, String>?> buscar(String nomeUser) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('$_prefixo$nomeUser');
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return {'cpf': j['cpf'] ?? '', 'nomeCompleto': j['nomeCompleto'] ?? ''};
  }
}
