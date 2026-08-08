/// Vinculo somente-leitura entre um cuidador e um idoso/tutelado.
class VinculoCuidador {
  final String idosoId;
  final String idosoNome;

  VinculoCuidador({required this.idosoId, required this.idosoNome});

  factory VinculoCuidador.fromJson(Map<String, dynamic> json) => VinculoCuidador(
        idosoId: json['idosoId'] ?? '',
        idosoNome: json['idosoNome'] ?? '',
      );
}

/// Resumo (somente leitura) do progresso de um idoso vinculado.
class ResumoIdoso {
  final String idosoNome;
  final int cursosConcluidos;
  final int sequenciaDias;
  final int pontos;

  ResumoIdoso({
    required this.idosoNome,
    required this.cursosConcluidos,
    required this.sequenciaDias,
    required this.pontos,
  });

  factory ResumoIdoso.fromJson(Map<String, dynamic> json) => ResumoIdoso(
        idosoNome: json['idosoNome'] ?? '',
        cursosConcluidos: json['cursosConcluidos'] ?? 0,
        sequenciaDias: json['sequenciaDias'] ?? 0,
        pontos: json['pontos'] ?? 0,
      );
}
