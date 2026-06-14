import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/curso.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/pedido_logistico.dart';
import 'mock_data.dart';

/// Camada cliente-servidor (Retrofit-equivalente em Flutter).
/// Implementa o contrato REST do backend Smart HAS sobre HTTP/HTTPS.
/// Com ApiConstants.useMock = true, retorna dados mock para rodar sem backend.
class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> _headers([String? bearer]) => {
        'Content-Type': 'application/json',
        if (bearer != null) 'Authorization': bearer,
      };

  // ---- Autenticacao ----
  Future<Usuario> login(String nomeUser, String senha) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (senha.isEmpty) {
        throw Exception('Senha invalida');
      }
      return MockData.usuario(nomeUser);
    }
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/usuarios/login'),
      headers: _headers(),
      body: jsonEncode({'nomeUser': nomeUser, 'senha': senha}),
    );
    if (res.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(res.body));
    }
    throw Exception('Falha no login (${res.statusCode})');
  }

  Future<void> register(Map<String, dynamic> body) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/usuarios/registrar'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception('Falha no cadastro (${res.statusCode})');
    }
  }

  // ---- Cursos ----
  Future<List<Curso>> getCursos(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.cursos();
    }
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/cursos'),
      headers: _headers(bearer),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Curso.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar cursos (${res.statusCode})');
  }

  // ---- Guia de Servicos ----
  Future<List<Servico>> getServicos(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.servicos();
    }
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/servicos'),
      headers: _headers(bearer),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Servico.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar servicos (${res.statusCode})');
  }

  // ---- AI Logistics Extension ----
  Future<List<PedidoLogistico>> getPedidos(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.pedidos();
    }
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/pedidos'),
      headers: _headers(bearer),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => PedidoLogistico.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar pedidos (${res.statusCode})');
  }

  Future<RiscoLogistico> recalcularRisco(String bearer, PedidoLogistico p) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return MockData.calcularRisco(p);
    }
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/entregas/${p.id}/recalcular-risco'),
      headers: _headers(bearer),
    );
    if (res.statusCode == 200) {
      return RiscoLogistico.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao recalcular risco (${res.statusCode})');
  }

  Future<Map<String, String>> perguntarAssistente(
      String bearer, int pedidoId, String pergunta) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return MockData.respostaAssistente(pergunta);
    }
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/assistente-logistico/pergunta'),
      headers: _headers(bearer),
      body: jsonEncode({'pedidoId': pedidoId, 'pergunta': pergunta}),
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return {
        'resposta': j['resposta'] ?? '',
        'acaoRecomendada': j['acaoRecomendada'] ?? '',
      };
    }
    throw Exception('Erro no assistente (${res.statusCode})');
  }
}
