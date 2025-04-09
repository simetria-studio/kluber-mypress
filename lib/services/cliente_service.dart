import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cliente_model.dart';
import '../models/usuario_kluber_model.dart';
import '../helpers/url_helper.dart';

class ClienteService {
  static const String _clientesKey = 'cached_clientes';
  static const String _usuariosKey = 'cached_usuarios_kluber';

  Future<List<Cliente>> getClientes() async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.clientesUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print(response.body);
        final List<dynamic> data = json.decode(response.body);
        final clientes = data.map((json) => Cliente.fromJson(json)).toList();
        await _salvarClientesCache(clientes);
        return clientes;
      } else {
        return await _getClientesCache();
      }
    } catch (e) {
      return await _getClientesCache();
    }
  }

  Future<List<UsuarioKluber>> getUsuariosKluber() async {
    try {
      final response = await http.post(
        Uri.parse(UrlHelper.usuariosKluberUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final usuarios =
            data.map((json) => UsuarioKluber.fromJson(json)).toList();
        await _salvarUsuariosCache(usuarios);
        return usuarios;
      } else {
        return await _getUsuariosCache();
      }
    } catch (e) {
      return await _getUsuariosCache();
    }
  }

  Future<void> _salvarClientesCache(List<Cliente> clientes) async {
    final prefs = await SharedPreferences.getInstance();
    final clientesJson = clientes.map((c) => c.toJson()).toList();
    await prefs.setString(_clientesKey, json.encode(clientesJson));
  }

  Future<List<Cliente>> _getClientesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientesString = prefs.getString(_clientesKey);

      if (clientesString != null) {
        final List<dynamic> clientesJson = json.decode(clientesString);
        return clientesJson.map((json) => Cliente.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _salvarUsuariosCache(List<UsuarioKluber> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosJson = usuarios.map((u) => u.toJson()).toList();
    await prefs.setString(_usuariosKey, json.encode(usuariosJson));
  }

  Future<List<UsuarioKluber>> _getUsuariosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuariosString = prefs.getString(_usuariosKey);

      if (usuariosString != null) {
        final List<dynamic> usuariosJson = json.decode(usuariosString);
        return usuariosJson
            .map((json) => UsuarioKluber.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
