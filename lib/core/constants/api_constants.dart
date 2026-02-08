class ApiConstants {
  // Base URL del backend
  static const String baseUrl = 'http://localhost:3001/api/v1';

  // Endpoints de autenticación
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Endpoints de usuarios
  static const String profile = '/users/profile';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
