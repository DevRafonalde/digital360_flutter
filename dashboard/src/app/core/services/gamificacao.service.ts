import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { RankingItem } from '../models/gamificacao.model';

@Injectable({ providedIn: 'root' })
export class GamificacaoService {
  private readonly baseUrl = `${environment.apiUrl}/gamificacao`;

  constructor(private http: HttpClient) {}

  ranking(): Observable<RankingItem[]> {
    return this.http.get<RankingItem[]>(`${this.baseUrl}/ranking`);
  }
}
