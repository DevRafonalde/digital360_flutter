/// Trilha de aprendizagem. Espelha CursoDTO do backend.
class Curso {
  final int id;
  final String titulo;
  final String descricao;
  final String nivel; // BASICO | INTERMEDIARIO | AVANCADO
  final int cargaHoraria;
  final int totalModulos;
  final int progresso; // 0-100

  Curso({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.nivel,
    required this.cargaHoraria,
    required this.totalModulos,
    this.progresso = 0,
  });

  factory Curso.fromJson(Map<String, dynamic> json) => Curso(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descricao: json['descricao'] ?? '',
        nivel: json['nivel'] ?? 'BASICO',
        cargaHoraria: json['cargaHoraria'] ?? 0,
        totalModulos: json['totalModulos'] ?? 0,
        progresso: json['progresso'] ?? 0,
      );
}
