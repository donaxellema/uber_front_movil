import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    String? email,
    String? phone,
    required String password,
  });

  Future<AuthResponseModel> register({
    String? email,
    String? phone,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<void> logout();

  Future<UserModel> getProfile();
}
