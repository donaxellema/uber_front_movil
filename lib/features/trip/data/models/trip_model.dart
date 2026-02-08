import '../../domain/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.userId,
    super.driverId,
    required super.originLat,
    required super.originLng,
    required super.originAddress,
    required super.destinationLat,
    required super.destinationLng,
    required super.destinationAddress,
    required super.vehicleCategory,
    required super.status,
    super.distance,
    super.duration,
    required super.basePrice,
    super.finalPrice,
    required super.paymentMethod,
    super.acceptedAt,
    super.startedAt,
    super.completedAt,
    super.cancelledAt,
    super.cancellationReason,
    super.cancelledBy,
    super.rating,
    super.comment,
    required super.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      userId: json['userId'],
      driverId: json['driverId'],
      originLat: double.parse(json['originLat'].toString()),
      originLng: double.parse(json['originLng'].toString()),
      originAddress: json['originAddress'],
      destinationLat: double.parse(json['destinationLat'].toString()),
      destinationLng: double.parse(json['destinationLng'].toString()),
      destinationAddress: json['destinationAddress'],
      vehicleCategory: _vehicleCategoryFromString(json['vehicleCategory']),
      status: _tripStatusFromString(json['status']),
      distance: json['distance'] != null
          ? double.parse(json['distance'].toString())
          : null,
      duration: json['duration'],
      basePrice: double.parse(json['basePrice'].toString()),
      finalPrice: json['finalPrice'] != null
          ? double.parse(json['finalPrice'].toString())
          : null,
      paymentMethod: _paymentMethodFromString(json['paymentMethod']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'],
      cancelledBy: json['cancelledBy'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originLat': originLat,
      'originLng': originLng,
      'originAddress': originAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationAddress': destinationAddress,
      'vehicleCategory': _vehicleCategoryToString(vehicleCategory),
      'paymentMethod': _paymentMethodToString(paymentMethod),
    };
  }

  static VehicleCategory _vehicleCategoryFromString(String value) {
    return VehicleCategory.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
    );
  }

  static String _vehicleCategoryToString(VehicleCategory category) {
    return category.name.toUpperCase();
  }

  static TripStatus _tripStatusFromString(String value) {
    final statusMap = {
      'REQUESTED': TripStatus.requested,
      'ACCEPTED': TripStatus.accepted,
      'IN_PROGRESS': TripStatus.inProgress,
      'COMPLETED': TripStatus.completed,
      'CANCELLED': TripStatus.cancelled,
    };
    return statusMap[value.toUpperCase()] ?? TripStatus.requested;
  }

  static PaymentMethod _paymentMethodFromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
    );
  }

  static String _paymentMethodToString(PaymentMethod method) {
    return method.name.toUpperCase();
  }
}
