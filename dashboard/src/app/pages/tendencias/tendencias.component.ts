import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { Tendencia } from '../../core/models/tendencia.model';
import { TendenciaService } from '../../core/services/tendencia.service';

@Component({
  selector: 'app-tendencias',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './tendencias.component.html',
  styleUrl: './tendencias.component.scss',
})
export class TendenciasComponent implements OnInit {
  tendencias = signal<Tendencia[]>([]);
  carregando = signal(true);
  erro = signal<string | null>(null);

  constructor(private tendenciaService: TendenciaService) {}

  ngOnInit(): void {
    this.carregando.set(true);
    this.tendenciaService.listar().subscribe({
      next: (tendencias) => {
        this.tendencias.set(tendencias);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar as tendencias.');
        this.carregando.set(false);
      },
    });
  }
}
