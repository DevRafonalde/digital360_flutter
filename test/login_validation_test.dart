import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:digital360_flutter/providers/auth_provider.dart';
import 'package:digital360_flutter/ui/screens/login_screen.dart';

void main() {
  testWidgets('Login valida campos vazios e exibe mensagem', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Toca em "Entrar" sem preencher nada.
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o usuário'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });
}
