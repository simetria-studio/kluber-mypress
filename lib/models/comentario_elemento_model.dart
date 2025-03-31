class ComentarioElemento {
  final int? id;
  final String comentario;
  final int elementoId;

  ComentarioElemento({
    this.id,
    required this.comentario,
    required this.elementoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comentario': comentario,
      'mypress_elemento_id': elementoId,
    };
  }

  factory ComentarioElemento.fromMap(Map<String, dynamic> map) {
    return ComentarioElemento(
      id: map['id'],
      comentario: map['comentario'],
      elementoId: map['mypress_elemento_id'],
    );
  }
} 