import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  final Dio _dio;
  final SecureStorageService _storage;
  final Logger _logger = Logger();

  DioClient(this._storage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token de autorización si existe
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );

          // Si es 401 y no es la ruta de refresh, intentar refrescar el token
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('refresh')) {
            try {
              await _refreshToken();
              // Reintentar la petición original
              final options = error.requestOptions;
              final token = await _storage.getAccessToken();
              options.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _dio.post(
      ApiConstants.refresh,
      options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
    );

    if (response.statusCode == 200) {
      await _storage.saveTokens(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );
    }
  }

  Dio get dio => _dio;
}
