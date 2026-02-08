import 'package:equatable/equatable.dart';
import '../../domain/entities/trip.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class TripRequested extends TripEvent {
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final VehicleCategory vehicleCategory;
  final PaymentMethod paymentMethod;

  const TripRequested({
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    required this.vehicleCategory,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    originLat,
    originLng,
    originAddress,
    destinationLat,
    destinationLng,
    destinationAddress,
    vehicleCategory,
    paymentMethod,
  ];
}

class TripAccepted extends TripEvent {
  final Trip trip;

  const TripAccepted(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripStarted extends TripEvent {
  final Trip trip;

  const TripStarted(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripCompleted extends TripEvent {
  final Trip trip;

  const TripCompleted(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripCancelled extends TripEvent {
  final String? reason;

  const TripCancelled({this.reason});

  @override
  List<Object?> get props => [reason];
}

class DriverLocationUpdated extends TripEvent {
  final String driverId;
  final double lat;
  final double lng;

  const DriverLocationUpdated({
    required this.driverId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [driverId, lat, lng];
}

class NearbyDriversUpdated extends TripEvent {
  final List<Map<String, dynamic>> drivers;

  const NearbyDriversUpdated(this.drivers);

  @override
  List<Object?> get props => [drivers];
}

class TripReset extends TripEvent {}
