# Arquitectura del Proyecto Skyfast Mobile

## 📐 Clean Architecture + BLoC Pattern

Este proyecto sigue los principios de Clean Architecture combinado con el patrón BLoC para gestión de estado.

### Capas de la Aplicación

```
┌─────────────────────────────────────────────────────┐
│              PRESENTATION LAYER                      │
│  (UI, BLoC, Pages, Widgets)                         │
│  - Maneja la interacción del usuario                │
│  - Renderiza la UI                                  │
│  - Reacciona a cambios de estado                    │
└──────────────────┬──────────────────────────────────┘
                   │ Events & States
┌──────────────────▼──────────────────────────────────┐
│              DOMAIN LAYER                            │
│  (Entities, Repository Interfaces, Use Cases)       │
│  - Lógica de negocio pura                           │
│  - Independiente de frameworks                      │
│  - Define contratos (interfaces)                    │
└──────────────────┬──────────────────────────────────┘
                   │ Implements
┌──────────────────▼──────────────────────────────────┐
│              DATA LAYER                              │
│  (Models, DataSources, Repository Implementations)  │
│  - Implementa repositorios                          │
│  - Consume APIs externas                            │
│  - Transforma datos externos a entidades            │
└─────────────────────────────────────────────────────┘
```

## 🎯 Módulo de Autenticación (auth)

### Estructura Completa

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart         # Interface
│   │   └── auth_remote_datasource_impl.dart    # Implementación API
│   ├── models/
│   │   ├── user_model.dart                     # Modelo de datos
│   │   └── auth_response_model.dart            # Modelo de respuesta
│   └── repositories/
│       └── auth_repository_impl.dart            # Implementación del repo
├── domain/
│   ├── entities/
│   │   ├── user.dart                           # Entidad de negocio
│   │   └── auth_response.dart                  # Entidad de respuesta
│   └── repositories/
│       └── auth_repository.dart                 # Contrato del repositorio
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                      # Lógica de estado
    │   ├── auth_event.dart                     # Eventos de usuario
    │   └── auth_state.dart                     # Estados de la UI
    └── pages/
        └── login_page.dart                      # Pantalla de login
```

### Flujo de Datos

```
┌─────────────┐
│ LoginPage   │ Usuario presiona "Iniciar Sesión"
└──────┬──────┘
       │ 1. Dispara evento
       ▼
┌─────────────────┐
│ AuthBloc        │ AuthLoginRequested(email, password)
│ - Recibe evento │
│ - Emite loading │
└──────┬──────────┘
       │ 2. Llama al repositorio
       ▼
┌──────────────────────┐
│ AuthRepository       │ login(email, password)
│ - Valida entrada     │
│ - Maneja Either      │
└──────┬───────────────┘
       │ 3. Ejecuta datasource
       ▼
┌──────────────────────────┐
│ AuthRemoteDataSource     │ POST /auth/login
│ - Hace petición HTTP     │
│ - Parsea respuesta       │
└──────┬───────────────────┘
       │ 4. Retorna modelo
       ▼
┌──────────────────────────┐
│ AuthRepositoryImpl       │ Either<Failure, AuthResponse>
│ - Convierte a entidad    │
│ - Guarda tokens          │
└──────┬───────────────────┘
       │ 5. Retorna resultado
       ▼
┌─────────────────┐
│ AuthBloc        │ Emite estado (authenticated o error)
└──────┬──────────┘
       │ 6. Actualiza UI
       ▼
┌─────────────┐
│ LoginPage   │ Navega a Home o muestra error
└─────────────┘
```

## 🔄 Patrón BLoC

### Componentes

1. **Events (Eventos)**
   - Acciones que el usuario puede realizar
   - Inmutables (usando Equatable)
   - Ejemplos: `AuthLoginRequested`, `AuthLogoutRequested`

2. **States (Estados)**
   - Representa el estado actual de la UI
   - Inmutables (usando Equatable)
   - Ejemplo: `AuthState(status: loading, user: null)`

3. **Bloc (Business Logic Component)**
   - Transforma eventos en estados
   - Contiene la lógica de negocio
   - Usa `on<Event>` para manejar eventos

### Ejemplo de Uso

```dart
// 1. Definir evento
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
}

// 2. Definir estado
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
  });
}

// 3. Manejar en Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  on<AuthLoginRequested>((event, emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    final result = await repository.login(
      email: event.email,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (authResponse) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      )),
    );
  });
}

// 4. Usar en la UI
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state.status == AuthStatus.loading) {
      return CircularProgressIndicator();
    }
    // ...
  },
)
```

## 🔌 Inyección de Dependencias (GetIt)

### Registro de Servicios

```dart
// Singleton - Una sola instancia
getIt.registerLazySingleton<SecureStorageService>(
  () => SecureStorageService(getIt()),
);

// Factory - Nueva instancia cada vez
getIt.registerFactory<AuthBloc>(
  () => AuthBloc(authRepository: getIt()),
);
```

### Orden de Registro

1. **External** - FlutterSecureStorage
2. **Core** - SecureStorageService, DioClient
3. **DataSources** - AuthRemoteDataSource
4. **Repositories** - AuthRepository
5. **BLoCs** - AuthBloc

## 🌐 Cliente HTTP (Dio)

### Interceptores

```dart
DioClient configura automáticamente:
├── Request Interceptor
│   └── Agrega token de autorización
├── Response Interceptor
│   └── Logs de respuestas
└── Error Interceptor
    └── Maneja 401 y refresca token automáticamente
```

### Refresh Token Automático

Cuando la API retorna 401:
1. Interceptor detecta el error
2. Obtiene refresh token del storage
3. Llama a `/auth/refresh`
4. Actualiza access token
5. Reintenta la petición original

## 💾 Almacenamiento Seguro

### SecureStorageService

```dart
// Guardar tokens
await storage.saveTokens(
  accessToken: 'xxx',
  refreshToken: 'yyy',
);

// Obtener token
final token = await storage.getAccessToken();

// Limpiar todo
await storage.clearAll();
```

Los tokens se almacenan cifrados usando:
- **Android**: EncryptedSharedPreferences
- **iOS**: Keychain
- **Linux/Windows**: Encrypted file

## ⚠️ Manejo de Errores

### Either Pattern (Dartz)

```dart
Either<Failure, Success>
  ├── Left(Failure)  - Cuando algo sale mal
  └── Right(Success) - Cuando todo está bien
```

### Tipos de Failures

```dart
sealed class Failure {
  ServerFailure     // Error del servidor (500, 400, etc)
  NetworkFailure    // Sin conexión a internet
  ValidationFailure // Datos inválidos
  CacheFailure      // Error en storage
  UnauthorizedFailure // 401 - No autorizado
}
```

### Uso

```dart
final result = await repository.login(...);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (success) => print('Éxito: $success'),
);
```

## 🎨 Principios SOLID Aplicados

### Single Responsibility
Cada clase tiene una única responsabilidad:
- `AuthBloc` → Gestiona estado de autenticación
- `AuthRepository` → Abstrae acceso a datos
- `AuthDataSource` → Comunica con la API

### Open/Closed
Extensible sin modificar código existente:
- Nuevos eventos se agregan sin modificar el Bloc
- Nuevos datasources se pueden agregar sin cambiar el repositorio

### Liskov Substitution
Las implementaciones son intercambiables:
- `AuthRepositoryImpl` implementa `AuthRepository`
- Se puede reemplazar por un `MockAuthRepository` en tests

### Interface Segregation
Interfaces específicas para cada necesidad:
- `AuthRemoteDataSource` - Solo métodos remotos
- `AuthRepository` - Solo métodos del dominio

### Dependency Inversion
Dependemos de abstracciones, no de implementaciones:
- `AuthBloc` depende de `AuthRepository` (interface)
- No depende de `AuthRepositoryImpl` (implementación)

---

**Última actualización:** 2026-01-16
