export interface Curso {
  id: number;
  titulo: string;
  descricao: string;
  nivel: 'BASICO' | 'INTERMEDIARIO' | 'AVANCADO';
  cargaHoraria: number;
  totalModulos: number;
  progresso: number;
}

export type CursoRequest = Omit<Curso, 'id' | 'progresso'>;
