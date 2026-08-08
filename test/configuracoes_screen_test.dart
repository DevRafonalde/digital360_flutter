import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/providers/logistica_provider.dart';
import 'package:digital360_flutter/providers/settings_provider.dart';
import 'package:digital360_flutter/ui/screens/configuracoes_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsProvider> montarTela(WidgetTester tester) async {
    final settings = SettingsProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider(create: (_) => LogisticaProvider()),
        ],
        child: const MaterialApp(home: ConfiguracoesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('mostra as 3 opcoes de tema e o slider de fonte', (tester) async {
    await montarTela(tester);

    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('tocar em "Sistema" chama definirTema(ThemeMode.system)', (tester) async {
    final settings = await montarTela(tester);
    expect(settings.themeMode, ThemeMode.dark); // default

    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.system);
  });

  testWidgets('alternar o switch de notificacoes atualiza o LogisticaProvider', (tester) async {
    await montarTela(tester);

    // Ha 2 switches nessa tela agora (notificacoes + biometria) - o de
    // notificacoes e o primeiro.
    final switchFinder = find.byType(SwitchListTile).first;

    final antes = tester.widget<SwitchListTile>(switchFinder).value;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    final depois = tester.widget<SwitchListTile>(switchFinder).value;

    expect(depois, isNot(antes));
  });

  testWidgets('switch de biometria fica desabilitado quando indisponivel no dispositivo',
      (tester) async {
    await montarTela(tester);

    // Em ambiente de teste (sem binding de plataforma), local_auth reporta
    // indisponivel - o switch de biometria deve refletir isso.
    expect(find.text('Indisponível neste dispositivo'), findsOneWidget);
  });
}
