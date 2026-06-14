import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

/// WEB SERVICE EXTERNO 2 (Parte 6): ViaCEP.
/// Resolve um endereco completo a partir do CEP - usado para cadastrar/validar
/// o endereco de entrega de um pedido na camada de logistica.
/// API publica brasileira, SEM necessidade de chave.
class ViaCepService {
  Future<Endereco> buscarPorCep(String cep) async {
    final clean = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 8) {
      throw Exception('CEP invalido');
    }
    final res = await http.get(Uri.parse('${ApiConstants.viaCepUrl}/$clean/json/'));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      if (j['erro'] == true) throw Exception('CEP nao encontrado');
      return Endereco.fromJson(j);
    }
    throw Exception('ViaCEP indisponivel (${res.statusCode})');
  }
}

class Endereco {
  final String cep;
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;

  Endereco({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory Endereco.fromJson(Map<String, dynamic> j) => Endereco(
        cep: j['cep'] ?? '',
        logradouro: j['logradouro'] ?? '',
        bairro: j['bairro'] ?? '',
        localidade: j['localidade'] ?? '',
        uf: j['uf'] ?? '',
      );

  String get completo =>
      '$logradouro, $bairro - $localidade/$uf  (CEP $cep)';
}
