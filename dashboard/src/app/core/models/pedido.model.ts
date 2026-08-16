export interface PedidoLogistico {
  id: number;
  codigoPedido: string;
  produto: string;
  tipoProduto: string;
  regiaoEntrega: string;
  distanciaKm: number;
  prazoPrometido: string;
  statusAtual: 'PENDENTE' | 'EM_TRANSITO' | 'ENTREGUE' | 'ATRASADO';
  parceiroLogistico: string;
  estoqueDisponivel: boolean;
  historicoAtrasos: number;
  reagendamentos: number;
  latitude: number;
  longitude: number;
}

export type PedidoRequest = Omit<PedidoLogistico, 'id'>;

export interface RiscoLogistico {
  pedidoId: number;
  riscoScore: number;
  riscoNivel: 'BAIXO' | 'MEDIO' | 'ALTO' | 'CRITICO';
  recomendacao: string;
  mensagemCliente: string;
}
