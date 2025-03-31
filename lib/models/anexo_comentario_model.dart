class AnexoComentario {
  final int? id;
  final String nome;
  final String tipo;
  final String url;
  final String base64;
  final int comentarioId;

  AnexoComentario({
    this.id,
    required this.nome,
    required this.tipo,
    required this.url,
    required this.base64,
    required this.comentarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'url': url,
      'base64': base64,
      'mypress_comentario_id': comentarioId,
    };
  }

  factory AnexoComentario.fromMap(Map<String, dynamic> map) {
    return AnexoComentario(
      id: map['id'],
      nome: map['nome'],
      tipo: map['tipo'],
      url: map['url'],
      base64: map['base64'],
      comentarioId: map['mypress_comentario_id'],
    );
  }
} 