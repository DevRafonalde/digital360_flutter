export interface Servico {
  id: number;
  titulo: string;
  descricao: string;
  categoria: string;
  orgao: string;
  conteudo: string;
}

export type ServicoRequest = Omit<Servico, 'id'>;
