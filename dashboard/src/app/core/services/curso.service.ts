import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Curso, CursoRequest } from '../models/curso.model';

@Injectable({ providedIn: 'root' })
export class CursoService {
  private readonly baseUrl = `${environment.apiUrl}/cursos`;

  constructor(private http: HttpClient) {}

  listar(): Observable<Curso[]> {
    return this.http.get<Curso[]>(this.baseUrl);
  }

  criar(curso: CursoRequest): Observable<Curso> {
    return this.http.post<Curso>(this.baseUrl, curso);
  }

  atualizar(id: number, curso: CursoRequest): Observable<Curso> {
    return this.http.put<Curso>(`${this.baseUrl}/${id}`, curso);
  }

  remover(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
