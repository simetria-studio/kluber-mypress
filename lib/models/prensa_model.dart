class Prensa {
  final int? id;
  final int visitaId;
  final String tipoPrensa;
  final String fabricante;
  final double comprimento;
  final double espressura;
  final String produto;
  final double velocidade;
  final String produtoCinta;
  final String produtoCorrente;
  final String produtoBendroads;
  final double torque;

  Prensa({
    this.id,
    required this.visitaId,
    required this.tipoPrensa,
    required this.fabricante,
    required this.comprimento,
    required this.espressura,
    required this.produto,
    required this.velocidade,
    required this.produtoCinta,
    required this.produtoCorrente,
    required this.produtoBendroads,
    required this.torque,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visita_id': visitaId,
      'tipo_prensa': tipoPrensa,
      'fabricante': fabricante,
      'comprimento': comprimento,
      'espressura': espressura,
      'produto': produto,
      'velocidade': velocidade,
      'produto_cinta': produtoCinta,
      'produto_corrente': produtoCorrente,
      'produto_bendroads': produtoBendroads,
      'torque': torque,
    };
  }

  factory Prensa.fromMap(Map<String, dynamic> map) {
    return Prensa(
      id: map['id'],
      visitaId: map['visita_id'],
      tipoPrensa: map['tipo_prensa'],
      fabricante: map['fabricante'],
      comprimento: map['comprimento'],
      espressura: map['espressura'],
      produto: map['produto'],
      velocidade: map['velocidade'],
      produtoCinta: map['produto_cinta'],
      produtoCorrente: map['produto_corrente'],
      produtoBendroads: map['produto_bendroads'],
      torque: map['torque'] ?? 0.0,
    );
  }
} 