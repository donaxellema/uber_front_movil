import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SocketService {
  IO.Socket? _socket;
  final FlutterSecureStorage _storage;

  SocketService(this._storage);

  Future<void> connect() async {
    print('🔌 SocketService: Iniciando conexión...');

    final token = await _storage.read(key: 'access_token');

    if (token == null) {
      print('❌ SocketService: No se encontró token de acceso');
      throw Exception('No token found');
    }

    print('✅ SocketService: Token encontrado');
    print('🌐 SocketService: Conectando a http://localhost:3001');

    _socket = IO.io(
      'http://localhost:3001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Socket connected successfully');
    });

    _socket!.onDisconnect((_) {
      print('⚠️  Socket disconnected');
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connection error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Escuchar eventos
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // Emitir eventos
  void emit(String event, dynamic data) {
    if (_socket == null) {
      print('❌ SocketService.emit: Socket no inicializado');
      return;
    }

    if (!isConnected) {
      print('❌ SocketService.emit: Socket no está conectado');
      return;
    }

    print('📤 SocketService.emit: Evento "$event" con datos: $data');
    _socket!.emit(event, data);
  }

  // Remover listener
  void off(String event) {
    _socket?.off(event);
  }

  bool get isConnected => _socket?.connected ?? false;
}
