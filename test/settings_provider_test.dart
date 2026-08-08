import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider', () {
    test('tema comeca no default historico (escuro) quando nunca configurado', () async {
      final settings = SettingsProvider();
      await Future.delayed(Duration.zero); // aguarda o _carregar() assincrono
      expect(settings.themeMode, ThemeMode.dark);
    });

    test('definirTema() aceita as 3 vias e persiste entre instancias', () async {
      final settings = SettingsProvider();
      await settings.definirTema(ThemeMode.system);
      expect(settings.themeMode, ThemeMode.system);

      final novaInstancia = SettingsProvider();
      await Future.delayed(Duration.zero);
      expect(novaInstancia.themeMode, ThemeMode.system);
    });

    test('definirTema() para claro e escuro tambem funciona e persiste', () async {
      final settings = SettingsProvider();

      await settings.definirTema(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);

      await settings.definirTema(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);
    });

    test('definirEscalaFonte() atualiza e persiste a escala', () async {
      final settings = SettingsProvider();
      await settings.definirEscalaFonte(1.3);
      expect(settings.fontScale, 1.3);

      final novaInstancia = SettingsProvider();
      await Future.delayed(Duration.zero);
      expect(novaInstancia.fontScale, 1.3);
    });
  });
}
