import { HttpClient } from '@angular/common/http';
import { Injectable, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { LoginRequest, Usuario } from '../models/usuario.model';

const STORAGE_KEY = 'smarthas.usuario';

@Injectable({ providedIn: 'root' })
export class AuthService {
  /** Signal exposto para a navbar/guards reagirem ao login/logout sem polling. */
  readonly usuario = signal<Usuario | null>(this.lerDoStorage());

  constructor(private http: HttpClient) {}

  login(request: LoginRequest): Observable<Usuario> {
    return this.http.post<Usuario>(`${environment.apiUrl}/auth/usuarios/login`, request).pipe(
      tap((usuario) => {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(usuario));
        this.usuario.set(usuario);
      }),
    );
  }

  logout(): void {
    localStorage.removeItem(STORAGE_KEY);
    this.usuario.set(null);
  }

  isAutenticado(): boolean {
    return this.usuario() !== null;
  }

  get accessToken(): string | null {
    return this.usuario()?.accessToken ?? null;
  }

  private lerDoStorage(): Usuario | null {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as Usuario) : null;
  }
}
