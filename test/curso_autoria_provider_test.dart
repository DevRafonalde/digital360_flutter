import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/curso_autoria_provider.dart';

void main() {
  group('CursoAutoriaProvider', () {
    test('tornarSeTutor() retorna sucesso em modo mock', () async {
      final provider = CursoAutoriaProvider();
      final ok = await provider.tornarSeTutor('bearer-teste');
      expect(ok, isTrue);
      expect(provider.erro, isNull);
    });

    test('gerarRascunho() popula topicos com o titulo informado', () async {
      final provider = CursoAutoriaProvider();
      await provider.gerarRascunho('bearer-teste', 'Uso de aplicativos bancários', 'BASICO');

      expect(provider.rascunhoSugerido, isNotEmpty);
      expect(provider.rascunhoSugerido.first, contains('aplicativos bancários'));
    });

    test('gerarRascunho() nivel AVANCADO gera mais modulos que BASICO', () async {
      final provider = CursoAutoriaProvider();
      await provider.gerarRascunho('bearer-teste', 'Segurança digital', 'BASICO');
      final basico = provider.rascunhoSugerido.length;

      await provider.gerarRascunho('bearer-teste', 'Segurança digital', 'AVANCADO');
      final avancado = provider.rascunhoSugerido.length;

      expect(avancado, greaterThan(basico));
    });

    test('publicarCurso() adiciona o curso criado em meusCursos', () async {
      final provider = CursoAutoriaProvider();
      final ok = await provider.publicarCurso(
        'bearer-teste',
        autorId: 'tutor_teste',
        titulo: 'Curso comunitário de teste',
        descricao: 'Descrição breve',
        nivel: 'BASICO',
        cargaHoraria: 3,
        topicosModulos: ['Introdução', 'Prática'],
      );

      expect(ok, isTrue);
      expect(provider.meusCursos, hasLength(1));
      expect(provider.meusCursos.first.titulo, 'Curso comunitário de teste');
      expect(provider.meusCursos.first.origem, 'COMUNIDADE');
      expect(provider.meusCursos.first.status, 'PUBLICADO');
      expect(provider.meusCursos.first.autorId, 'tutor_teste');
    });

    test('carregarMeusCursos() traz só os cursos do autor informado', () async {
      final provider = CursoAutoriaProvider();
      await provider.publicarCurso(
        'bearer-teste',
        autorId: 'tutor_a',
        titulo: 'Curso do tutor A',
        descricao: '',
        nivel: 'BASICO',
        cargaHoraria: 2,
        topicosModulos: ['Módulo único'],
      );
      await provider.publicarCurso(
        'bearer-teste',
        autorId: 'tutor_b',
        titulo: 'Curso do tutor B',
        descricao: '',
        nivel: 'BASICO',
        cargaHoraria: 2,
        topicosModulos: ['Módulo único'],
      );

      await provider.carregarMeusCursos('bearer-teste', 'tutor_a');

      expect(provider.meusCursos.map((c) => c.titulo), ['Curso do tutor A']);
    });
  });
}
