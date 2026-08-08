import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/core/utils/cpf_utils.dart';

TextEditingValue _digitar(String textoAtual) {
  final formatter = CpfInputFormatter();
  return formatter.formatEditUpdate(
    const TextEditingValue(text: ''),
    TextEditingValue(text: textoAtual, selection: TextSelection.collapsed(offset: textoAtual.length)),
  );
}

void main() {
  group('CpfInputFormatter', () {
    test('formata os digitos progressivamente com pontos e traco', () {
      expect(_digitar('1').text, '1');
      expect(_digitar('123').text, '123');
      expect(_digitar('1234').text, '123.4');
      expect(_digitar('123456').text, '123.456');
      expect(_digitar('1234567').text, '123.456.7');
      expect(_digitar('11144477735').text, '111.444.777-35');
    });

    test('ignora caracteres nao numericos digitados', () {
      expect(_digitar('111.444.777-35').text, '111.444.777-35');
      expect(_digitar('abc111').text, '111');
    });

    test('trunca alem de 11 digitos', () {
      expect(_digitar('111444777359999').text, '111.444.777-35');
    });

    test('cursor fica sempre no final do texto formatado', () {
      final r = _digitar('1234');
      expect(r.selection.baseOffset, r.text.length);
    });
  });
}
