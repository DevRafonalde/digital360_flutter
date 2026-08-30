import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PedidoLogistico, PedidoRequest, RiscoLogistico } from '../../core/models/pedido.model';
import { PedidoService } from '../../core/services/pedido.service';

const PEDIDO_VAZIO: PedidoRequest = {
  codigoPedido: '',
  produto: '',
  tipoProduto: '',
  regiaoEntrega: '',
  distanciaKm: 1,
  prazoPrometido: '',
  statusAtual: 'PENDENTE',
  parceiroLogistico: '',
  estoqueDisponivel: true,
  historicoAtrasos: 0,
  reagendamentos: 0,
  latitude: -23.5505,
  longitude: -46.6333,
};

@Component({
  selector: 'app-pedidos',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './pedidos.component.html',
  styleUrl: './pedidos.component.scss',
})
export class PedidosComponent implements OnInit {
  pedidos = signal<PedidoLogistico[]>([]);
  carregando = signal(true);
  erro = signal<string | null>(null);
  mostrarFormulario = signal(false);

  /** Ultimo risco calculado por pedido, para exibir na linha sem sair da tela. */
  riscoPorPedido = signal<Record<number, RiscoLogistico>>({});

  formulario: PedidoRequest = { ...PEDIDO_VAZIO };

  constructor(private pedidoService: PedidoService) {}

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.pedidoService.listar().subscribe({
      next: (pedidos) => {
        this.pedidos.set(pedidos);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar os pedidos.');
        this.carregando.set(false);
      },
    });
  }

  abrirFormulario(): void {
    this.formulario = { ...PEDIDO_VAZIO };
    this.mostrarFormulario.set(true);
  }

  cancelar(): void {
    this.mostrarFormulario.set(false);
  }

  salvar(): void {
    this.pedidoService.criar(this.formulario).subscribe({
      next: () => {
        this.mostrarFormulario.set(false);
        this.carregar();
      },
      error: () => this.erro.set('Nao foi possivel criar o pedido. Confira os campos e sua permissao de ADMIN.'),
    });
  }

  remover(pedido: PedidoLogistico): void {
    if (!confirm(`Remover o pedido "${pedido.codigoPedido}"?`)) return;

    this.pedidoService.remover(pedido.id).subscribe({
      next: () => this.carregar(),
      error: () => this.erro.set('Nao foi possivel remover o pedido.'),
    });
  }

  recalcularRisco(pedido: PedidoLogistico): void {
    this.pedidoService.recalcularRisco(pedido.id).subscribe({
      next: (risco) => this.riscoPorPedido.update((mapa) => ({ ...mapa, [pedido.id]: risco })),
      error: () => this.erro.set('Nao foi possivel recalcular o risco deste pedido.'),
    });
  }

  reagendar(pedido: PedidoLogistico): void {
    this.pedidoService.reagendar(pedido.id).subscribe({
      next: () => this.carregar(),
      error: () => this.erro.set('Nao foi possivel reagendar este pedido.'),
    });
  }
}
