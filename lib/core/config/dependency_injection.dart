import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/google_maps_api_service.dart';
import '../../core/network/socket_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/trip/presentation/bloc/trip_bloc.dart';
import '../../features/app_mode/app_mode_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // External
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  getIt.registerLazySingleton<Dio>(() => Dio()); // Register Dio

  // Core
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt()),
  );

  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt()));
  getIt.registerLazySingleton<GoogleMapsApiService>(
    () => GoogleMapsApiService(getIt<Dio>()),
  ); // Register GoogleMapsApiService

  // Socket.IO Service
  getIt.registerLazySingleton<SocketService>(
    () => SocketService(getIt<FlutterSecureStorage>()),
  );

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<DioClient>().dio),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt(), storage: getIt()),
  );

  // BLoC
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepository: getIt()));
  getIt.registerFactory<TripBloc>(() => TripBloc(socketService: getIt()));
  getIt.registerLazySingleton<AppModeCubit>(() => AppModeCubit());
}
