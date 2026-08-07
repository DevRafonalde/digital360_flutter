import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/cursos_provider.dart';
import 'package:digital360_flutter/providers/gamificacao_provider.dart';

void main() {
  group('GamificacaoProvider', () {
    test('carregarResumo() começa zerado para um usuário sem conclusões', () async {
      final provider = GamificacaoProvider();
      await provider.carregarResumo('bearer-teste', 'usuario_sem_pontos_xyz');

      expect(provider.cursosConcluidos, 0);
      expect(provider.sequenciaDias, 0);
      expect(provider.pontos, 0);
    });

    test('registrar conclusão de curso reflete no resumo de gamificação', () async {
      final cursos = CursosProvider();
      const userId = 'usuario_gamificacao_teste';
      cursos.registrarConclusao('bearer-teste', userId, 1);

      final provider = GamificacaoProvider();
      await provider.carregarResumo('bearer-teste', userId);

      expect(provider.cursosConcluidos, 1);
      expect(provider.pontos, greaterThan(0));
    });

    test('carregarRanking() inclui usuário com pontos', () async {
      final cursos = CursosProvider();
      const userId = 'usuario_ranking_teste';
      cursos.registrarConclusao('bearer-teste', userId, 1);

      final provider = GamificacaoProvider();
      await provider.carregarRanking('bearer-teste');

      expect(provider.ranking.any((r) => r['nomeAmigavel'] == userId), isTrue);
    });
  });
}
