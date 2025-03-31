class Problema {
  final int? id;
  final int problemaRedutorPrincipal;
  final String? comentarioRedutorPrincipal;
  final int problemaTemperatura;
  final String? comentarioTemperatura;
  final int problemaTamborPrincipal;
  final String? comentarioTamborPrincipal;
  final int myPressVisitaId;

  Problema({
    this.id,
    required this.problemaRedutorPrincipal,
    this.comentarioRedutorPrincipal,
    required this.problemaTemperatura,
    this.comentarioTemperatura,
    required this.problemaTamborPrincipal,
    this.comentarioTamborPrincipal,
    required this.myPressVisitaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'problema_redutor_principal': problemaRedutorPrincipal,
      'comentario_redutor_principal': comentarioRedutorPrincipal,
      'problema_temperatura': problemaTemperatura,
      'comentario_temperatura': comentarioTemperatura,
      'problema_tambor_principal': problemaTamborPrincipal,
      'comentario_tambor_principal': comentarioTamborPrincipal,
      'mypress_visita_id': myPressVisitaId,
    };
  }

  factory Problema.fromMap(Map<String, dynamic> map) {
    return Problema(
      id: map['id'],
      problemaRedutorPrincipal: map['problema_redutor_principal'],
      comentarioRedutorPrincipal: map['comentario_redutor_principal'],
      problemaTemperatura: map['problema_temperatura'],
      comentarioTemperatura: map['comentario_temperatura'],
      problemaTamborPrincipal: map['problema_tambor_principal'],
      comentarioTamborPrincipal: map['comentario_tambor_principal'],
      myPressVisitaId: map['mypress_visita_id'],
    );
  }
} 