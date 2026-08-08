import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/cursos_provider.dart';

void main() {
  group('CursosProvider.avancar', () {
    test('avanca o progresso do curso conforme os modulos', () async {
      final provider = CursosProvider();
      await provider.carregar('bearer-teste');
      final curso = provider.cursos.first; // 6 modulos, comeca em 75%

      provider.avancar(curso.id);

      expect(provider.cursos.first.progresso, greaterThan(75));
    });

    test('progresso nao passa de 100', () async {
      final provider = CursosProvider();
      await provider.carregar('bearer-teste');
      final curso = provider.cursos.first;

      for (var i = 0; i < 20; i++) {
        provider.avancar(curso.id);
      }

      expect(provider.cursos.first.progresso, 100);
    });

    test('marca cursoRecemConcluido só quando cruza 100% pela primeira vez', () async {
      final provider = CursosProvider();
      await provider.carregar('bearer-teste');
      final curso = provider.cursos.first;

      for (var i = 0; i < 20; i++) {
        provider.avancar(curso.id);
      }
      expect(provider.cursoRecemConcluido?.id, curso.id);

      provider.limparConclusaoRecente();
      provider.avancar(curso.id); // ja estava 100%, nao deve marcar de novo
      expect(provider.cursoRecemConcluido, isNull);
    });

    test('id inexistente nao quebra nem altera nada', () async {
      final provider = CursosProvider();
      await provider.carregar('bearer-teste');
      final progressoAntes = provider.cursos.map((c) => c.progresso).toList();

      provider.avancar(9999);

      expect(provider.cursos.map((c) => c.progresso).toList(), progressoAntes);
    });
  });
}
