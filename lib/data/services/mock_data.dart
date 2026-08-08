import '../models/curso.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/pedido_logistico.dart';

/// Dados simulados para o app rodar sem backend (avaliacao / demo).
/// Coordenadas reais de Sao Paulo para a tela de mapas.
class MockData {
  static Usuario usuario(String nomeUser) => Usuario(
        id: 1,
        nomeAmigavel: nomeUser.isEmpty ? 'Visitante' : nomeUser,
        nomeUser: nomeUser,
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      );

  static List<Curso> cursos() => [
        Curso(
          id: 1,
          titulo: 'Primeiros passos no celular',
          descricao: 'Aprenda a usar o smartphone com segurança e confiança.',
          nivel: 'BASICO',
          cargaHoraria: 4,
          totalModulos: 6,
          progresso: 75,
        ),
        Curso(
          id: 2,
          titulo: 'Usando o gov.br',
          descricao: 'Acesse serviços públicos digitais sem complicação.',
          nivel: 'INTERMEDIARIO',
          cargaHoraria: 6,
          totalModulos: 8,
          progresso: 30,
        ),
        Curso(
          id: 3,
          titulo: 'Segurança digital e golpes',
          descricao: 'Identifique fraudes e proteja seus dados pessoais.',
          nivel: 'INTERMEDIARIO',
          cargaHoraria: 5,
          totalModulos: 7,
          progresso: 0,
        ),
        Curso(
          id: 4,
          titulo: 'Pix e pagamentos digitais',
          descricao: 'Faça transferências e pagamentos com tranquilidade.',
          nivel: 'AVANCADO',
          cargaHoraria: 8,
          totalModulos: 10,
          progresso: 10,
        ),
      ];

  /// Espelha heuristics.py::gerar_rascunho_curso do backend real - mesmo
  /// template por regra fixa (NAO IA generativa), pro modo mock e o modo
  /// real terem o mesmo comportamento de demo.
  static List<String> gerarRascunhoCurso(String titulo, String nivel) {
    final tituloNormalizado = titulo.trim().isEmpty ? 'este assunto' : titulo.trim();
    final modulos = <String>[
      'Introdução: por que aprender $tituloNormalizado',
      'Passo a passo com exemplos práticos',
      'Erros comuns e como evitá-los',
    ];
    if (nivel.toUpperCase() == 'INTERMEDIARIO' || nivel.toUpperCase() == 'AVANCADO') {
      modulos.add('Aprofundando: casos do dia a dia');
    }
    if (nivel.toUpperCase() == 'AVANCADO') {
      modulos.add('Cenários avançados e exceções');
    }
    modulos.add('Prática guiada e revisão final');
    return modulos;
  }

  /// Espelha GET /metricas/impacto do backend real - numeros da sessao mock
  /// atual (demo), rotulados honestamente como tal, nunca uma alegacao de
  /// escala real.
  static Map<String, dynamic> metricasImpacto({
    required int cursosConcluidos,
    required int cursosComunidade,
    required int perguntasForum,
  }) =>
      {
        'totalUsuarios': 1,
        'totalCursosConcluidos': cursosConcluidos,
        'totalCursosPublicados': cursos().length + cursosComunidade,
        'totalCursosComunidade': cursosComunidade,
        'totalPerguntasForum': perguntasForum,
        'observacao':
            'Números da sessão de demonstração atual (modo mock, sem backend), não uma métrica de escala real.',
      };

  static List<Servico> servicos() => [
        Servico(
          id: 1,
          titulo: 'Consultar benefício do INSS',
          descricao: 'Veja extrato e situação de aposentadoria/auxílio.',
          categoria: 'Previdência',
          orgao: 'INSS',
          conteudo:
              'Acesse o aplicativo Meu INSS, faça login com sua conta gov.br '
              'e selecione "Extrato de pagamento" para consultar seu benefício.',
        ),
        Servico(
          id: 2,
          titulo: 'Agendar consulta no SUS',
          descricao: 'Marque atendimento na unidade de saúde mais próxima.',
          categoria: 'Saúde',
          orgao: 'SUS',
          conteudo:
              'Use o app Conecte SUS ou procure a UBS do seu bairro com o '
              'Cartão Nacional de Saúde para agendar sua consulta.',
        ),
        Servico(
          id: 3,
          titulo: 'Emitir 2ª via do RG/CPF',
          descricao: 'Solicite documentos pelo portal gov.br.',
          categoria: 'Documentos',
          orgao: 'gov.br',
          conteudo:
              'No portal gov.br, busque por "2a via" do documento desejado e '
              'siga as instruções. Alguns serviços são gratuitos.',
        ),
        Servico(
          id: 4,
          titulo: 'Consultar Bolsa Família',
          descricao: 'Verifique calendário e valor do benefício.',
          categoria: 'Assistência Social',
          orgao: 'Caixa',
          conteudo:
              'Use o app Bolsa Família ou Caixa Tem para consultar o '
              'calendário de pagamentos e o valor do seu benefício.',
        ),
      ];

  static List<PedidoLogistico> pedidos() => [
        PedidoLogistico(
          id: 1,
          codigoPedido: 'LM-2026-0001',
          produto: 'Kit ferramentas basicas',
          tipoProduto: 'Ferramentas',
          regiaoEntrega: 'Sao Paulo - Centro',
          distanciaKm: 8,
          prazoPrometido: '16/06/2026',
          statusAtual: 'EM_TRANSITO',
          parceiroLogistico: 'Loggi',
          estoqueDisponivel: true,
          historicoAtrasos: 0,
          reagendamentos: 0,
          latitude: -23.5505,
          longitude: -46.6333,
        ),
        PedidoLogistico(
          id: 2,
          codigoPedido: 'LM-2026-0002',
          produto: 'Tinta acrilica 18L',
          tipoProduto: 'Pintura',
          regiaoEntrega: 'Sao Paulo - Zona Leste',
          distanciaKm: 22,
          prazoPrometido: '15/06/2026',
          statusAtual: 'ATRASADO',
          parceiroLogistico: 'Total Express',
          estoqueDisponivel: false,
          historicoAtrasos: 3,
          reagendamentos: 2,
          latitude: -23.5400,
          longitude: -46.4900,
        ),
        PedidoLogistico(
          id: 3,
          codigoPedido: 'LM-2026-0003',
          produto: 'Furadeira de impacto',
          tipoProduto: 'Ferramentas eletricas',
          regiaoEntrega: 'Sao Paulo - Zona Sul',
          distanciaKm: 14,
          prazoPrometido: '18/06/2026',
          statusAtual: 'PENDENTE',
          parceiroLogistico: 'Correios',
          estoqueDisponivel: true,
          historicoAtrasos: 1,
          reagendamentos: 0,
          latitude: -23.6500,
          longitude: -46.7000,
        ),
        PedidoLogistico(
          id: 4,
          codigoPedido: 'LM-2026-0004',
          produto: 'Piso laminado (10 caixas)',
          tipoProduto: 'Revestimento',
          regiaoEntrega: 'Sao Paulo - Zona Norte',
          distanciaKm: 19,
          prazoPrometido: '14/06/2026',
          statusAtual: 'ENTREGUE',
          parceiroLogistico: 'Loggi',
          estoqueDisponivel: true,
          historicoAtrasos: 0,
          reagendamentos: 0,
          latitude: -23.4800,
          longitude: -46.6200,
        ),
      ];

  /// Heuristica de risco identica em espirito ao motor do backend (regras).
  /// [impactoClima] (0-25) vem do clima consultado via Open-Meteo na tela de
  /// detalhe - chuva/vento realmente aumentam o score, nao sao so texto.
  static RiscoLogistico calcularRisco(PedidoLogistico p, {int impactoClima = 0}) {
    int score = 0;
    score += p.historicoAtrasos * 18;
    score += p.reagendamentos * 12;
    score += p.estoqueDisponivel ? 0 : 25;
    score += p.distanciaKm > 20 ? 15 : (p.distanciaKm > 10 ? 8 : 0);
    if (p.statusAtual == 'ATRASADO') score += 20;
    score += impactoClima.clamp(0, 25);
    if (score > 100) score = 100;

    String nivel;
    String rec;
    if (score >= 75) {
      nivel = 'CRITICO';
      rec = 'Acionar suporte logístico e oferecer reagendamento proativo.';
    } else if (score >= 50) {
      nivel = 'ALTO';
      rec = 'Monitorar de perto e comunicar o cliente sobre possível atraso.';
    } else if (score >= 25) {
      nivel = 'MEDIO';
      rec = 'Acompanhar a entrega no próximo ciclo de atualização.';
    } else {
      nivel = 'BAIXO';
      rec = 'Entrega dentro do esperado. Nenhuma ação necessária.';
    }
    return RiscoLogistico(
      pedidoId: p.id,
      riscoScore: score,
      riscoNivel: nivel,
      recomendacao: rec,
      mensagemCliente: score >= 50
          ? 'Detectamos fatores que podem afetar a janela prometida.'
          : 'Sua entrega está dentro do prazo previsto.',
    );
  }

  static Map<String, String> respostaAssistente(String pergunta) {
    final q = pergunta.toLowerCase();
    if (q.contains('atras')) {
      return {
        'resposta':
            'Identificamos risco elevado neste pedido. Recomendamos acionar o '
            'suporte logístico antes do prazo para um reagendamento proativo.',
        'acaoRecomendada': 'REAGENDAR',
      };
    }
    if (q.contains('prazo') || q.contains('quando')) {
      return {
        'resposta':
            'O prazo prometido segue válido. Você receberá uma notificação '
            'caso haja qualquer alteração na janela de entrega.',
        'acaoRecomendada': 'AGUARDAR',
      };
    }
    return {
      'resposta':
          'Estou acompanhando seu pedido em tempo real. Posso ajudar com '
          'prazo, status, risco de atraso ou reagendamento.',
      'acaoRecomendada': 'INFORMAR',
    };
  }

  /// Categorias em alta (deteccao de picos/sazonalidade) - espelha o formato
  /// do endpoint real GET /tendencias do backend. Nomes de categoria
  /// identicos aos usados em Servico.categoria (mesma acentuacao).
  static List<Map<String, dynamic>> tendencias() => [
        {
          'categoria': 'Previdência',
          'volumeUltimos7Dias': 34,
          'mediaHistoricaDiaria': 2.1,
          'emAlta': true,
        },
        {
          'categoria': 'Documentos',
          'volumeUltimos7Dias': 9,
          'mediaHistoricaDiaria': 1.8,
          'emAlta': false,
        },
        {
          'categoria': 'Saúde',
          'volumeUltimos7Dias': 6,
          'mediaHistoricaDiaria': 1.2,
          'emAlta': false,
        },
      ];

  /// Top recomendacoes heuristicas - espelha o formato (cold-start) do
  /// endpoint real GET /recomendacoes/{userId} do backend: prioriza o
  /// curso de nivel BASICO e o primeiro servico quando o usuario nao tem
  /// historico de eventos ainda.
  static List<Map<String, dynamic>> recomendacoes() => [
        {
          'tipo': 'curso',
          'id': 1,
          'titulo': 'Primeiros passos no celular',
          'nivel': 'BASICO',
          'score': 100,
          'motivo': 'cold-start',
        },
        {
          'tipo': 'servico',
          'id': 1,
          'titulo': 'Consultar benefício do INSS',
          'categoria': 'Previdência',
          'score': 90,
          'motivo': 'cold-start',
        },
        {
          'tipo': 'curso',
          'id': 2,
          'titulo': 'Usando o gov.br',
          'nivel': 'INTERMEDIARIO',
          'score': 80,
          'motivo': 'cold-start',
        },
      ];
}
