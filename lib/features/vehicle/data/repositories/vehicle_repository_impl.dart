import '../../../../core/network/dio_client.dart';
import '../../../../features/trip/domain/entities/trip.dart';
import '../models/vehicle_model.dart';
import '../domain/entities/vehicle.dart';
import '../domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final DioClient _dioClient;

  VehicleRepositoryImpl(this._dioClient);

  @override
  Future<List<Vehicle>> getMyVehicles() async {
    try {
      final response = await _dioClient.dio.get('/vehicles/my-vehicles');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      throw Exception('Error getting vehicles');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Vehicle> createVehicle({
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required VehicleCategory category,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/vehicles',
        data: {
          'brand': brand,
          'model': model,
          'year': year,
          'plate': plate,
          'color': color,
          'category': category.name.toUpperCase(),
        },
      );
      if (response.statusCode == 201) {
        return VehicleModel.fromJson(response.data);
      }
      throw Exception('Error creating vehicle');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Vehicle> updateVehicle(String id, {
    String? brand,
    String? model,
    int? year,
    String? plate,
    String? color,
    VehicleCategory? category,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (brand != null) data['brand'] = brand;
      if (model != null) data['model'] = model;
      if (year != null) data['year'] = year;
      if (plate != null) data['plate'] = plate;
      if (color != null) data['color'] = color;
      if (category != null) data['category'] = category.name.toUpperCase();
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dioClient.dio.patch('/vehicles/$id', data: data);
      if (response.statusCode == 200) {
        return VehicleModel.fromJson(response.data);
      }
      throw Exception('Error updating vehicle');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteVehicle(String id) async {
    try {
      final response = await _dioClient.dio.delete('/vehicles/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error deleting vehicle');
      }
    } catch (e) {
      rethrow;
    }
  }
}
