# Skyfast - App Móvil de Transporte 🚀

Frontend móvil desarrollado con Flutter para la plataforma de transporte Skyfast.

## ✅ Estado del Proyecto

**Módulo de Autenticación Completo!**

### Funcionalidades Implementadas
- ✅ Arquitectura Clean Architecture + BLoC
- ✅ **Login** con email y contraseña
- ✅ **Registro** de nuevos usuarios (email, teléfono, nombre, apellido)
- ✅ **Recuperación de contraseña** (UI lista, pendiente integración backend)
- ✅ Validación de formularios con mensajes en español
- ✅ Almacenamiento seguro de tokens (JWT)
- ✅ Refresh token automático con interceptores Dio
- ✅ Manejo de errores con pattern Either (dartz)
- ✅ Navegación entre pantallas
- ✅ Estados de carga con feedback visual
- ✅ Compilación exitosa en Linux
- ✅ Sin errores ni warnings en análisis estático

### Pantallas Disponibles
1. **LoginPage** - Inicio de sesión con email/contraseña
2. **RegisterPage** - Registro de nuevos usuarios
3. **ForgotPasswordPage** - Recuperación de contraseña
4. **HomePage** - Pantalla principal (placeholder)

### Validaciones Implementadas
- Email: formato válido (regex)
- Contraseña: 
  - Mínimo 8 caracteres
  - Al menos 1 mayúscula, 1 minúscula y 1 número (registro)
- Confirmación de contraseña
- Nombre y apellido: mínimo 2 caracteres
- Teléfono: opcional, formato válido si se proporciona

## 🚀 Inicio Rápido

### 1. Instalar dependencias
```bash
cd app_front_transport
flutter pub get
```

### 2. Configurar backend
Edita `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://localhost:3001/api/v1';
```

### 3. Ejecutar
```bash
flutter run -d linux
```

## 📚 Documentación

- [ARQUITECTURA.md](./ARQUITECTURA.md) - Documentación completa de la arquitectura

## 🏗️ Tecnologías

- **Flutter 3.38.7** - Framework UI multiplataforma
- **BLoC 8.1.6** - Gestión de estado reactiva
- **Dio 5.7.0** - Cliente HTTP con interceptores
- **GetIt 8.3.0** - Inyección de dependencias
- **Flutter Secure Storage 9.2.4** - Almacenamiento cifrado de tokens
- **Equatable 2.0.7** - Comparación de objetos para BLoC
- **Dartz 0.10.1** - Programación funcional (Either pattern)
- **Logger 2.5.0** - Sistema de logs
- **HUX 0.2.0** - Sistema de diseño
- **Flutter Feather Icons** - Iconografía

## 📱 Plataformas

- ✅ Linux (probado)
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS

---

Ver [ARQUITECTURA.md](./ARQUITECTURA.md) para más detalles.

