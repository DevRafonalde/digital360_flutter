import { CommonModule } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { RankingItem } from '../../core/models/gamificacao.model';
import { GamificacaoService } from '../../core/services/gamificacao.service';

@Component({
  selector: 'app-gamificacao',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './gamificacao.component.html',
  styleUrl: './gamificacao.component.scss',
})
export class GamificacaoComponent implements OnInit {
  ranking = signal<RankingItem[]>([]);
  carregando = signal(true);
  erro = signal<string | null>(null);

  constructor(private gamificacaoService: GamificacaoService) {}

  ngOnInit(): void {
    this.carregando.set(true);
    this.gamificacaoService.ranking().subscribe({
      next: (ranking) => {
        this.ranking.set(ranking);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Nao foi possivel carregar o ranking.');
        this.carregando.set(false);
      },
    });
  }
}
