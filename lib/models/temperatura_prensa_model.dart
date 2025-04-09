class TemperaturaPrensa {
  final int? id;
  final String dataRegistro;
  final double? zona1;
  final double? zona2;
  final double? zona3;
  final double? zona4;
  final double? zona5;
  final int prensaId;

  TemperaturaPrensa({
    this.id,
    required this.dataRegistro,
    this.zona1,
    this.zona2,
    this.zona3,
    this.zona4,
    this.zona5,
    required this.prensaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_registro': dataRegistro,
      'zona1': zona1,
      'zona2': zona2,
      'zona3': zona3,
      'zona4': zona4,
      'zona5': zona5,
      'prensa_id': prensaId,
    };
  }

  factory TemperaturaPrensa.fromMap(Map<String, dynamic> map) {
    return TemperaturaPrensa(
      id: map['id'],
      dataRegistro: map['data_registro'],
      zona1: map['zona1'],
      zona2: map['zona2'],
      zona3: map['zona3'],
      zona4: map['zona4'],
      zona5: map['zona5'],
      prensaId: map['prensa_id'],
    );
  }
} 