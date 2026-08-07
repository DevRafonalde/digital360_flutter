import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/ui/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('primeiro passo pede o perfil antes de liberar a navegacao', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Quem vai usar o Digital 360?'), findsOneWidget);
    expect(find.text('Sou cuidador(a)'), findsOneWidget);
    // Sem escolher um perfil, so ha o aviso pedindo pra escolher - nao ha
    // botao "Proximo" disponivel ainda.
    expect(find.text('Escolha uma opção acima para continuar'), findsOneWidget);
  });

  testWidgets('escolher "cuidador" personaliza a dica final do tour', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('Sou cuidador(a)'));
    await tester.pumpAndSettle();

    // Avanca pelos 2 slides fixos ate chegar na dica personalizada.
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Acompanhe quem você cuida'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('escolher "eu mesmo" mantem a dica original sobre entregas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.tap(find.text('Eu mesmo(a)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Acompanhe suas entregas'), findsOneWidget);
  });
}
