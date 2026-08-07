/// Trilha de aprendizagem. Espelha CursoDTO do backend.
class Curso {
  final int id;
  final String titulo;
  final String descricao;
  final String nivel; // BASICO | INTERMEDIARIO | AVANCADO
  final int cargaHoraria;
  final int totalModulos;
  int progresso; // 0-100 - mutavel: avanca conforme o usuario estuda
  final String? autorId; // nomeUser do tutor; null = curso oficial
  final String origem; // 'OFICIAL' | 'COMUNIDADE'
  final String status; // 'PUBLICADO' | 'RASCUNHO'
  final List<String> topicosModulos;

  Curso({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.nivel,
    required this.cargaHoraria,
    required this.totalModulos,
    this.progresso = 0,
    this.autorId,
    this.origem = 'OFICIAL',
    this.status = 'PUBLICADO',
    this.topicosModulos = const [],
  });

  bool get isComunidade => origem == 'COMUNIDADE';

  factory Curso.fromJson(Map<String, dynamic> json) => Curso(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descricao: json['descricao'] ?? '',
        nivel: json['nivel'] ?? 'BASICO',
        cargaHoraria: json['cargaHoraria'] ?? 0,
        totalModulos: json['totalModulos'] ?? 0,
        progresso: json['progresso'] ?? 0,
        autorId: json['autorId'],
        origem: json['origem'] ?? 'OFICIAL',
        status: json['status'] ?? 'PUBLICADO',
        topicosModulos: (json['topicosModulos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'nivel': nivel,
        'cargaHoraria': cargaHoraria,
        'topicosModulos': topicosModulos,
      };
}
