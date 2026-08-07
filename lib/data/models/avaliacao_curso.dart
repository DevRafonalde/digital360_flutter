/// Avaliação de um curso (marketplace de tutores).
class AvaliacaoCurso {
  final int id;
  final String usuarioNome;
  final int nota;
  final String? comentario;

  AvaliacaoCurso({
    required this.id,
    required this.usuarioNome,
    required this.nota,
    this.comentario,
  });

  factory AvaliacaoCurso.fromJson(Map<String, dynamic> json) => AvaliacaoCurso(
        id: json['id'],
        usuarioNome: json['usuarioNome'] ?? 'Anônimo',
        nota: json['nota'] ?? 0,
        comentario: json['comentario'],
      );
}

/// Perfil público de um tutor: cursos publicados e média de avaliação.
class PerfilTutor {
  final String nomeAmigavel;
  final int totalCursos;
  final double? mediaAvaliacao;
  final int totalAvaliacoes;

  PerfilTutor({
    required this.nomeAmigavel,
    required this.totalCursos,
    required this.mediaAvaliacao,
    required this.totalAvaliacoes,
  });

  factory PerfilTutor.fromJson(Map<String, dynamic> json) => PerfilTutor(
        nomeAmigavel: json['nomeAmigavel'] ?? '',
        totalCursos: json['totalCursos'] ?? 0,
        mediaAvaliacao: (json['mediaAvaliacao'] as num?)?.toDouble(),
        totalAvaliacoes: json['totalAvaliacoes'] ?? 0,
      );
}
