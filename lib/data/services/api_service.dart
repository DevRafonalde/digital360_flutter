import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/avaliacao_curso.dart';
import '../models/curso.dart';
import '../models/pergunta_forum.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/pedido_logistico.dart';
import '../models/vinculo_cuidador.dart';
import 'mock_data.dart';

const _timeout = Duration(seconds: 10);

/// Camada cliente-servidor (Retrofit-equivalente em Flutter).
/// Implementa o contrato REST do backend Smart HAS sobre HTTP/HTTPS.
/// Com ApiConstants.useMock = true, retorna dados mock para rodar sem backend.
///
/// Singleton: uma unica instancia e compartilhada por todos os Providers,
/// em vez de cada um criar seu proprio ApiService (evita estado duplicado e
/// permite o hook de renovacao de sessao abaixo).
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

  // Cursos comunitarios criados em modo mock - vivem so na sessao (mesmo
  // principio do resto do modo mock: nada persiste entre reinicios do app).
  final List<Curso> _cursosComunidadeMock = [];
  int _proximoIdCursoMock = 1000;

  // Forum e gamificacao em modo mock - mesmo principio: estado so de sessao.
  final List<PerguntaForum> _perguntasMock = [];
  int _proximoIdPerguntaMock = 1;
  final Map<String, int> _cursosConcluidosMock = {}; // userId -> contagem

  // Cuidador, indicacao e avaliacoes em modo mock - mesmo principio.
  final Map<String, List<VinculoCuidador>> _vinculosCuidadorMock = {}; // cuidadorId -> vinculos
  final Map<String, int> _indicacoesMock = {}; // userId -> total
  final Map<int, List<AvaliacaoCurso>> _avaliacoesCursoMock = {}; // cursoId -> avaliacoes
  int _proximoIdAvaliacaoMock = 1;

  /// Registrado pelo AuthProvider: quando uma chamada autenticada recebe
  /// 401, tenta renovar a sessao (refresh token) e devolve o novo bearer
  /// para uma unica nova tentativa. Retorna null se nao foi possivel renovar.
  Future<String?> Function()? onUnauthorized;

  Map<String, String> _headers([String? bearer]) => {
        'Content-Type': 'application/json',
        if (bearer != null) 'Authorization': bearer,
      };

  Future<http.Response> _getComRenovacao(Uri uri, String bearer) async {
    var res = await _client.get(uri, headers: _headers(bearer)).timeout(_timeout);
    if (res.statusCode == 401 && onUnauthorized != null) {
      final novoBearer = await onUnauthorized!();
      if (novoBearer != null) {
        res = await _client.get(uri, headers: _headers(novoBearer)).timeout(_timeout);
      }
    }
    return res;
  }

  Future<http.Response> _deleteComRenovacao(Uri uri, String bearer) async {
    var res = await _client.delete(uri, headers: _headers(bearer)).timeout(_timeout);
    if (res.statusCode == 401 && onUnauthorized != null) {
      final novoBearer = await onUnauthorized!();
      if (novoBearer != null) {
        res = await _client.delete(uri, headers: _headers(novoBearer)).timeout(_timeout);
      }
    }
    return res;
  }

  Future<http.Response> _postComRenovacao(Uri uri, String bearer, {Object? body}) async {
    final encoded = body == null ? null : jsonEncode(body);
    var res = await _client.post(uri, headers: _headers(bearer), body: encoded).timeout(_timeout);
    if (res.statusCode == 401 && onUnauthorized != null) {
      final novoBearer = await onUnauthorized!();
      if (novoBearer != null) {
        res = await _client.post(uri, headers: _headers(novoBearer), body: encoded).timeout(_timeout);
      }
    }
    return res;
  }

  // ---- Autenticacao ----
  Future<Usuario> login(String nomeUser, String senha) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (senha.isEmpty) {
        throw Exception('Senha invalida');
      }
      return MockData.usuario(nomeUser);
    }
    final res = await _client
        .post(
          Uri.parse('${ApiConstants.baseUrl}/auth/usuarios/login'),
          headers: _headers(),
          body: jsonEncode({'nomeUser': nomeUser, 'senhaUser': senha}),
        )
        .timeout(_timeout);
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
    final res = await _client
        .post(
          Uri.parse('${ApiConstants.baseUrl}/auth/usuarios/registrar'),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      throw Exception('Falha no cadastro (${res.statusCode})');
    }
  }

  /// Renova o access token a partir do refresh token. Em modo mock, apenas
  /// gera novos tokens simulados (nunca falha) - em modo real, chama
  /// POST /auth/refresh no backend.
  Future<Usuario> refresh(Usuario atual) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return Usuario(
        id: atual.id,
        nomeAmigavel: atual.nomeAmigavel,
        nomeUser: atual.nomeUser,
        accessToken: 'mock-access-token-renovado',
        refreshToken: 'mock-refresh-token-renovado',
        cpf: atual.cpf,
        nomeCompleto: atual.nomeCompleto,
      );
    }
    final res = await _client
        .post(
          Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
          headers: _headers(),
          body: jsonEncode({'refreshToken': atual.refreshToken}),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return Usuario(
        id: atual.id,
        nomeAmigavel: atual.nomeAmigavel,
        nomeUser: atual.nomeUser,
        accessToken: j['accessToken'],
        refreshToken: j['refreshToken'],
        cpf: atual.cpf,
        nomeCompleto: atual.nomeCompleto,
      );
    }
    throw Exception('Nao foi possivel renovar a sessao (${res.statusCode})');
  }

  /// Recuperacao de senha - mensagem generica (nao revela se o usuario
  /// existe), seguindo boa pratica de seguranca.
  Future<void> solicitarRecuperacaoSenha(String nomeUser) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // MVP mock: nao ha envio real de e-mail/SMS. Em producao, chamaria
    // POST /auth/recuperar-senha no backend.
  }

  // ---- Cursos ----
  Future<List<Curso>> getCursos(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [...MockData.cursos(), ..._cursosComunidadeMock];
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/cursos'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Curso.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar cursos (${res.statusCode})');
  }

  /// Auto-atribuicao do papel de tutor - sem fila de aprovacao (Nivel 2+4).
  Future<bool> tornarTutor(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/perfil/tornar-tutor'),
      bearer,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['isTutor'] ?? true;
    }
    throw Exception('Erro ao tornar-se tutor (${res.statusCode})');
  }

  /// Estrutura inicial de modulos por TEMPLATE (heuristica por regra fixa,
  /// nao IA generativa - ver heuristics.py::gerar_rascunho_curso). Serve so
  /// como ponto de partida pro tutor revisar e editar antes de publicar.
  Future<List<String>> gerarRascunhoCurso(String bearer, String titulo, String nivel) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return MockData.gerarRascunhoCurso(titulo, nivel);
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cursos/gerar-rascunho'),
      bearer,
      body: {'titulo': titulo, 'nivel': nivel},
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      return (j['topicosSugeridos'] as List).map((e) => e.toString()).toList();
    }
    throw Exception('Erro ao gerar rascunho do curso (${res.statusCode})');
  }

  /// Cria e publica direto um curso comunitario (sem fila de moderacao,
  /// conforme decisao do grupo pro MVP).
  Future<Curso> criarCurso(String bearer, Curso rascunho, {required String autorId}) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      final criado = Curso(
        id: _proximoIdCursoMock++,
        titulo: rascunho.titulo,
        descricao: rascunho.descricao,
        nivel: rascunho.nivel,
        cargaHoraria: rascunho.cargaHoraria,
        totalModulos: rascunho.topicosModulos.length,
        autorId: autorId,
        origem: 'COMUNIDADE',
        status: 'PUBLICADO',
        topicosModulos: rascunho.topicosModulos,
      );
      _cursosComunidadeMock.add(criado);
      return criado;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cursos'),
      bearer,
      body: rascunho.toJson(),
    );
    if (res.statusCode == 201) {
      return Curso.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao publicar curso (${res.statusCode})');
  }

  /// Cursos do proprio tutor (inclui rascunhos - hoje o app so cria
  /// publicados direto, mas o backend ja suporta o campo status).
  Future<List<Curso>> getMeusCursos(String bearer, String autorId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _cursosComunidadeMock.where((c) => c.autorId == autorId).toList();
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/cursos/meus'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Curso.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar meus cursos (${res.statusCode})');
  }

  // ---- Guia de Servicos ----
  Future<List<Servico>> getServicos(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.servicos();
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/servicos'), bearer);
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
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/pedidos'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => PedidoLogistico.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar pedidos (${res.statusCode})');
  }

  /// [impactoClima] (0-25) e somado ao score de risco quando informado - e
  /// assim que o clima consultado na tela de detalhe passa a influenciar de
  /// verdade o calculo, e nao apenas aparecer como texto informativo.
  Future<RiscoLogistico> recalcularRisco(String bearer, PedidoLogistico p, {int impactoClima = 0}) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return MockData.calcularRisco(p, impactoClima: impactoClima);
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/entregas/${p.id}/recalcular-risco'),
      bearer,
      body: {'impactoClima': impactoClima},
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
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/assistente-logistico/pergunta'),
      bearer,
      body: {'pedidoId': pedidoId, 'pergunta': pergunta},
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

  /// Reagenda uma entrega (acao recomendada pelo motor de risco quando
  /// ALTO/CRITICO). Incrementa reagendamentos e volta o status para PENDENTE.
  Future<PedidoLogistico> reagendarEntrega(String bearer, PedidoLogistico p) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      p.reagendamentos += 1;
      p.statusAtual = 'PENDENTE';
      return p;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/pedidos/${p.id}/reagendar'),
      bearer,
    );
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      p.reagendamentos = j['reagendamentos'] ?? (p.reagendamentos + 1);
      p.statusAtual = j['statusAtual'] ?? 'PENDENTE';
      return p;
    }
    throw Exception('Erro ao reagendar entrega (${res.statusCode})');
  }

  /// Registra a avaliacao do cliente apos a entrega/atendimento.
  Future<void> enviarFeedback(String bearer, int pedidoId, int nota, String? comentario) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/feedback-entrega'),
      bearer,
      body: {'pedidoId': pedidoId, 'nota': nota, 'comentario': comentario},
    );
    if (res.statusCode >= 400) {
      throw Exception('Erro ao enviar feedback (${res.statusCode})');
    }
  }

  /// Categorias em alta (deteccao de picos/sazonalidade) - motor heuristico
  /// do backend real da AI Logistics Extension.
  Future<List<Map<String, dynamic>>> getTendencias(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.tendencias();
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/tendencias'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao carregar tendencias (${res.statusCode})');
  }

  /// Top recomendacoes heuristicas (frequencia + novidade + nivel) para o
  /// usuario - motor real do backend, sem tela nenhuma consumindo ele ate
  /// esta correcao.
  Future<List<Map<String, dynamic>>> getRecomendacoes(String bearer, String userId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.recomendacoes();
    }
    final res = await _getComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/recomendacoes/$userId'),
      bearer,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao carregar recomendações (${res.statusCode})');
  }

  /// Registra um evento de uso (curso/servico visitado, ou "curso_concluido"
  /// pra gamificacao) - alimenta o motor de recomendacao, a deteccao de
  /// sazonalidade e o resumo de gamificacao. Disparado silenciosamente (nao
  /// bloqueia a navegacao do usuario nem mostra erro se falhar).
  Future<void> registrarEvento(
    String bearer, {
    required String userId,
    required String tipo,
    required int referenceId,
    String? categoria,
  }) async {
    if (ApiConstants.useMock) {
      // Em modo mock nao ha uma lista de eventos pra recomendar/tendencias
      // reconstruir, mas a gamificacao precisa contar conclusoes de curso
      // pra tela nao ficar sempre zerada na demo.
      if (tipo == 'curso_concluido') {
        _cursosConcluidosMock[userId] = (_cursosConcluidosMock[userId] ?? 0) + 1;
      }
      return;
    }
    try {
      await _postComRenovacao(
        Uri.parse('${ApiConstants.baseUrl}/eventos'),
        bearer,
        body: {'userId': userId, 'tipo': tipo, 'referenceId': referenceId, 'categoria': categoria},
      );
    } catch (_) {/* evento e best-effort - nunca deve quebrar a navegacao */}
  }

  // ---- Forum da comunidade ----
  Future<PerguntaForum> criarPergunta(String bearer, String autorNome, String titulo, String corpo) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final criada = PerguntaForum(
        id: _proximoIdPerguntaMock++,
        autorNome: autorNome,
        titulo: titulo,
        corpo: corpo,
        criadoEm: DateTime.now().toIso8601String(),
        totalRespostas: 0,
      );
      _perguntasMock.insert(0, criada);
      return criada;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/forum/perguntas'),
      bearer,
      body: {'titulo': titulo, 'corpo': corpo},
    );
    if (res.statusCode == 201) {
      return PerguntaForum.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao criar pergunta (${res.statusCode})');
  }

  Future<List<PerguntaForum>> getPerguntas(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return List.unmodifiable(_perguntasMock);
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/forum/perguntas'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => PerguntaForum.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar perguntas (${res.statusCode})');
  }

  Future<PerguntaForum> getDetalhePergunta(String bearer, int perguntaId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _perguntasMock.firstWhere((p) => p.id == perguntaId);
    }
    final res = await _getComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/forum/perguntas/$perguntaId'),
      bearer,
    );
    if (res.statusCode == 200) {
      return PerguntaForum.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao carregar a pergunta (${res.statusCode})');
  }

  Future<PerguntaForum> responderPergunta(
      String bearer, int perguntaId, String autorNome, String corpo) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _perguntasMock.indexWhere((p) => p.id == perguntaId);
      if (idx == -1) throw Exception('Pergunta não encontrada');
      final atual = _perguntasMock[idx];
      final novaResposta = RespostaForum(
        id: atual.respostas.length + 1,
        autorNome: autorNome,
        corpo: corpo,
        criadoEm: DateTime.now().toIso8601String(),
      );
      final atualizada = PerguntaForum(
        id: atual.id,
        autorNome: atual.autorNome,
        titulo: atual.titulo,
        corpo: atual.corpo,
        criadoEm: atual.criadoEm,
        totalRespostas: atual.totalRespostas + 1,
        respostas: [...atual.respostas, novaResposta],
      );
      _perguntasMock[idx] = atualizada;
      return atualizada;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/forum/perguntas/$perguntaId/respostas'),
      bearer,
      body: {'corpo': corpo},
    );
    if (res.statusCode == 201) {
      return getDetalhePergunta(bearer, perguntaId);
    }
    throw Exception('Erro ao responder (${res.statusCode})');
  }

  // ---- Gamificacao ----
  Future<Map<String, int>> getResumoGamificacao(String bearer, String userId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final cursosConcluidos = _cursosConcluidosMock[userId] ?? 0;
      const sequenciaDias = 1; // sem historico real de datas em modo mock
      return {
        'cursosConcluidos': cursosConcluidos,
        'sequenciaDias': cursosConcluidos > 0 ? sequenciaDias : 0,
        'pontos': cursosConcluidos * 100 + (cursosConcluidos > 0 ? sequenciaDias * 10 : 0),
      };
    }
    final res = await _getComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/gamificacao/$userId/resumo'),
      bearer,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map).cast<String, int>();
    }
    throw Exception('Erro ao carregar seu resumo (${res.statusCode})');
  }

  Future<List<Map<String, dynamic>>> getRankingGamificacao(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _cursosConcluidosMock.entries
          .where((e) => e.value > 0)
          .map((e) => {
                'nomeAmigavel': e.key,
                'cursosConcluidos': e.value,
                'sequenciaDias': 1,
                'pontos': e.value * 100 + 10,
              })
          .toList()
        ..sort((a, b) => (b['pontos'] as int).compareTo(a['pontos'] as int));
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/gamificacao/ranking'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ao carregar o ranking (${res.statusCode})');
  }

  // ---- Painel de impacto ----
  Future<Map<String, dynamic>> getMetricasImpacto(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return MockData.metricasImpacto(
        cursosConcluidos: _cursosConcluidosMock.values.fold(0, (a, b) => a + b),
        cursosComunidade: _cursosComunidadeMock.length,
        perguntasForum: _perguntasMock.length,
      );
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/metricas/impacto'), bearer);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar as métricas de impacto (${res.statusCode})');
  }

  // ---- Modo cuidador (somente leitura) ----
  Future<void> vincularCuidador(String bearer, String cuidadorId, String codigoIdoso) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (codigoIdoso == cuidadorId) throw Exception('Você não pode se vincular a si mesmo');
      final vinculos = _vinculosCuidadorMock.putIfAbsent(cuidadorId, () => []);
      if (vinculos.any((v) => v.idosoId == codigoIdoso)) {
        throw Exception('Vínculo já existe');
      }
      vinculos.add(VinculoCuidador(idosoId: codigoIdoso, idosoNome: codigoIdoso));
      return;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cuidador/vincular'),
      bearer,
      body: {'codigoIdoso': codigoIdoso},
    );
    if (res.statusCode >= 400) {
      throw Exception('Erro ao vincular (${res.statusCode})');
    }
  }

  Future<List<VinculoCuidador>> getVinculosCuidador(String bearer, String cuidadorId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List.unmodifiable(_vinculosCuidadorMock[cuidadorId] ?? const []);
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/cuidador/vinculos'), bearer);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => VinculoCuidador.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar vínculos (${res.statusCode})');
  }

  Future<ResumoIdoso> getResumoIdoso(String bearer, String idosoId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final cursosConcluidos = _cursosConcluidosMock[idosoId] ?? 0;
      return ResumoIdoso(
        idosoNome: idosoId,
        cursosConcluidos: cursosConcluidos,
        sequenciaDias: cursosConcluidos > 0 ? 1 : 0,
        pontos: cursosConcluidos * 100 + (cursosConcluidos > 0 ? 10 : 0),
      );
    }
    final res = await _getComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cuidador/$idosoId/resumo'),
      bearer,
    );
    if (res.statusCode == 200) {
      return ResumoIdoso.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao carregar o resumo (${res.statusCode})');
  }

  // ---- Indicacao ----
  Future<Map<String, dynamic>> getMinhasIndicacoes(String bearer, String userId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'codigo': userId, 'totalIndicacoes': _indicacoesMock[userId] ?? 0};
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/indicacoes/minhas'), bearer);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar suas indicações (${res.statusCode})');
  }

  // ---- Marketplace de tutores ----
  Future<void> avaliarCurso(String bearer, int cursoId, String usuarioNome, int nota, String? comentario) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final lista = _avaliacoesCursoMock.putIfAbsent(cursoId, () => []);
      lista.add(AvaliacaoCurso(
        id: _proximoIdAvaliacaoMock++,
        usuarioNome: usuarioNome,
        nota: nota,
        comentario: comentario,
      ));
      return;
    }
    final res = await _postComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cursos/$cursoId/avaliar'),
      bearer,
      body: {'nota': nota, 'comentario': comentario},
    );
    if (res.statusCode >= 400) {
      throw Exception('Erro ao avaliar (${res.statusCode})');
    }
  }

  Future<List<AvaliacaoCurso>> getAvaliacoesCurso(String bearer, int cursoId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.unmodifiable(_avaliacoesCursoMock[cursoId] ?? const []);
    }
    final res = await _getComRenovacao(
      Uri.parse('${ApiConstants.baseUrl}/cursos/$cursoId/avaliacoes'),
      bearer,
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => AvaliacaoCurso.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar avaliações (${res.statusCode})');
  }

  Future<PerfilTutor> getPerfilTutor(String bearer, String autorId) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final cursosDoTutor = _cursosComunidadeMock.where((c) => c.autorId == autorId).toList();
      final notas = [
        for (final c in cursosDoTutor) ...(_avaliacoesCursoMock[c.id] ?? const []).map((a) => a.nota),
      ];
      return PerfilTutor(
        nomeAmigavel: autorId,
        totalCursos: cursosDoTutor.length,
        mediaAvaliacao: notas.isEmpty ? null : notas.reduce((a, b) => a + b) / notas.length,
        totalAvaliacoes: notas.length,
      );
    }
    final res = await _getComRenovacao(Uri.parse('${ApiConstants.baseUrl}/tutores/$autorId'), bearer);
    if (res.statusCode == 200) {
      return PerfilTutor.fromJson(jsonDecode(res.body));
    }
    throw Exception('Erro ao carregar o perfil do tutor (${res.statusCode})');
  }

  // ---- LGPD: exclusao da propria conta ----
  Future<void> excluirConta(String bearer) async {
    if (ApiConstants.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    final res = await _deleteComRenovacao(Uri.parse('${ApiConstants.baseUrl}/perfil/conta'), bearer);
    if (res.statusCode >= 400) {
      throw Exception('Erro ao excluir a conta (${res.statusCode})');
    }
  }
}
