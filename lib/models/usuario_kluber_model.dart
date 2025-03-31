class UsuarioKluber {
  final int id;
  final String nomeUsuario;
  final String nomeUsuarioCompleto;

  UsuarioKluber({
    required this.id,
    required this.nomeUsuario,
    required this.nomeUsuarioCompleto,
  });

  factory UsuarioKluber.fromJson(Map<String, dynamic> json) {
    return UsuarioKluber(
      id: json['id'],
      nomeUsuario: json['nome_usuario'],
      nomeUsuarioCompleto: json['nome_usuario_completo'],
    );
  }
} 