import 'package:equatable/equatable.dart';
import '../../../../features/trip/domain/entities/trip.dart';

class Vehicle extends Equatable {
  final String id;
  final String driverId;
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final VehicleCategory category;
  final bool isActive;
  final bool soatVerified;
  final bool technicalRevisionVerified;

  const Vehicle({
    required this.id,
    required this.driverId,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.category,
    this.isActive = false,
    this.soatVerified = false,
    this.technicalRevisionVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        driverId,
        brand,
        model,
        year,
        plate,
        color,
        category,
        isActive,
        soatVerified,
        technicalRevisionVerified,
      ];
}
