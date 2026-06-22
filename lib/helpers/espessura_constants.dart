class EspessuraConstants {
  static const List<String> opcoes = ['6', '9', '12', '15', '18', '25'];

  static String? opcaoDeValor(double espressura) {
    final valorInteiro = espressura.toInt();
    if (espressura != valorInteiro.toDouble()) {
      return null;
    }

    final opcao = valorInteiro.toString();
    return opcoes.contains(opcao) ? opcao : null;
  }
}
