class AplicacaoPrensaHelper {
  static const String cinta = 'Cinta metálica';
  static const String corrente = 'Corrente';
  static const String bendRods = 'Bend rods';

  static List<String> tiposPermitidos(String? fabricante) {
    if (fabricante == 'Dieffenbacher') {
      return const [cinta, corrente, bendRods];
    }

    if (fabricante == 'Kusters') {
      return const [cinta];
    }

    return const [cinta, corrente];
  }

  static bool permite(String? fabricante, String tipo) {
    return tiposPermitidos(fabricante).contains(tipo);
  }

  /// Dieffenbacher: corrente e bend rods não têm superior/inferior.
  static bool exigePosicao(String? fabricante, String tipo) {
    if (tipo == bendRods) return false;
    if (fabricante == 'Dieffenbacher' && tipo == corrente) return false;
    return true;
  }
}
