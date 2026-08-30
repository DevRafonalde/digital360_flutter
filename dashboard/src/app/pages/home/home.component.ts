import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import { CursoService } from '../../core/services/curso.service';
import { PedidoService } from '../../core/services/pedido.service';
import { ServicoService } from '../../core/services/servico.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss',
})
export class HomeComponent implements OnInit {
  totalCursos = signal(0);
  totalServicos = signal(0);
  totalPedidos = signal(0);
  pedidosAtrasados = signal(0);
  carregando = signal(true);
  erro = signal<string | null>(null);

  constructor(
    private cursoService: CursoService,
    private servicoService: ServicoService,
    private pedidoService: PedidoService,
  ) {}

  ngOnInit(): void {
    forkJoin({
      cursos: this.cursoService.listar(),
      servicos: this.servicoService.listar(),
      pedidos: this.pedidoService.listar(),
    }).subscribe({
      next: ({ cursos, servicos, pedidos }) => {
        this.totalCursos.set(cursos.length);
        this.totalServicos.set(servicos.length);
        this.totalPedidos.set(pedidos.length);
        this.pedidosAtrasados.set(pedidos.filter((p) => p.statusAtual === 'ATRASADO').length);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar os dados. Verifique se o backend esta rodando em ' +
          'http://localhost:8080.');
        this.carregando.set(false);
      },
    });
  }
}
