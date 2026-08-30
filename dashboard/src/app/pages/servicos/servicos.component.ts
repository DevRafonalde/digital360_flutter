import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Servico, ServicoRequest } from '../../core/models/servico.model';
import { ServicoService } from '../../core/services/servico.service';

const SERVICO_VAZIO: ServicoRequest = {
  titulo: '',
  descricao: '',
  categoria: '',
  orgao: '',
  conteudo: '',
};

@Component({
  selector: 'app-servicos',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './servicos.component.html',
  styleUrl: './servicos.component.scss',
})
export class ServicosComponent implements OnInit {
  servicos = signal<Servico[]>([]);
  carregando = signal(true);
  erro = signal<string | null>(null);

  editandoId: number | null = null;
  formulario: ServicoRequest = { ...SERVICO_VAZIO };

  constructor(private servicoService: ServicoService) {}

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.servicoService.listar().subscribe({
      next: (servicos) => {
        this.servicos.set(servicos);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar o guia de servicos.');
        this.carregando.set(false);
      },
    });
  }

  editar(servico: Servico): void {
    this.editandoId = servico.id;
    this.formulario = {
      titulo: servico.titulo,
      descricao: servico.descricao,
      categoria: servico.categoria,
      orgao: servico.orgao,
      conteudo: servico.conteudo,
    };
  }

  cancelar(): void {
    this.editandoId = null;
    this.formulario = { ...SERVICO_VAZIO };
  }

  salvar(): void {
    const acao = this.editandoId
      ? this.servicoService.atualizar(this.editandoId, this.formulario)
      : this.servicoService.criar(this.formulario);

    acao.subscribe({
      next: () => {
        this.cancelar();
        this.carregar();
      },
      error: () => this.erro.set('Nao foi possivel salvar o servico. Confira os campos e sua permissao de ADMIN.'),
    });
  }

  remover(servico: Servico): void {
    if (!confirm(`Remover o servico "${servico.titulo}"?`)) return;

    this.servicoService.remover(servico.id).subscribe({
      next: () => this.carregar(),
      error: () => this.erro.set('Nao foi possivel remover o servico.'),
    });
  }
}
