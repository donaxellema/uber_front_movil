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
      final authResponse = await remoteDataSource.login(
        email: email,
        phone: phone,
        password: password,
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
      final token = await storage.getAccessToken();
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure('Failed to check login status'));
    }
  }
}
