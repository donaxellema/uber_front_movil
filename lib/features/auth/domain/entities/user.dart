import 'package:equatable/equatable.dart';

enum UserRole {
  user('USER'),
  driver('DRIVER'),
  admin('ADMIN'),
  superAdmin('SUPER_ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.user,
    );
  }
}

enum UserStatus {
  pending('PENDING'),
  active('ACTIVE'),
  suspended('SUSPENDED'),
  blocked('BLOCKED');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String status) {
    return UserStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => UserStatus.pending,
    );
  }
}

class User extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final UserRole role;
  final UserStatus status;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    firstName,
    lastName,
    profileImage,
    role,
    status,
    emailVerified,
    phoneVerified,
    createdAt,
    updatedAt,
  ];
}
