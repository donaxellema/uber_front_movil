import '../../../../features/trip/domain/entities/trip.dart';
import '../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.driverId,
    required super.brand,
    required super.model,
    required super.year,
    required super.plate,
    required super.color,
    required super.category,
    super.isActive,
    super.soatVerified,
    super.technicalRevisionVerified,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      driverId: json['driverId'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      plate: json['plate'],
      color: json['color'],
      category: _parseVehicleCategory(json['category']),
      isActive: json['isActive'] ?? false,
      soatVerified: json['soatVerified'] ?? false,
      technicalRevisionVerified: json['technicalRevisionVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'plate': plate,
      'color': color,
      'category': category.name.toUpperCase(),
      'isActive': isActive,
    };
  }

  static VehicleCategory _parseVehicleCategory(String category) {
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
}
