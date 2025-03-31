class Cliente {
  final int id;
  final String codigoEmpresa;
  final String codigoCliente;
  final String razaoSocial;
  final String nomeFantasia;
  final String email;
  final String ativo;

  Cliente({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoCliente,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.email,
    required this.ativo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      codigoEmpresa: json['codigo_empresa'],
      codigoCliente: json['codigo_cliente'],
      razaoSocial: json['razao_social'],
      nomeFantasia: json['nome_fantasia'],
      email: json['email'] ?? '',
      ativo: json['ativo'],
    );
  }
} 