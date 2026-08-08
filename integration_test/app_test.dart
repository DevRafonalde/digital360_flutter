import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digital360_flutter/main.dart' as app;

/// Teste de integracao ponta-a-ponta: login em modo demonstracao -> navega
/// pra Cursos -> avanca o progresso de um curso -> volta pro Perfil -> sai.
/// Roda o app de verdade (main() real) num device real (Windows/Chrome/Edge)
/// - diferente dos widget tests, aqui plugins nativos (secure storage etc.)
/// tem implementacao de plataforma de verdade por tras, entao nao ha o
/// problema de MethodChannel sem handler que os widget tests em modo VM tem.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login demo -> cursos -> avancar progresso -> logout', (tester) async {
    app.main();
    // Splash tem uma marca fixa de 2s antes de decidir pra onde navegar.
    await tester.pump(const Duration(seconds: 3));

    // Se o onboarding aparecer (primeira execucao), pula direto pro login -
    // ele fica sempre visivel no canto superior direito, em qualquer pagina.
    final pular = find.text('Pular');
    if (pular.evaluate().isNotEmpty) {
      await tester.tap(pular);
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('Entrar em modo demonstração'), findsOneWidget);
    await tester.tap(find.text('Entrar em modo demonstração'));
    // login() em modo demo tem delay mock de 600ms.
    await tester.pump(const Duration(milliseconds: 900));

    // Chegou na Home (bottom nav com "Início").
    expect(find.text('Cursos'), findsWidgets);

    await tester.tap(find.text('Cursos').first);
    await tester.pump(const Duration(milliseconds: 700)); // CursosProvider.carregar()

    // Abre o primeiro curso da lista.
    await tester.tap(find.byType(Card).first);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Detalhes do curso'), findsOneWidget);
    final botaoAvancar = find.textContaining(RegExp(r'Começar curso|Continuar curso'));
    expect(botaoAvancar, findsOneWidget);
    final progressoAntes = _progressoAtual(tester);

    await tester.tap(botaoAvancar);
    await tester.pump(const Duration(milliseconds: 300));

    expect(_progressoAtual(tester), greaterThan(progressoAntes));

    // Volta pra Home e vai pro Perfil.
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Perfil'), findsWidgets);
    await tester.tap(find.text('Sair'));
    await tester.pump(const Duration(milliseconds: 300));
    // Dialog de confirmacao - toca no botao "Sair" dentro dele.
    await tester.tap(find.text('Sair').last);
    await tester.pump(const Duration(milliseconds: 300));

    // Voltou pra tela de Login.
    expect(find.text('Entrar em modo demonstração'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

int _progressoAtual(WidgetTester tester) {
  final texto = tester
      .widgetList<Text>(find.textContaining('% concluído'))
      .map((t) => t.data ?? '')
      .first;
  final match = RegExp(r'(\d+)%').firstMatch(texto);
  return int.parse(match!.group(1)!);
}
