class EspessuraConstants {
  static final List<String> opcoes = List.generate(29, (i) => '${i + 2}');

  static String? opcaoDeValor(double espressura) {
    final valorInteiro = espressura.toInt();
    if (espressura != valorInteiro.toDouble()) {
      return null;
    }

    final opcao = valorInteiro.toString();
    return opcoes.contains(opcao) ? opcao : null;
  }
}
