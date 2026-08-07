import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/forum_provider.dart';

void main() {
  group('ForumProvider', () {
    test('criarPergunta() adiciona a pergunta no topo da lista', () async {
      final provider = ForumProvider();
      final ok = await provider.criarPergunta(
        'bearer-teste', 'Fulano', 'Como uso o Pix?', 'Alguém pode explicar o passo a passo?',
      );

      expect(ok, isTrue);
      expect(provider.perguntas, hasLength(1));
      expect(provider.perguntas.first.titulo, 'Como uso o Pix?');
      expect(provider.perguntas.first.totalRespostas, 0);
    });

    test('carregarPerguntas() popula a lista em modo mock', () async {
      final provider = ForumProvider();
      await provider.criarPergunta('bearer-teste', 'Fulano', 'Pergunta única XYZ', 'Corpo 1');

      await provider.carregarPerguntas('bearer-teste');

      expect(provider.perguntas.any((p) => p.titulo == 'Pergunta única XYZ'), isTrue);
      expect(provider.erro, isNull);
    });

    test('responder() incrementa o total de respostas da pergunta atual', () async {
      final provider = ForumProvider();
      await provider.criarPergunta('bearer-teste', 'Fulano', 'Pergunta', 'Corpo');
      final perguntaId = provider.perguntas.first.id;

      await provider.carregarDetalhe('bearer-teste', perguntaId);
      final ok = await provider.responder('bearer-teste', perguntaId, 'Ciclano', 'Resposta útil');

      expect(ok, isTrue);
      expect(provider.perguntaAtual?.totalRespostas, 1);
      expect(provider.perguntaAtual?.respostas.first.corpo, 'Resposta útil');
    });
  });
}
