import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/trip.dart';

enum TripStateStatus {
  initial,
  requesting,
  waitingDriver,
  driverAccepted,
  inProgress,
  completed,
  cancelled,
  error,
}

class TripState extends Equatable {
  final TripStateStatus status;
  final Trip? currentTrip;
  final String? errorMessage;
  final List<LatLng> nearbyDrivers;
  final LatLng? driverLocation;
  final bool isDriverAvailable;

  const TripState({
    this.status = TripStateStatus.initial,
    this.currentTrip,
    this.errorMessage,
    this.nearbyDrivers = const [],
    this.driverLocation,
    this.isDriverAvailable = false,
  });

  TripState copyWith({
    TripStateStatus? status,
    Trip? currentTrip,
    String? errorMessage,
    List<LatLng>? nearbyDrivers,
    LatLng? driverLocation,
    bool? isDriverAvailable,
  }) {
    return TripState(
      status: status ?? this.status,
      currentTrip: currentTrip ?? this.currentTrip,
      errorMessage: errorMessage,
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      driverLocation: driverLocation ?? this.driverLocation,
      isDriverAvailable: isDriverAvailable ?? this.isDriverAvailable,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentTrip,
    errorMessage,
    nearbyDrivers,
    driverLocation,
    isDriverAvailable,
  ];
}
