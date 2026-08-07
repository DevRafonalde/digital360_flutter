import 'package:flutter_test/flutter_test.dart';
import 'package:digital360_flutter/core/utils/cpf_utils.dart';

void main() {
  group('cpfValido', () {
    test('CPF valido (digitos verificadores corretos) e aceito', () {
      // 111.444.777-35 e um CPF classico de exemplo/teste, matematicamente valido.
      expect(cpfValido('111.444.777-35'), true);
      expect(cpfValido('11144477735'), true);
    });

    test('CPF com digito verificador errado e rejeitado', () {
      expect(cpfValido('111.444.777-36'), false);
    });

    test('CPF com todos os digitos iguais e rejeitado', () {
      expect(cpfValido('111.111.111-11'), false);
      expect(cpfValido('000.000.000-00'), false);
    });

    test('CPF com quantidade errada de digitos e rejeitado', () {
      expect(cpfValido('123'), false);
      expect(cpfValido(''), false);
    });
  });

  group('cpfMascarado', () {
    test('mascara o meio do CPF, mantendo os 3 primeiros e os verificadores', () {
      expect(cpfMascarado('111.444.777-35'), '111.***.**7-35');
      expect(cpfMascarado('11144477735'), '111.***.**7-35');
    });

    test('CPF com quantidade errada de digitos volta sem alteracao', () {
      expect(cpfMascarado('123'), '123');
    });
  });
}
