import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/url_helper.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String usuario, String password) async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario': usuario,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        throw 'Usuario ou Senha incorretos!';
      } else {
        print(response.body);
        throw 'Erro ao realizar login. Tente novamente.';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
