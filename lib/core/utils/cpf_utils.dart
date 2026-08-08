import 'package:flutter/services.dart';

/// Mascara de CPF (000.000.000-00) aplicada enquanto o usuario digita.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').substring(
        0, newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length.clamp(0, 11));
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final temMaisDigitos = i < digits.length - 1;
      if ((i == 2 || i == 5) && temMaisDigitos) buffer.write('.');
      if (i == 8 && temMaisDigitos) buffer.write('-');
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Validacao de CPF pelo algoritmo oficial dos digitos verificadores.
bool cpfValido(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false; // 000.000.000-00 etc.

  final nums = digits.split('').map(int.parse).toList();

  int calcularDigito(List<int> base) {
    var peso = base.length + 1;
    var soma = 0;
    for (final n in base) {
      soma += n * peso;
      peso--;
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  final d1 = calcularDigito(nums.sublist(0, 9));
  final d2 = calcularDigito(nums.sublist(0, 9) + [d1]);
  return d1 == nums[9] && d2 == nums[10];
}

/// Mascara os dígitos do meio do CPF (ex.: "123.456.789-35" vira
/// "123.***.**9-35") - usado no Perfil pra nao exibir o CPF completo por
/// padrao, so quando o usuario pedir explicitamente pra revelar.
String cpfMascarado(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 11) return cpf;
  return '${digits.substring(0, 3)}.***.**${digits.substring(8, 9)}-${digits.substring(9)}';
}
