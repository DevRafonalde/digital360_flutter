import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { MetricasImpacto } from '../models/impacto.model';

@Injectable({ providedIn: 'root' })
export class ImpactoService {
  private readonly baseUrl = `${environment.apiUrl}/metricas/impacto`;

  constructor(private http: HttpClient) {}

  buscar(): Observable<MetricasImpacto> {
    return this.http.get<MetricasImpacto>(this.baseUrl);
  }
}
