import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider', () {
    test('login() com senha valida autentica em modo mock', () async {
      final auth = AuthProvider();
      final ok = await auth.login('joao', '1234');
      expect(ok, true);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.usuario?.nomeUser, 'joao');
    });

    test('login() com senha vazia falha com mensagem amigavel', () async {
      final auth = AuthProvider();
      final ok = await auth.login('joao', '');
      expect(ok, false);
      expect(auth.status, AuthStatus.error);
      expect(auth.erro, isNotNull);
      expect(auth.erro!.toLowerCase(), contains('senha'));
    });

    test('registrar() guarda CPF/nome completo e login() os recupera depois', () async {
      final auth = AuthProvider();
      final cadastrou = await auth.registrar({
        'cpf': '111.444.777-35',
        'nomeCompleto': 'Maria da Silva',
        'nomeAmigavel': 'Maria',
        'nomeUser': 'maria',
        'senhaUser': 'abc123',
      });
      expect(cadastrou, true);

      final ok = await auth.login('maria', 'abc123');
      expect(ok, true);
      expect(auth.usuario?.cpf, '111.444.777-35');
      expect(auth.usuario?.nomeCompleto, 'Maria da Silva');
    });

    test('solicitarRecuperacaoSenha() sempre retorna mensagem generica', () async {
      final auth = AuthProvider();
      final msg1 = await auth.solicitarRecuperacaoSenha('usuario-que-existe');
      final msg2 = await auth.solicitarRecuperacaoSenha('usuario-que-nao-existe');
      expect(msg1, msg2); // nao revela se o usuario existe ou nao
    });

    test('atualizarNome() muda o nome de exibicao do usuario logado', () async {
      final auth = AuthProvider();
      await auth.login('joao', '1234');
      await auth.atualizarNome('João Editado');
      expect(auth.usuario?.nomeAmigavel, 'João Editado');
    });

    test('logout() limpa o usuario autenticado', () async {
      final auth = AuthProvider();
      await auth.login('joao', '1234');
      expect(auth.autenticado, true);
      await auth.logout();
      expect(auth.autenticado, false);
      expect(auth.usuario, isNull);
    });

    test('excluirConta() encerra a sessao (LGPD - direito de exclusao)', () async {
      final auth = AuthProvider();
      await auth.login('joao', '1234');
      expect(auth.autenticado, true);

      final ok = await auth.excluirConta();

      expect(ok, true);
      expect(auth.autenticado, false);
      expect(auth.usuario, isNull);
    });

    test('excluirConta() sem sessao ativa nao quebra e retorna falso', () async {
      final auth = AuthProvider();
      final ok = await auth.excluirConta();
      expect(ok, false);
    });
  });
}
