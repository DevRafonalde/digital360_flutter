import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Servico, ServicoRequest } from '../models/servico.model';

@Injectable({ providedIn: 'root' })
export class ServicoService {
  private readonly baseUrl = `${environment.apiUrl}/servicos`;

  constructor(private http: HttpClient) {}

  listar(): Observable<Servico[]> {
    return this.http.get<Servico[]>(this.baseUrl);
  }

  criar(servico: ServicoRequest): Observable<Servico> {
    return this.http.post<Servico>(this.baseUrl, servico);
  }

  atualizar(id: number, servico: ServicoRequest): Observable<Servico> {
    return this.http.put<Servico>(`${this.baseUrl}/${id}`, servico);
  }

  remover(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
