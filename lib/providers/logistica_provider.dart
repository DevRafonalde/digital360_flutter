import 'package:flutter/foundation.dart';
import '../data/models/pedido_logistico.dart';
import '../data/services/api_service.dart';
import '../data/services/notification_service.dart';

/// Estado da camada AI Logistics Extension.
class LogisticaProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool carregando = false;
  String? erro;
  List<PedidoLogistico> pedidos = [];
  final Map<int, RiscoLogistico> riscos = {};
  bool notificacoesAtivas = true;

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      pedidos = await _api.getPedidos(bearer);
    } catch (e) {
      erro = _mensagemAmigavel(e);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// Recalcula o risco e, se ALTO/CRITICO, dispara notificacao local
  /// simulando um alerta do sistema (Parte 6). [impactoClima] (0-25) vem do
  /// clima consultado na tela de detalhe e agora entra de verdade na conta.
  Future<RiscoLogistico> recalcularRisco(String bearer, PedidoLogistico p, {int impactoClima = 0}) async {
    final risco = await _api.recalcularRisco(bearer, p, impactoClima: impactoClima);
    riscos[p.id] = risco;
    notifyListeners();

    if (notificacoesAtivas && (risco.riscoNivel == 'ALTO' || risco.riscoNivel == 'CRITICO')) {
      await NotificationService.instance.mostrarNotificacao(
        titulo: 'Alerta de entrega - ${p.codigoPedido}',
        corpo:
            'Risco ${risco.riscoNivel} (${risco.riscoScore}). ${risco.recomendacao}',
        payload: p.id.toString(),
      );
    }
    return risco;
  }

  Future<Map<String, String>> perguntar(
          String bearer, int pedidoId, String pergunta) =>
      _api.perguntarAssistente(bearer, pedidoId, pergunta);

  /// Reagenda a entrega - a acao que o motor de risco recomenda quando o
  /// nivel e ALTO/CRITICO, mas que antes nao existia em lugar nenhum da UI.
  Future<void> reagendar(String bearer, PedidoLogistico p) async {
    await _api.reagendarEntrega(bearer, p);
    riscos.remove(p.id); // risco antigo nao vale mais apos reagendar
    notifyListeners();
  }

  Future<void> enviarFeedback(String bearer, int pedidoId, int nota, String? comentario) =>
      _api.enviarFeedback(bearer, pedidoId, nota, comentario);

  Future<List<Map<String, dynamic>>> carregarTendencias(String bearer) =>
      _api.getTendencias(bearer);

  void definirNotificacoesAtivas(bool ativo) {
    notificacoesAtivas = ativo;
    notifyListeners();
  }

  String _mensagemAmigavel(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('TimeoutException') || msg.contains('SocketException')) {
      return 'Sem conexão no momento. Mostrando o que já temos salvo.';
    }
    return 'Não conseguimos atualizar seus pedidos agora.';
  }
}
