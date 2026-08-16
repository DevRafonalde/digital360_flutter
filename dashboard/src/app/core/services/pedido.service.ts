import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PedidoLogistico, PedidoRequest, RiscoLogistico } from '../models/pedido.model';

@Injectable({ providedIn: 'root' })
export class PedidoService {
  private readonly baseUrl = `${environment.apiUrl}/pedidos`;

  constructor(private http: HttpClient) {}

  listar(): Observable<PedidoLogistico[]> {
    return this.http.get<PedidoLogistico[]>(this.baseUrl);
  }

  criar(pedido: PedidoRequest): Observable<PedidoLogistico> {
    return this.http.post<PedidoLogistico>(this.baseUrl, pedido);
  }

  atualizar(id: number, pedido: PedidoRequest): Observable<PedidoLogistico> {
    return this.http.put<PedidoLogistico>(`${this.baseUrl}/${id}`, pedido);
  }

  remover(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  recalcularRisco(id: number): Observable<RiscoLogistico> {
    return this.http.post<RiscoLogistico>(`${environment.apiUrl}/entregas/${id}/recalcular-risco`, {});
  }

  reagendar(id: number): Observable<PedidoLogistico> {
    return this.http.post<PedidoLogistico>(`${this.baseUrl}/${id}/reagendar`, {});
  }
}
