import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storage;

  AuthRepositoryImpl({required this.remoteDataSource, required this.storage});

  @override
  Future<Either<Failure, AuthResponse>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      print('🔐 Login iniciado...');
      final authResponse = await remoteDataSource.login(
        email: email,
        phone: phone,
        password: password,
      );

      print('✅ Login exitoso');
      print('   Access Token: ${authResponse.accessToken.substring(0, 20)}...');

      // Guardar tokens
      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      print('✅ Tokens guardados en storage');

      // Guardar info del usuario
      await storage.saveUserId(authResponse.user.id);
      if (authResponse.user.email != null) {
        await storage.saveUserEmail(authResponse.user.email!);
      }
      await storage.saveUserRole(authResponse.user.role.value);
      print('✅ Info de usuario guardada');
      print('   User ID: ${authResponse.user.id}');
      print('   Role: ${authResponse.user.role.value}');

      return Right(authResponse);
    } on UnauthorizedException catch (e) {
      print('❌ Login falló: Unauthorized - ${e.message}');
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      print('❌ Login falló: Network - ${e.message}');
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      print('❌ Login falló: Server - ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ Login falló: Unexpected - $e');
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> register({
    String? email,
    String? phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final authResponse = await remoteDataSource.register(
        email: email,
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      // Guardar tokens
      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Guardar info del usuario
      await storage.saveUserId(authResponse.user.id);
      if (authResponse.user.email != null) {
        await storage.saveUserEmail(authResponse.user.email!);
      }
      await storage.saveUserRole(authResponse.user.role.value);

      return Right(authResponse);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await storage.clearAll();
      return const Right(null);
    } catch (e) {
      // Aunque falle la petición, limpiamos el storage local
      await storage.clearAll();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      return Right(user);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      print('🔍 Verificando sesión...');
      final token = await storage.getAccessToken();
      final isLogged = token != null && token.isNotEmpty;

      if (isLogged) {
        print('✅ Sesión activa encontrada');
        print('   Token: ${token!.substring(0, 20)}...');
      } else {
        print('⚠️  No hay sesión activa');
      }

      return Right(isLogged);
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return Left(CacheFailure('Failed to check login status'));
    }
  }
}
