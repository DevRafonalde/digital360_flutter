/// Usuario autenticado. Espelha LoginResponse do backend Smart HAS.
class Usuario {
  final int id;
  final String nomeAmigavel;
  final String nomeUser;
  final String accessToken;
  final String refreshToken;

  Usuario({
    required this.id,
    required this.nomeAmigavel,
    required this.nomeUser,
    required this.accessToken,
    required this.refreshToken,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] ?? 0,
        nomeAmigavel: json['nomeAmigavel'] ?? '',
        nomeUser: json['nomeUser'] ?? '',
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
      );

  String get bearer => 'Bearer $accessToken';
}
