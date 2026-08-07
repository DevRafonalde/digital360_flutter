import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/providers/cuidador_provider.dart';

void main() {
  group('CuidadorProvider', () {
    test('vincular() cria o vínculo e aparece em carregarVinculos()', () async {
      final provider = CuidadorProvider();
      const cuidadorId = 'cuidador_teste_xyz';
      const idosoId = 'idoso_teste_xyz';

      final ok = await provider.vincular('bearer-teste', cuidadorId, idosoId);
      expect(ok, isTrue);

      await provider.carregarVinculos('bearer-teste', cuidadorId);
      expect(provider.vinculos, hasLength(1));
      expect(provider.vinculos.first.idosoId, idosoId);
      expect(provider.resumos[idosoId], isNotNull);
    });

    test('vincular() a si mesmo falha com mensagem de erro', () async {
      final provider = CuidadorProvider();
      const userId = 'usuario_solo_xyz';

      final ok = await provider.vincular('bearer-teste', userId, userId);

      expect(ok, isFalse);
      expect(provider.erro, isNotNull);
    });

    test('vincular() duas vezes ao mesmo idoso falha na segunda', () async {
      final provider = CuidadorProvider();
      const cuidadorId = 'cuidador_duplicado_xyz';
      const idosoId = 'idoso_duplicado_xyz';

      await provider.vincular('bearer-teste', cuidadorId, idosoId);
      final segundaVez = await provider.vincular('bearer-teste', cuidadorId, idosoId);

      expect(segundaVez, isFalse);
    });
  });
}
