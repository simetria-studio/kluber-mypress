/// Nomes e aliases dos produtos de lubrificação (cinta / corrente / bend rods).
class LubrificanteProdutoHelper {
  static const Map<String, String> aliases = {
    'Klubersynh CP 2-260': 'Klubersynth CP 2-260',
    'Klubersynh CP 2-100': 'Klubersynth CP 2-100',
    'Klubersynhth GEM 4': 'Klubersynth GEM 4',
  };

  static const List<String> produtosCinta = [
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynth CP 2-260',
    'Outro',
    'N/A',
  ];

  static const List<String> produtosCorrente = [
    'Hotemp Super CH 2-100',
    'Klubersynth CP 2-100',
    'Hotemp Super N',
    'Hotemp Super N Plus',
    'Klubersynth CP 2-260',
    'Outro',
    'N/A',
  ];

  static const List<String> produtosBendRods = [
    'Hotemp Super CH 2-100',
    'Klubersynth CP 2-100',
    'Outro',
    'N/A',
  ];

  static String normalizar(String? valor) {
    if (valor == null || valor.isEmpty) return '';
    return aliases[valor] ?? valor;
  }

  static String? valorNaLista(String? valor, List<String> opcoes) {
    final normalizado = normalizar(valor);
    if (normalizado.isEmpty) return null;
    return opcoes.contains(normalizado) ? normalizado : null;
  }

  static List<String> opcoesPorTipo(String tipo) {
    switch (tipo) {
      case 'Corrente':
        return produtosCorrente;
      case 'Bend rods':
        return produtosBendRods;
      default:
        return produtosCinta;
    }
  }
}
