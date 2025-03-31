class TemperaturaElemento {
  final int? id;
  final String dataRegistro;
  final double? zona1;
  final double? zona2;
  final double? zona3;
  final double? zona4;
  final double? zona5;
  final int elementoId;

  TemperaturaElemento({
    this.id,
    required this.dataRegistro,
    this.zona1,
    this.zona2,
    this.zona3,
    this.zona4,
    this.zona5,
    required this.elementoId,
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
      'elemento_id': elementoId,
    };
  }

  factory TemperaturaElemento.fromMap(Map<String, dynamic> map) {
    return TemperaturaElemento(
      id: map['id'],
      dataRegistro: map['data_registro'],
      zona1: map['zona1'],
      zona2: map['zona2'],
      zona3: map['zona3'],
      zona4: map['zona4'],
      zona5: map['zona5'],
      elementoId: map['elemento_id'],
    );
  }
} 