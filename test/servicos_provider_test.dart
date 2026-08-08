import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digital360_flutter/providers/servicos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Reseta o "disco" simulado antes de CADA teste - sem isso, um favorito
  // salvo (de forma assincrona e sem await) por um teste vazava para o
  // proximo, que comecaria com favoritos que nao deveria ter.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServicosProvider', () {
    test('filtrar() busca por titulo, orgao ou categoria', () async {
      final provider = ServicosProvider();
      await provider.carregar('bearer-teste');

      provider.filtrar('inss');
      expect(provider.servicos, hasLength(1));
      expect(provider.servicos.first.orgao, 'INSS');

      provider.filtrar('');
      expect(provider.servicos.length, greaterThan(1));
    });

    test('alternarFiltroFavoritos() mostra so os favoritados', () async {
      final provider = ServicosProvider();
      await provider.carregar('bearer-teste');
      final primeiro = provider.servicos.first;

      provider.alternarFavorito(primeiro.id);
      provider.alternarFiltroFavoritos();

      expect(provider.apenasFavoritos, true);
      expect(provider.servicos.every((s) => provider.favoritos.contains(s.id)), true);
      expect(provider.servicos.any((s) => s.id == primeiro.id), true);
    });

    test('alternarFavorito() adiciona e remove dos favoritos', () async {
      final provider = ServicosProvider();
      await provider.carregar('bearer-teste');
      final id = provider.servicos.first.id;

      provider.alternarFavorito(id);
      expect(provider.favoritos.contains(id), true);

      provider.alternarFavorito(id);
      expect(provider.favoritos.contains(id), false);
    });

    test('favorito marcado logo apos criar o provider nao e perdido quando '
        'o carregamento assincrono do disco termina depois', () async {
      final provider = ServicosProvider(); // dispara _carregarFavoritos() sem aguardar
      provider.alternarFavorito(42); // corre na frente do load do disco
      await Future.delayed(Duration.zero); // deixa o load pendente terminar

      expect(provider.favoritos.contains(42), true);
    });

    test('registrarBusca() adiciona no topo do historico, mais recente primeiro', () {
      final provider = ServicosProvider();
      provider.registrarBusca('INSS');
      provider.registrarBusca('gov.br');

      expect(provider.historicoBuscas, ['gov.br', 'INSS']);
    });

    test('registrarBusca() de um termo repetido move ele pro topo, sem duplicar', () {
      final provider = ServicosProvider();
      provider.registrarBusca('INSS');
      provider.registrarBusca('gov.br');
      provider.registrarBusca('inss'); // mesmo termo, caixa diferente

      expect(provider.historicoBuscas, ['inss', 'gov.br']);
    });

    test('registrarBusca() com termo vazio nao adiciona nada', () {
      final provider = ServicosProvider();
      provider.registrarBusca('   ');
      expect(provider.historicoBuscas, isEmpty);
    });

    test('historico fica limitado aos 8 termos mais recentes', () {
      final provider = ServicosProvider();
      for (var i = 0; i < 10; i++) {
        provider.registrarBusca('busca $i');
      }
      expect(provider.historicoBuscas, hasLength(8));
      expect(provider.historicoBuscas.first, 'busca 9');
    });

    test('limparHistorico() esvazia a lista', () {
      final provider = ServicosProvider();
      provider.registrarBusca('INSS');
      provider.limparHistorico();
      expect(provider.historicoBuscas, isEmpty);
    });
  });
}
