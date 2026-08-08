import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/data/services/mock_data.dart';
import 'package:digital360_flutter/providers/logistica_provider.dart';

void main() {
  group('MockData.calcularRisco (heuristica de risco)', () {
    test('pedido sem atraso e com estoque disponivel tem risco BAIXO', () {
      final pedido = MockData.pedidos().firstWhere((p) => p.id == 1);
      final risco = MockData.calcularRisco(pedido);
      expect(risco.riscoNivel, 'BAIXO');
      expect(risco.pedidoId, 1);
    });

    test('pedido atrasado, sem estoque e com reagendamentos e CRITICO', () {
      final pedido = MockData.pedidos().firstWhere((p) => p.id == 2);
      final risco = MockData.calcularRisco(pedido);
      expect(risco.riscoNivel, 'CRITICO');
      expect(risco.riscoScore, 100); // score bruto estoura 100 e e limitado (clamp)
    });

    test('mensagem ao cliente muda conforme o score', () {
      final baixo = MockData.calcularRisco(MockData.pedidos().firstWhere((p) => p.id == 1));
      final critico = MockData.calcularRisco(MockData.pedidos().firstWhere((p) => p.id == 2));
      expect(baixo.mensagemCliente, contains('dentro do prazo'));
      expect(critico.mensagemCliente, contains('fatores'));
    });
  });

  group('MockData.respostaAssistente (fallback local do assistente)', () {
    test('pergunta sobre atraso recomenda reagendar', () {
      final resposta = MockData.respostaAssistente('Minha entrega vai atrasar?');
      expect(resposta['acaoRecomendada'], 'REAGENDAR');
    });

    test('pergunta sobre prazo recomenda aguardar', () {
      final resposta = MockData.respostaAssistente('Quando chega meu pedido?');
      expect(resposta['acaoRecomendada'], 'AGUARDAR');
    });

    test('pergunta generica retorna acao informar', () {
      final resposta = MockData.respostaAssistente('Oi, tudo bem?');
      expect(resposta['acaoRecomendada'], 'INFORMAR');
    });
  });

  group('LogisticaProvider', () {
    test('carregar() popula a lista de pedidos a partir do mock', () async {
      final provider = LogisticaProvider();
      await provider.carregar('bearer-teste');
      expect(provider.carregando, false);
      expect(provider.erro, isNull);
      expect(provider.pedidos.length, 4);
    });

    test('recalcularRisco() armazena o risco calculado por pedido', () async {
      final provider = LogisticaProvider();
      await provider.carregar('bearer-teste');
      final pedidoAtrasado = provider.pedidos.firstWhere((p) => p.id == 2);

      final risco = await provider.recalcularRisco('bearer-teste', pedidoAtrasado);

      expect(risco.riscoNivel, 'CRITICO');
      expect(provider.riscos[2]?.riscoNivel, 'CRITICO');
    });

    test('perguntar() delega para o assistente e retorna acao recomendada', () async {
      final provider = LogisticaProvider();
      final resposta = await provider.perguntar('bearer-teste', 2, 'Minha entrega pode atrasar?');
      expect(resposta['acaoRecomendada'], 'REAGENDAR');
    });

    test('recalcularRisco() soma o impacto do clima ao score', () async {
      final provider = LogisticaProvider();
      await provider.carregar('bearer-teste');
      final pedido = provider.pedidos.firstWhere((p) => p.id == 1);

      final semClima = await provider.recalcularRisco('bearer-teste', pedido);
      final comClima =
          await provider.recalcularRisco('bearer-teste', pedido, impactoClima: 20);

      expect(comClima.riscoScore, semClima.riscoScore + 20);
    });

    test('reagendar() incrementa reagendamentos, volta pra PENDENTE e limpa o risco antigo', () async {
      final provider = LogisticaProvider();
      await provider.carregar('bearer-teste');
      final pedido = provider.pedidos.firstWhere((p) => p.id == 2);
      await provider.recalcularRisco('bearer-teste', pedido);
      expect(provider.riscos.containsKey(2), true);

      final reagendamentosAntes = pedido.reagendamentos;
      await provider.reagendar('bearer-teste', pedido);

      expect(pedido.reagendamentos, reagendamentosAntes + 1);
      expect(pedido.statusAtual, 'PENDENTE');
      expect(provider.riscos.containsKey(2), false);
    });

    test('definirNotificacoesAtivas() controla a flag', () {
      final provider = LogisticaProvider();
      expect(provider.notificacoesAtivas, true);
      provider.definirNotificacoesAtivas(false);
      expect(provider.notificacoesAtivas, false);
    });
  });
}
