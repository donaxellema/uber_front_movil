import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hux/hux.dart';
import 'core/config/dependency_injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/map/presentation/pages/map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar inyección de dependencias
  await setupDependencyInjection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'Skyfast',
        debugShowCheckedModeBanner: false,
        theme: HuxTheme.darkTheme,
        darkTheme: HuxTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/home': (context) => const MapPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.loading ||
            state.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state.status == AuthStatus.authenticated) {
          return const MapPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
