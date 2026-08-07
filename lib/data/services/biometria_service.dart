import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Login biometrico (impressão digital/rosto) - reautentica uma sessao QUE
/// JA EXISTE (token salvo via login normal), no momento em que o app abre.
/// Nao substitui o login por usuario/senha - so evita ter que digitar de
/// novo toda vez, atras de uma confirmacao biometrica.
class BiometriaService {
  BiometriaService._();
  static final BiometriaService instance = BiometriaService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica se o dispositivo suporta e tem biometria configurada. Protegido
  /// por try/catch: plataformas sem suporte (ex.: web) devolvem false, sem
  /// quebrar a tela que perguntou.
  Future<bool> disponivel() async {
    try {
      final suportado = await _auth.isDeviceSupported();
      final podeChecar = await _auth.canCheckBiometrics;
      return suportado && podeChecar;
    } catch (_) {
      return false;
    }
  }

  /// Pede a confirmacao biometrica. Retorna false tanto em caso de falha
  /// quanto de cancelamento pelo usuario - a tela que chama decide o que
  /// fazer (ex.: cair pro login normal).
  Future<bool> autenticar({String motivo = 'Confirme sua identidade para continuar'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e) {
      debugPrint('Falha na autenticacao biometrica: $e');
      return false;
    }
  }
}
