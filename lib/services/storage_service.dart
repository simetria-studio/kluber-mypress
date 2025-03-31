import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String tokenExpiryKey = 'token_expiry';

  // Salvar token
  Future<void> saveToken(String token, String expiryDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(tokenExpiryKey, expiryDate);
  }

  // Obter token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Obter data de expiração
  Future<String?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenExpiryKey);
  }

  // Remover token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(tokenExpiryKey);
  }

  // Verificar se está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final expiry = await getTokenExpiry();

    if (token == null || expiry == null) {
      return false;
    }

    final expiryDate = DateTime.parse(expiry);
    return expiryDate.isAfter(DateTime.now());
  }
}
