import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { MetricasImpacto } from '../../core/models/impacto.model';
import { ImpactoService } from '../../core/services/impacto.service';

@Component({
  selector: 'app-impacto',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './impacto.component.html',
  styleUrl: './impacto.component.scss',
})
export class ImpactoComponent implements OnInit {
  metricas = signal<MetricasImpacto | null>(null);
  carregando = signal(true);
  erro = signal<string | null>(null);

  constructor(private impactoService: ImpactoService) {}

  ngOnInit(): void {
    this.carregando.set(true);
    this.impactoService.buscar().subscribe({
      next: (metricas) => {
        this.metricas.set(metricas);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Não foi possível carregar as métricas de impacto.');
        this.carregando.set(false);
      },
    });
  }
}
