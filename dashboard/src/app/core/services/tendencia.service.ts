import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Tendencia } from '../models/tendencia.model';

@Injectable({ providedIn: 'root' })
export class TendenciaService {
  private readonly baseUrl = `${environment.apiUrl}/tendencias`;

  constructor(private http: HttpClient) {}

  listar(): Observable<Tendencia[]> {
    return this.http.get<Tendencia[]>(this.baseUrl);
  }
}
