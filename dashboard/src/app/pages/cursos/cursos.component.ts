import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Curso, CursoRequest } from '../../core/models/curso.model';
import { CursoService } from '../../core/services/curso.service';

const CURSO_VAZIO: CursoRequest = {
  titulo: '',
  descricao: '',
  nivel: 'BASICO',
  cargaHoraria: 1,
  totalModulos: 1,
};

@Component({
  selector: 'app-cursos',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './cursos.component.html',
  styleUrl: './cursos.component.scss',
})
export class CursosComponent implements OnInit {
  cursos = signal<Curso[]>([]);
  carregando = signal(true);
  erro = signal<string | null>(null);

  editandoId: number | null = null;
  formulario: CursoRequest = { ...CURSO_VAZIO };

  constructor(private cursoService: CursoService) {}

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.cursoService.listar().subscribe({
      next: (cursos) => {
        this.cursos.set(cursos);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar os cursos.');
        this.carregando.set(false);
      },
    });
  }

  editar(curso: Curso): void {
    this.editandoId = curso.id;
    this.formulario = {
      titulo: curso.titulo,
      descricao: curso.descricao,
      nivel: curso.nivel,
      cargaHoraria: curso.cargaHoraria,
      totalModulos: curso.totalModulos,
    };
  }

  cancelar(): void {
    this.editandoId = null;
    this.formulario = { ...CURSO_VAZIO };
  }

  salvar(): void {
    const acao = this.editandoId
      ? this.cursoService.atualizar(this.editandoId, this.formulario)
      : this.cursoService.criar(this.formulario);

    acao.subscribe({
      next: () => {
        this.cancelar();
        this.carregar();
      },
      error: () => this.erro.set('Nao foi possivel salvar o curso. Confira os campos e sua permissao de ADMIN.'),
    });
  }

  remover(curso: Curso): void {
    if (!confirm(`Remover o curso "${curso.titulo}"?`)) return;

    this.cursoService.remover(curso.id).subscribe({
      next: () => this.carregar(),
      error: () => this.erro.set('Nao foi possivel remover o curso.'),
    });
  }
}
