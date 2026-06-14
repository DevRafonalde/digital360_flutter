/// Pedido monitorado pela camada AI Logistics. Espelha PedidoLogisticoDTO.
class PedidoLogistico {
  final int id;
  final String codigoPedido;
  final String produto;
  final String tipoProduto;
  final String regiaoEntrega;
  final int distanciaKm;
  final String prazoPrometido;
  final String statusAtual; // PENDENTE | EM_TRANSITO | ENTREGUE | ATRASADO
  final String parceiroLogistico;
  final bool estoqueDisponivel;
  final int historicoAtrasos;
  final int reagendamentos;
  // Coordenadas para o mapa (Parte 5).
  final double latitude;
  final double longitude;

  PedidoLogistico({
    required this.id,
    required this.codigoPedido,
    required this.produto,
    required this.tipoProduto,
    required this.regiaoEntrega,
    required this.distanciaKm,
    required this.prazoPrometido,
    required this.statusAtual,
    required this.parceiroLogistico,
    required this.estoqueDisponivel,
    required this.historicoAtrasos,
    required this.reagendamentos,
    this.latitude = 0,
    this.longitude = 0,
  });

  factory PedidoLogistico.fromJson(Map<String, dynamic> json) => PedidoLogistico(
        id: json['id'],
        codigoPedido: json['codigoPedido'] ?? '',
        produto: json['produto'] ?? '',
        tipoProduto: json['tipoProduto'] ?? '',
        regiaoEntrega: json['regiaoEntrega'] ?? '',
        distanciaKm: json['distanciaKm'] ?? 0,
        prazoPrometido: json['prazoPrometido'] ?? '',
        statusAtual: json['statusAtual'] ?? 'PENDENTE',
        parceiroLogistico: json['parceiroLogistico'] ?? '',
        estoqueDisponivel: json['estoqueDisponivel'] ?? false,
        historicoAtrasos: json['historicoAtrasos'] ?? 0,
        reagendamentos: json['reagendamentos'] ?? 0,
        latitude: (json['latitude'] ?? 0).toDouble(),
        longitude: (json['longitude'] ?? 0).toDouble(),
      );
}

/// Resposta do recalculo de risco. Espelha RiscoLogisticoResponse.
class RiscoLogistico {
  final int pedidoId;
  final int riscoScore; // 0-100
  final String riscoNivel; // BAIXO | MEDIO | ALTO | CRITICO
  final String recomendacao;
  final String mensagemCliente;

  RiscoLogistico({
    required this.pedidoId,
    required this.riscoScore,
    required this.riscoNivel,
    required this.recomendacao,
    required this.mensagemCliente,
  });

  factory RiscoLogistico.fromJson(Map<String, dynamic> json) => RiscoLogistico(
        pedidoId: json['pedidoId'] ?? 0,
        riscoScore: json['riscoScore'] ?? 0,
        riscoNivel: json['riscoNivel'] ?? 'BAIXO',
        recomendacao: json['recomendacao'] ?? '',
        mensagemCliente: json['mensagemCliente'] ?? '',
      );
}
