import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/data/models/usuario.dart';
import 'package:digital360_flutter/providers/auth_provider.dart';
import 'package:digital360_flutter/providers/logistica_provider.dart';
import 'package:digital360_flutter/ui/screens/assistente_screen.dart';

/// Popula um usuario autenticado direto no provider, sem passar por
/// AuthProvider.login() - login() grava a sessao via SessionService, que usa
/// flutter_secure_storage (MethodChannel nativo). Dentro de testWidgets(),
/// sem um handler mock configurado pro channel, essa chamada fica pendurada
/// esperando resposta que nunca chega e trava o teste ate o timeout.
AuthProvider _authAutenticado() {
  final auth = AuthProvider();
  auth.usuario = Usuario(
    id: 1, nomeAmigavel: 'Joao', nomeUser: 'joao',
    accessToken: 'token-teste', refreshToken: 'refresh-teste',
  );
  auth.status = AuthStatus.authenticated;
  return auth;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> montarTela(WidgetTester tester) async {
    final auth = _authAutenticado();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => LogisticaProvider()),
        ],
        child: const MaterialApp(home: AssistenteScreen()),
      ),
    );
    // Nao usar pumpAndSettle aqui: o CircularProgressIndicator do estado de
    // carregamento anima continuamente e pumpAndSettle trava esperando a
    // animacao "acabar" (nunca acaba). Avancar o tempo virtual por uma
    // duracao fixa resolve o carregamento do historico sem esse problema.
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('mostra a mensagem de boas-vindas ao abrir', (tester) async {
    await montarTela(tester);
    expect(find.textContaining('Sou o assistente do Digital 360'), findsOneWidget);
  });

  testWidgets('enviar uma pergunta mostra a mensagem do usuario e a resposta', (tester) async {
    await montarTela(tester);

    await tester.enterText(find.byType(TextField), 'Minha entrega vai atrasar?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(); // registra a mensagem do usuario e o estado "Digitando..."
    await tester.pump(const Duration(milliseconds: 900)); // resolve o mock de 800ms

    expect(find.text('Minha entrega vai atrasar?'), findsOneWidget);
    expect(find.textContaining('Ação recomendada:'), findsOneWidget);
  });
}
