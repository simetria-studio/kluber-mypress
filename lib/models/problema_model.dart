class Problema {
  final int? id;
  final String problemaRedutorPrincipal;
  final String? comentarioRedutorPrincipal;
  final String? lubrificanteRedutorPrincipal;
  final String problemaTemperatura;
  final String? comentarioTemperatura;
  final String problemaTamborPrincipal;
  final String? comentarioTamborPrincipal;
  final int myPressPrensaId;
  final String? graxaRolamentosZonasQuentes;
  final String? graxaTamborPrincipal;

  Problema({
    this.id,
    required this.problemaRedutorPrincipal,
    this.comentarioRedutorPrincipal,
    this.lubrificanteRedutorPrincipal,
    required this.problemaTemperatura,
    this.comentarioTemperatura,
    required this.problemaTamborPrincipal,
    this.comentarioTamborPrincipal,
    required this.myPressPrensaId,
    this.graxaRolamentosZonasQuentes,
    this.graxaTamborPrincipal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'problema_redutor_principal': problemaRedutorPrincipal,
      'comentario_redutor_principal': comentarioRedutorPrincipal,
      'lubrificante_redutor_principal': lubrificanteRedutorPrincipal,
      'problema_temperatura': problemaTemperatura,
      'comentario_temperatura': comentarioTemperatura,
      'problema_tambor_principal': problemaTamborPrincipal,
      'comentario_tambor_principal': comentarioTamborPrincipal,
      'prensa_id': myPressPrensaId,
      'graxa_rolamentos_zonas_quentes': graxaRolamentosZonasQuentes,
      'graxa_tambor_principal': graxaTamborPrincipal,
    };
  }

  factory Problema.fromMap(Map<String, dynamic> map) {
    return Problema(
      id: map['id'],
      problemaRedutorPrincipal: map['problema_redutor_principal'],
      comentarioRedutorPrincipal: map['comentario_redutor_principal'],
      lubrificanteRedutorPrincipal: map['lubrificante_redutor_principal'],
      problemaTemperatura: map['problema_temperatura'],
      comentarioTemperatura: map['comentario_temperatura'],
      problemaTamborPrincipal: map['problema_tambor_principal'],
      comentarioTamborPrincipal: map['comentario_tambor_principal'],
      myPressPrensaId: map['prensa_id'],
      graxaRolamentosZonasQuentes: map['graxa_rolamentos_zonas_quentes'],
      graxaTamborPrincipal: map['graxa_tambor_principal'],
    );
  }
} 