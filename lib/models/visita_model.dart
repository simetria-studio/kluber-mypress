class Visita {
  final int? id;
  final DateTime dataVisita;
  final String cliente;
  final String contatoCliente;
  final String contatoKluber;
  final String comentario;

  Visita({
    this.id,
    required this.dataVisita,
    required this.cliente,
    required this.contatoCliente,
    required this.contatoKluber,
    this.comentario = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_visita': dataVisita.toIso8601String(),
      'cliente': cliente,
      'contato_cliente': contatoCliente,
      'contato_kluber': contatoKluber,
      'comentario': comentario,
    };
  }

  factory Visita.fromMap(Map<String, dynamic> map) {
    return Visita(
      id: map['id'],
      dataVisita: DateTime.parse(map['data_visita']),
      cliente: map['cliente'],
      contatoCliente: map['contato_cliente'],
      contatoKluber: map['contato_kluber'],
      comentario: map['comentario'] ?? '',
    );
  }
} 