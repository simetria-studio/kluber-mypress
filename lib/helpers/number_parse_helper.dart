class NumberParseHelper {
  /// Normaliza entrada BR (`1,5` / `1.5`) para parse numérico.
  static String normalize(String? value) {
    if (value == null) return '';
    var text = value.trim().replaceAll(' ', '');
    if (text.isEmpty) return '';

    if (text.contains(',') && text.contains('.')) {
      // Ex.: 1.234,56 → 1234.56
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '.');
    }
    return text;
  }

  static double? tryParse(String? value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static double parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Valor numérico inválido: $value');
    }
    return parsed;
  }

  static String? validateRequired(String? value, {String field = 'valor'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, insira o $field';
    }
    if (tryParse(value) == null) {
      return 'Informe um número válido (use vírgula ou ponto)';
    }
    return null;
  }
}
