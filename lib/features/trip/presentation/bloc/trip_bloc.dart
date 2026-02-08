import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/models/trip_model.dart';
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

  @override
  Future<void> close() {
    _socketService.disconnect();
    return super.close();
  }
}
