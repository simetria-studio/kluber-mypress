class UrlHelper {
  static const bool _isProduction = true; // Altere para true em produção

  static const String _baseUrlProduction = 'https://kluber.x-erp.com.br/api';
  static const String _baseUrlDevelopment = 'http://10.0.2.2:8000/api';

  static String get baseUrl =>
      _isProduction ? _baseUrlProduction : _baseUrlDevelopment;

  // URLs específicas
  static String get loginUrl => '$baseUrl/login-app';
  static String get clientesUrl => '$baseUrl/get-clientes';
  static String get usuariosKluberUrl => '$baseUrl/get-users-kluber';
  static String get visitasUrl => '$baseUrl/my-press';
}
