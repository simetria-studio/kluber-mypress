import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/url_helper.dart';

class ApiService {
  // Substitua pela URL da sua API

  static Future<Map<String, dynamic>> enviarVisita(
      Map<String, dynamic> dadosVisita) async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.visitasUrl),
        headers: {
          'Content-Type': 'application/json',
          // Adicione outros headers necessários, como token de autenticação
          // 'Authorization': 'Bearer seu-token-aqui',
        },
        body: jsonEncode(dadosVisita),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao enviar visita: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);
      if (responseData['message'] != 'Visita cadastrada com sucesso') {
        throw Exception('Erro na resposta da API: ${responseData['message']}');
      }

      return responseData;
    } catch (e) {
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  // Adicione outros métodos da API conforme necessário
  // Por exemplo:
  // static Future<List<Cliente>> getClientes() async { ... }
  // static Future<void> enviarAnexo(String base64, String nome) async { ... }
}
