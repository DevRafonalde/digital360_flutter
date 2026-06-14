/// Servico publico (gov.br, INSS, SUS...). Espelha ServicoDTO do backend.
class Servico {
  final int id;
  final String titulo;
  final String descricao;
  final String categoria;
  final String orgao;
  final String conteudo;

  Servico({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.orgao,
    required this.conteudo,
  });

  factory Servico.fromJson(Map<String, dynamic> json) => Servico(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descricao: json['descricao'] ?? '',
        categoria: json['categoria'] ?? '',
        orgao: json['orgao'] ?? '',
        conteudo: json['conteudo'] ?? '',
      );
}
