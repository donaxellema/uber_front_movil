import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthProfileRequested>(_onProfileRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await authRepository.login(
      email: event.email,
      phone: event.phone,
      password: event.password,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (authResponse) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: authResponse.user,
        ),
      ),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await authRepository.register(
      email: event.email,
      phone: event.phone,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (authResponse) => emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: authResponse.user,
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await authRepository.logout();

    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await authRepository.isLoggedIn();

    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (isLoggedIn) {
        if (isLoggedIn) {
          add(const AuthProfileRequested());
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> _onProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await authRepository.getProfile();

    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (user) =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }
}
