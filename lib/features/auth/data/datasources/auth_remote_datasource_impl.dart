import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final _logger = Logger();

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<AuthResponseModel> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ServerException('Login failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Invalid credentials',
        );
      } else {
        throw ServerException(e.response?.data['message'] ?? 'Server error');
      }
    }
  }

  @override
  Future<AuthResponseModel> register({
    String? email,
    String? phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ServerException('Registration failed');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.response?.statusCode == 400) {
        throw ServerException(e.response?.data['message'] ?? 'Invalid data');
      } else {
        throw ServerException(e.response?.data['message'] ?? 'Server error');
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      // Ignoramos errores en logout
      _logger.w('Logout error: ${e.message}');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to get profile');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout');
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Unauthorized');
      } else {
        throw ServerException(e.response?.data['message'] ?? 'Server error');
      }
    }
  }
}
