import 'package:equatable/equatable.dart';

enum TripStatus { requested, accepted, inProgress, completed, cancelled }

enum VehicleCategory { economy, comfort, xl, moto, van }

enum PaymentMethod { cash, card, wallet }

class Trip extends Equatable {
  final String id;
  final String userId;
  final String? driverId;
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final VehicleCategory vehicleCategory;
  final TripStatus status;
  final double? distance;
  final int? duration;
  final double basePrice;
  final double? finalPrice;
  final PaymentMethod paymentMethod;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final int? rating;
  final String? comment;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.userId,
    this.driverId,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    required this.vehicleCategory,
    required this.status,
    this.distance,
    this.duration,
    required this.basePrice,
    this.finalPrice,
    required this.paymentMethod,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    driverId,
    originLat,
    originLng,
    originAddress,
    destinationLat,
    destinationLng,
    destinationAddress,
    vehicleCategory,
    status,
    distance,
    duration,
    basePrice,
    finalPrice,
    paymentMethod,
    acceptedAt,
    startedAt,
    completedAt,
    cancelledAt,
    cancellationReason,
    cancelledBy,
    rating,
    comment,
    createdAt,
  ];
}
