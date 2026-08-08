/// Pergunta do fórum da comunidade. Espelha PerguntaForumORM do backend.
class PerguntaForum {
  final int id;
  final String autorNome;
  final String titulo;
  final String corpo;
  final String criadoEm;
  final int totalRespostas;
  final List<RespostaForum> respostas;

  PerguntaForum({
    required this.id,
    required this.autorNome,
    required this.titulo,
    required this.corpo,
    required this.criadoEm,
    required this.totalRespostas,
    this.respostas = const [],
  });

  factory PerguntaForum.fromJson(Map<String, dynamic> json) => PerguntaForum(
        id: json['id'],
        autorNome: json['autorNome'] ?? 'Anônimo',
        titulo: json['titulo'] ?? '',
        corpo: json['corpo'] ?? '',
        criadoEm: json['criadoEm'] ?? '',
        totalRespostas: json['totalRespostas'] ?? 0,
        respostas: (json['respostas'] as List<dynamic>?)
                ?.map((e) => RespostaForum.fromJson(e))
                .toList() ??
            const [],
      );
}

class RespostaForum {
  final int id;
  final String autorNome;
  final String corpo;
  final String criadoEm;

  RespostaForum({
    required this.id,
    required this.autorNome,
    required this.corpo,
    required this.criadoEm,
  });

  factory RespostaForum.fromJson(Map<String, dynamic> json) => RespostaForum(
        id: json['id'],
        autorNome: json['autorNome'] ?? 'Anônimo',
        corpo: json['corpo'] ?? '',
        criadoEm: json['criadoEm'] ?? '',
      );
}
