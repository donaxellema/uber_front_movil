import '../entities/vehicle.dart';
import '../../../../features/trip/domain/entities/trip.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getMyVehicles();
  Future<Vehicle> createVehicle({
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required VehicleCategory category,
  });
  Future<Vehicle> updateVehicle(String id, {
    String? brand,
    String? model,
    int? year,
    String? plate,
    String? color,
    VehicleCategory? category,
    bool? isActive,
  });
  Future<void> deleteVehicle(String id);
}
