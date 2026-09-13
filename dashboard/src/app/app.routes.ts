import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { CursosComponent } from './pages/cursos/cursos.component';
import { GamificacaoComponent } from './pages/gamificacao/gamificacao.component';
import { HomeComponent } from './pages/home/home.component';
import { ImpactoComponent } from './pages/impacto/impacto.component';
import { LayoutComponent } from './pages/layout/layout.component';
import { LoginComponent } from './pages/login/login.component';
import { PedidosComponent } from './pages/pedidos/pedidos.component';
import { ServicosComponent } from './pages/servicos/servicos.component';
import { TendenciasComponent } from './pages/tendencias/tendencias.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  {
    path: '',
    component: LayoutComponent,
    canActivate: [authGuard],
    children: [
      { path: 'home', component: HomeComponent },
      { path: 'cursos', component: CursosComponent },
      { path: 'servicos', component: ServicosComponent },
      { path: 'pedidos', component: PedidosComponent },
      { path: 'tendencias', component: TendenciasComponent },
      { path: 'gamificacao', component: GamificacaoComponent },
      { path: 'impacto', component: ImpactoComponent },
      { path: '', pathMatch: 'full', redirectTo: 'home' },
    ],
  },
  { path: '**', redirectTo: 'login' },
];
