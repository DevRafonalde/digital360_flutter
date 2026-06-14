import 'package:flutter/foundation.dart';
import '../data/models/pedido_logistico.dart';
import '../data/services/api_service.dart';
import '../data/services/notification_service.dart';

/// Estado da camada AI Logistics Extension.
class LogisticaProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool carregando = false;
  String? erro;
  List<PedidoLogistico> pedidos = [];
  final Map<int, RiscoLogistico> riscos = {};

  Future<void> carregar(String bearer) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      pedidos = await _api.getPedidos(bearer);
    } catch (e) {
      erro = e.toString().replaceAll('Exception: ', '');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// Recalcula o risco e, se ALTO/CRITICO, dispara notificacao local
  /// simulando um alerta do sistema (Parte 6).
  Future<RiscoLogistico> recalcularRisco(String bearer, PedidoLogistico p) async {
    final risco = await _api.recalcularRisco(bearer, p);
    riscos[p.id] = risco;
    notifyListeners();

    if (risco.riscoNivel == 'ALTO' || risco.riscoNivel == 'CRITICO') {
      await NotificationService.instance.mostrarNotificacao(
        titulo: 'Alerta de entrega - ${p.codigoPedido}',
        corpo:
            'Risco ${risco.riscoNivel} (${risco.riscoScore}). ${risco.recomendacao}',
      );
    }
    return risco;
  }

  Future<Map<String, String>> perguntar(
          String bearer, int pedidoId, String pergunta) =>
      _api.perguntarAssistente(bearer, pedidoId, pergunta);
}
