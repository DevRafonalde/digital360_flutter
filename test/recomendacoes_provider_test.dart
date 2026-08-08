import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/recomendacoes_provider.dart';

void main() {
  group('RecomendacoesProvider', () {
    test('carregar() popula os itens a partir do mock (cold-start)', () async {
      final provider = RecomendacoesProvider();
      await provider.carregar('bearer-teste', 'usuario-novo');

      expect(provider.carregando, false);
      expect(provider.erro, isNull);
      expect(provider.itens, isNotEmpty);
      expect(provider.itens.first['motivo'], 'cold-start');
    });

    test('registrarVisita() nao lanca excecao em modo mock', () {
      final provider = RecomendacoesProvider();
      expect(
        () => provider.registrarVisita('bearer-teste',
            userId: 'joao', tipo: 'curso', referenceId: 1),
        returnsNormally,
      );
    });
  });
}
