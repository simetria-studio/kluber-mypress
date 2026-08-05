import 'package:flutter/material.dart';

/// Textos informativos exibidos nos botões "i" dos formulários.
/// Conteúdo provisório (~140 caracteres) até definição final pela Klüber.
class CampoInfoHelper {
  static const String temperaturasZonas =
      'Registre a temperatura de cada zona da prensa em °C. '
      'Os valores ajudam a avaliar o comportamento térmico e a lubrificação.';

  static const String produtosLubrificacao =
      'Selecione o produto aplicado em cada aplicação da prensa '
      '(cinta, corrente ou bend rods, conforme o fabricante).';

  static const String bendRods =
      'Bend rods aplica-se apenas a prensas Dieffenbacher. '
      'Informe o produto específico usado nessa aplicação.';

  static const String dadosPrensa =
      'Informe fabricante, dimensões, espessura e velocidade. '
      'Esses dados alimentam o reporte técnico da visita.';

  static void mostrar(BuildContext context, String titulo, String mensagem) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFFABA00).withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFABA00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFFFABA00),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            mensagem,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Entendi',
                style: TextStyle(color: Color(0xFFFABA00)),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget botao(
    BuildContext context, {
    required String titulo,
    required String mensagem,
  }) {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Color(0xFFFABA00), size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Mais informações',
      onPressed: () => mostrar(context, titulo, mensagem),
    );
  }
}
