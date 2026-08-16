import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

/// Preferencias de acessibilidade e aparencia (tema, tamanho de fonte).
/// Publico-alvo do app (idosos, baixo letramento digital) se beneficia de
/// poder ajustar esses dois pontos, entao ficam configuraveis e persistidos.
class SettingsProvider extends ChangeNotifier {
  static const _kTema = 'settings_tema'; // 'system' | 'dark' | 'light'
  static const _kFonte = 'settings_fonte_escala';
  static const _kBiometria = 'settings_biometria_ativa';
  static const _kAmbiente = 'settings_ambiente_backend'; // 'mock' | 'python' | 'java'

  ThemeMode themeMode = ThemeMode.dark;
  double fontScale = 1.0; // 0.9 / 1.0 / 1.15 / 1.3
  bool biometriaAtiva = false;
  AmbienteBackend ambienteBackend = AmbienteBackend.mock;

  SettingsProvider() {
    _carregar();
  }

  Future<void> _carregar() async {
    final p = await SharedPreferences.getInstance();
    themeMode = _fromString(p.getString(_kTema));
    fontScale = p.getDouble(_kFonte) ?? 1.0;
    biometriaAtiva = p.getBool(_kBiometria) ?? false;
    ambienteBackend = _ambienteFromString(p.getString(_kAmbiente));
    ApiConstants.aplicarAmbiente(ambienteBackend);
    notifyListeners();
  }

  /// Troca o backend que o app conversa (mock / Python real / Java Fase 5).
  /// Nao exige reiniciar o app: [ApiConstants.baseUrl] e lido a cada chamada
  /// de rede, entao a troca vale a partir da proxima requisicao.
  Future<void> definirAmbienteBackend(AmbienteBackend ambiente) async {
    ambienteBackend = ambiente;
    ApiConstants.aplicarAmbiente(ambiente);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAmbiente, _ambienteToString(ambiente));
  }

  AmbienteBackend _ambienteFromString(String? v) => switch (v) {
        'python' => AmbienteBackend.python,
        'java' => AmbienteBackend.java,
        _ => AmbienteBackend.mock,
      };

  String _ambienteToString(AmbienteBackend a) => switch (a) {
        AmbienteBackend.mock => 'mock',
        AmbienteBackend.python => 'python',
        AmbienteBackend.java => 'java',
      };

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
