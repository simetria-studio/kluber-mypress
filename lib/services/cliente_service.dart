import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cliente_model.dart';
import '../models/usuario_kluber_model.dart';
import '../helpers/url_helper.dart';

class ClienteService {
  Future<List<Cliente>> getClientes() async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.clientesUrl),
        headers: {
          'Content-Type': 'application/json',
          // Adicione outros headers necessários aqui
        },
        // Adicione body se necessário
        // body: json.encode({
        //   'chave': 'valor',
        // }),
      );

      if (response.statusCode == 200) {
        // Para debug
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw 'Erro ao carregar clientes';
      }
    } catch (e) {
      print('Erro ao buscar clientes: $e'); // Para debug
      throw e.toString();
    }
  }

  Future<List<UsuarioKluber>> getUsuariosKluber() async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.usuariosKluberUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UsuarioKluber.fromJson(json)).toList();
      } else {
        throw 'Erro ao carregar usuários';
      }
    } catch (e) {
      print('Erro ao buscar usuários: $e'); // Para debug
      throw e.toString();
    }
  }
}
