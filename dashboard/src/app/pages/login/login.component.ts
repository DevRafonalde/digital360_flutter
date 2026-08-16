import { CommonModule } from '@angular/common';
import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
})
export class LoginComponent {
  nomeUser = '';
  senha = '';
  carregando = signal(false);
  erro = signal<string | null>(null);

  constructor(
    private authService: AuthService,
    private router: Router,
  ) {}

  entrar(): void {
    this.erro.set(null);
    this.carregando.set(true);

    this.authService.login({ nomeUser: this.nomeUser, senha: this.senha }).subscribe({
      next: () => {
        this.carregando.set(false);
        this.router.navigate(['/home']);
      },
      error: () => {
        this.carregando.set(false);
        this.erro.set('Usuario ou senha invalidos. Confira e tente novamente.');
      },
    });
  }
}
