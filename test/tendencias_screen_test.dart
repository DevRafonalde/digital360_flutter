import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/data/models/usuario.dart';
import 'package:digital360_flutter/providers/auth_provider.dart';
import 'package:digital360_flutter/providers/logistica_provider.dart';
import 'package:digital360_flutter/ui/screens/tendencias_screen.dart';

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

  testWidgets('carrega e mostra as tendencias do mock', (tester) async {
    final auth = _authAutenticado();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => LogisticaProvider()),
        ],
        child: const MaterialApp(home: TendenciasScreen()),
      ),
    );

    // Primeiro frame: indicador de carregamento.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Nao usar pumpAndSettle: o CircularProgressIndicator anima
    // continuamente e pumpAndSettle trava esperando a animacao "acabar".
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Detecção automática de picos'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
