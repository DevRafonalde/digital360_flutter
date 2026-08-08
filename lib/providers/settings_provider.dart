import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de acessibilidade e aparencia (tema, tamanho de fonte).
/// Publico-alvo do app (idosos, baixo letramento digital) se beneficia de
/// poder ajustar esses dois pontos, entao ficam configuraveis e persistidos.
class SettingsProvider extends ChangeNotifier {
  static const _kTema = 'settings_tema'; // 'system' | 'dark' | 'light'
  static const _kFonte = 'settings_fonte_escala';
  static const _kBiometria = 'settings_biometria_ativa';

  ThemeMode themeMode = ThemeMode.dark;
  double fontScale = 1.0; // 0.9 / 1.0 / 1.15 / 1.3
  bool biometriaAtiva = false;

  SettingsProvider() {
    _carregar();
  }

  Future<void> _carregar() async {
    final p = await SharedPreferences.getInstance();
    themeMode = _fromString(p.getString(_kTema));
    fontScale = p.getDouble(_kFonte) ?? 1.0;
    biometriaAtiva = p.getBool(_kBiometria) ?? false;
    notifyListeners();
  }

  /// Liga/desliga a exigencia de biometria ao reabrir o app com uma sessao
  /// ja salva - nao afeta o login por usuario/senha em si.
  Future<void> definirBiometriaAtiva(bool ativa) async {
    biometriaAtiva = ativa;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBiometria, ativa);
  }

  /// Define o tema entre as 3 vias: acompanhar o sistema, ou fixar
  /// claro/escuro - respeita quem prefere que o app siga a preferencia
  /// do aparelho, em vez de forcar uma escolha manual.
  Future<void> definirTema(ThemeMode modo) async {
    themeMode = modo;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTema, _toString(modo));
  }

  Future<void> definirEscalaFonte(double escala) async {
    fontScale = escala;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kFonte, escala);
  }

  ThemeMode _fromString(String? v) {
    switch (v) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark; // default historico do app (antes da opcao "sistema" existir)
    }
  }

  String _toString(ThemeMode m) => switch (m) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };
}
