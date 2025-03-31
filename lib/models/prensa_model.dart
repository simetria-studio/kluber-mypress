class Prensa {
  final int? id;
  final String tipoPrensa;
  final String fabricante;
  final double comprimento;
  final double espessura;
  final String produto;
  final double velocidade;
  final String produtoCinta;
  final String produtoCorrente;
  final String produtoBendroads;
  final int visitaId;

  Prensa({
    this.id,
    required this.tipoPrensa,
    required this.fabricante,
    required this.comprimento,
    required this.espessura,
    required this.produto,
    required this.velocidade,
    required this.produtoCinta,
    required this.produtoCorrente,
    required this.produtoBendroads,
    required this.visitaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo_prensa': tipoPrensa,
      'fabricante': fabricante,
      'comprimento': comprimento,
      'espessura': espessura,
      'produto': produto,
      'velocidade': velocidade,
      'produto_cinta': produtoCinta,
      'produto_corrente': produtoCorrente,
      'produto_bendroads': produtoBendroads,
      'visita_id': visitaId,
    };
  }

  factory Prensa.fromMap(Map<String, dynamic> map) {
    return Prensa(
      id: map['id'],
      tipoPrensa: map['tipo_prensa'],
      fabricante: map['fabricante'],
      comprimento: map['comprimento'],
      espessura: map['espessura'],
      produto: map['produto'],
      velocidade: map['velocidade'],
      produtoCinta: map['produto_cinta'],
      produtoCorrente: map['produto_corrente'],
      produtoBendroads: map['produto_bendroads'],
      visitaId: map['visita_id'],
    );
  }
} 