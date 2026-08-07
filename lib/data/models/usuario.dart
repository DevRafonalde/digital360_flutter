/// Usuario autenticado. Espelha LoginResponse do backend Smart HAS.
class Usuario {
  final int id;
  String nomeAmigavel; // mutavel - editavel no Perfil
  final String nomeUser;
  final String accessToken;
  final String refreshToken;
  final String cpf;
  final String nomeCompleto;
  bool isTutor; // mutavel - atualiza ao virar tutor sem precisar de novo login

  Usuario({
    required this.id,
    required this.nomeAmigavel,
    required this.nomeUser,
    required this.accessToken,
    required this.refreshToken,
    this.cpf = '',
    this.nomeCompleto = '',
    this.isTutor = false,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] ?? 0,
        nomeAmigavel: json['nomeAmigavel'] ?? '',
        nomeUser: json['nomeUser'] ?? '',
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        cpf: json['cpf'] ?? '',
        nomeCompleto: json['nomeCompleto'] ?? '',
        isTutor: json['isTutor'] ?? false,
      );

  String get bearer => 'Bearer $accessToken';
}
