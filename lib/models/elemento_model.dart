class Elemento {
  final int? id;
  final double consumo1;
  final double consumo2;
  final double consumo3;
  final String toma;
  final String posicao;
  final String tipo;
  final int prensaId;

  Elemento({
    this.id,
    required this.consumo1,
    required this.consumo2,
    required this.consumo3,
    required this.toma,
    required this.posicao,
    required this.tipo,
    required this.prensaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumo1': consumo1,
      'consumo2': consumo2,
      'consumo3': consumo3,
      'toma': toma,
      'posicao': posicao,
      'tipo': tipo,
      'prensa_id': prensaId,
    };
  }

  factory Elemento.fromMap(Map<String, dynamic> map) {
    return Elemento(
      id: map['id'],
      consumo1: map['consumo1'],
      consumo2: map['consumo2'],
      consumo3: map['consumo3'],
      toma: map['toma'],
      posicao: map['posicao'],
      tipo: map['tipo'],
      prensaId: map['prensa_id'],
    );
  }
} 