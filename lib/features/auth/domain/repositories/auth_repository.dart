import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login({
    String? email,
    String? phone,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> register({
    String? email,
    String? phone,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getProfile();

  Future<Either<Failure, bool>> isLoggedIn();
}
