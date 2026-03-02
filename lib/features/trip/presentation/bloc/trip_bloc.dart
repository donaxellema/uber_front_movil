import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/models/trip_model.dart';
import '../../domain/entities/trip.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final SocketService _socketService;

  TripBloc({required SocketService socketService})
    : _socketService = socketService,
      super(const TripState()) {
    on<TripRequested>(_onTripRequested);
    on<TripAccepted>(_onTripAccepted);
    on<TripStarted>(_onTripStarted);
    on<TripCompleted>(_onTripCompleted);
    on<TripCancelled>(_onTripCancelled);
    on<DriverLocationUpdated>(_onDriverLocationUpdated);
    on<NearbyDriversUpdated>(_onNearbyDriversUpdated);
    on<TripReset>(_onTripReset);

    // Eventos para conductores
    on<NewTripReceived>(_onNewTripReceived);
    on<DriverAcceptTrip>(_onDriverAcceptTrip);
    on<DriverStartTrip>(_onDriverStartTrip);
    on<DriverCompleteTrip>(_onDriverCompleteTrip);
    on<DriverUpdateLocation>(_onDriverUpdateLocation);
    on<DriverSetAvailable>(_onDriverSetAvailable);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Escuchar cuando un conductor acepta
    _socketService.on('trip:accepted', (data) {
      final trip = TripModel.fromJson(data['trip']);
      add(TripAccepted(trip));
    });

    // Escuchar cuando el viaje inicia
    _socketService.on('trip:started', (data) {
      final trip = TripModel.fromJson(data['trip']);
      add(TripStarted(trip));
    });

    // Escuchar cuando el viaje se completa
    _socketService.on('trip:completed', (data) {
      final trip = TripModel.fromJson(data['trip']);
      add(TripCompleted(trip));
    });

    // Escuchar cancelaciones
    _socketService.on('trip:cancelled', (data) {
      add(TripCancelled(reason: data['reason']));
    });

    // Escuchar actualizaciones de ubicación del conductor
    _socketService.on('driver:location:update', (data) {
      add(
        DriverLocationUpdated(
          driverId: data['driverId'],
          lat: data['lat'],
          lng: data['lng'],
        ),
      );
    });

    // Escuchar conductores cercanos
    _socketService.on('drivers:nearby', (data) {
      add(
        DriverLocationUpdated(
          driverId: data['driverId'],
          lat: data['lat'],
          lng: data['lng'],
        ),
      );
    });

    // Escuchar nuevas solicitudes de viaje (para conductores)
    _socketService.on('trip:new', (data) {
      print('🚗 Nueva solicitud de viaje recibida: $data');
      add(
        NewTripReceived(
          tripId: data['tripId'],
          originLat: data['origin']['lat'],
          originLng: data['origin']['lng'],
          originAddress: data['origin']['address'],
          destinationLat: data['destination']['lat'],
          destinationLng: data['destination']['lng'],
          destinationAddress: data['destination']['address'],
          vehicleCategory: _parseVehicleCategory(data['vehicleCategory']),
          basePrice: (data['basePrice'] as num).toDouble(),
        ),
      );
    });

    // Escuchar cuando un viaje es tomado por otro conductor
    _socketService.on('trip:taken', (data) {
      print('⚠️ Viaje tomado por otro conductor: ${data['tripId']}');
      add(TripReset());
    });
  }

  VehicleCategory _parseVehicleCategory(String category) {
    switch (category.toUpperCase()) {
      case 'ECONOMY':
        return VehicleCategory.economy;
      case 'COMFORT':
        return VehicleCategory.comfort;
      case 'XL':
        return VehicleCategory.xl;
      case 'MOTO':
        return VehicleCategory.moto;
      case 'VAN':
        return VehicleCategory.van;
      default:
        return VehicleCategory.economy;
    }
  }

  Future<void> _onTripRequested(
    TripRequested event,
    Emitter<TripState> emit,
  ) async {
    print('🚗 TripBloc: Viaje solicitado');
    print(
      '   Origen: ${event.originAddress} (${event.originLat}, ${event.originLng})',
    );
    print(
      '   Destino: ${event.destinationAddress} (${event.destinationLat}, ${event.destinationLng})',
    );
    print('   Vehículo: ${event.vehicleCategory.name}');

    emit(state.copyWith(status: TripStateStatus.requesting));

    try {
      print('🔌 Verificando conexión Socket.IO...');
      if (!_socketService.isConnected) {
        print('⚠️  Socket NO conectado, conectando...');
        await _socketService.connect();
        print('✅ Socket conectado exitosamente');
      } else {
        print('✅ Socket ya está conectado');
      }

      final tripData = {
        'originLat': event.originLat,
        'originLng': event.originLng,
        'originAddress': event.originAddress,
        'destinationLat': event.destinationLat,
        'destinationLng': event.destinationLng,
        'destinationAddress': event.destinationAddress,
        'vehicleCategory': event.vehicleCategory.name.toUpperCase(),
        'paymentMethod': event.paymentMethod.name.toUpperCase(),
      };

      print('📤 Emitiendo evento trip:request con datos:');
      print(tripData);

      _socketService.emit('trip:request', tripData);

      print('✅ Evento emitido, esperando respuesta del servidor...');
      emit(state.copyWith(status: TripStateStatus.waitingDriver));
    } catch (e) {
      print('❌ Error al solicitar viaje: $e');
      emit(
        state.copyWith(
          status: TripStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTripAccepted(
    TripAccepted event,
    Emitter<TripState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TripStateStatus.driverAccepted,
        currentTrip: event.trip,
      ),
    );
  }

  Future<void> _onTripStarted(
    TripStarted event,
    Emitter<TripState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TripStateStatus.inProgress,
        currentTrip: event.trip,
      ),
    );
  }

  Future<void> _onTripCompleted(
    TripCompleted event,
    Emitter<TripState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TripStateStatus.completed,
        currentTrip: event.trip,
      ),
    );
  }

  Future<void> _onTripCancelled(
    TripCancelled event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip != null) {
      _socketService.emit('trip:cancel', {
        'tripId': state.currentTrip!.id,
        'reason': event.reason,
      });
    }

    emit(state.copyWith(status: TripStateStatus.cancelled, currentTrip: null));
  }

  Future<void> _onDriverLocationUpdated(
    DriverLocationUpdated event,
    Emitter<TripState> emit,
  ) async {
    // Actualizar ubicación del conductor asignado
    if (state.currentTrip?.driverId == event.driverId) {
      emit(state.copyWith(driverLocation: LatLng(event.lat, event.lng)));
    }

    // Actualizar lista de conductores cercanos
    final updatedDrivers = List<LatLng>.from(state.nearbyDrivers);
    updatedDrivers.add(LatLng(event.lat, event.lng));

    emit(state.copyWith(nearbyDrivers: updatedDrivers));
  }

  Future<void> _onNearbyDriversUpdated(
    NearbyDriversUpdated event,
    Emitter<TripState> emit,
  ) async {
    final drivers = event.drivers
        .map((d) => LatLng(d['lat'] as double, d['lng'] as double))
        .toList();

    emit(state.copyWith(nearbyDrivers: drivers));
  }

  Future<void> _onTripReset(TripReset event, Emitter<TripState> emit) async {
    emit(const TripState());
  }

  // Manejadores para conductores
  Future<void> _onNewTripReceived(
    NewTripReceived event,
    Emitter<TripState> emit,
  ) async {
    print('📱 TripBloc: Nueva solicitud de viaje recibida');
    print('   ID: ${event.tripId}');
    print('   Origen: ${event.originAddress}');
    print('   Destino: ${event.destinationAddress}');
    print('   Precio base: \$${event.basePrice}');

    // Crear un Trip temporal para mostrar en la UI
    final trip = Trip(
      id: event.tripId,
      userId: '', // No tenemos el userId en este evento
      originLat: event.originLat,
      originLng: event.originLng,
      originAddress: event.originAddress,
      destinationLat: event.destinationLat,
      destinationLng: event.destinationLng,
      destinationAddress: event.destinationAddress,
      vehicleCategory: event.vehicleCategory,
      status: TripStatus.requested,
      basePrice: event.basePrice,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime.now(),
    );

    emit(
      state.copyWith(status: TripStateStatus.waitingDriver, currentTrip: trip),
    );
  }

  Future<void> _onDriverAcceptTrip(
    DriverAcceptTrip event,
    Emitter<TripState> emit,
  ) async {
    print('✅ TripBloc: Conductor acepta viaje ${event.tripId}');

    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }

      _socketService.emit('trip:accept', {'tripId': event.tripId});

      emit(state.copyWith(status: TripStateStatus.driverAccepted));
    } catch (e) {
      print('❌ Error al aceptar viaje: $e');
      emit(
        state.copyWith(
          status: TripStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDriverStartTrip(
    DriverStartTrip event,
    Emitter<TripState> emit,
  ) async {
    print('🚀 TripBloc: Conductor inicia viaje ${event.tripId}');

    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }

      _socketService.emit('trip:start', {'tripId': event.tripId});

      emit(state.copyWith(status: TripStateStatus.inProgress));
    } catch (e) {
      print('❌ Error al iniciar viaje: $e');
      emit(
        state.copyWith(
          status: TripStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDriverCompleteTrip(
    DriverCompleteTrip event,
    Emitter<TripState> emit,
  ) async {
    print('🏁 TripBloc: Conductor completa viaje ${event.tripId}');

    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }

      _socketService.emit('trip:complete', {'tripId': event.tripId});

      emit(state.copyWith(status: TripStateStatus.completed));
    } catch (e) {
      print('❌ Error al completar viaje: $e');
      emit(
        state.copyWith(
          status: TripStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDriverUpdateLocation(
    DriverUpdateLocation event,
    Emitter<TripState> emit,
  ) async {
    if (!_socketService.isConnected) {
      return;
    }

    final data = <String, dynamic>{'lat': event.lat, 'lng': event.lng};

    if (event.tripId != null) {
      data['tripId'] = event.tripId;
    }

    _socketService.emit('driver:location', data);
  }

  Future<void> _onDriverSetAvailable(
    DriverSetAvailable event,
    Emitter<TripState> emit,
  ) async {
    print(
      '📡 TripBloc: Estableciendo disponibilidad del conductor: ${event.isAvailable}',
    );

    try {
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }

      // Emitir evento al backend para registrar disponibilidad
      _socketService.emit('driver:available', {'available': event.isAvailable});

      emit(state.copyWith(isDriverAvailable: event.isAvailable));

      print('✅ Disponibilidad actualizada: ${event.isAvailable}');
    } catch (e) {
      print('❌ Error al actualizar disponibilidad: $e');
    }
  }

  @override
  Future<void> close() {
    _socketService.disconnect();
    return super.close();
  }
}
