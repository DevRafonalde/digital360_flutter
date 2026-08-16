export interface Usuario {
  id: number;
  nomeAmigavel: string;
  nomeUser: string;
  accessToken: string;
  refreshToken: string;
}

export interface LoginRequest {
  nomeUser: string;
  senha: string;
}
