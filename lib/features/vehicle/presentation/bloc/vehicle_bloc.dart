import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/trip/domain/entities/trip.dart';
import '../domain/entities/vehicle.dart';
import '../domain/repositories/vehicle_repository.dart';

// Events
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

class GetMyVehicles extends VehicleEvent {}

class CreateVehicleRequested extends VehicleEvent {
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final VehicleCategory category;

  const CreateVehicleRequested({
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.category,
  });

  @override
  List<Object?> get props => [brand, model, year, plate, color, category];
}

class UpdateVehicleRequested extends VehicleEvent {
  final String id;
  final String? brand;
  final String? model;
  final int? year;
  final String? plate;
  final String? color;
  final VehicleCategory? category;
  final bool? isActive;

  const UpdateVehicleRequested(
    this.id, {
    this.brand,
    this.model,
    this.year,
    this.plate,
    this.color,
    this.category,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, brand, model, year, plate, color, category, isActive];
}

class DeleteVehicleRequested extends VehicleEvent {
  final String id;
  const DeleteVehicleRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// State
enum VehicleStatus { initial, loading, success, error }

class VehicleState extends Equatable {
  final List<Vehicle> vehicles;
  final VehicleStatus status;
  final String? errorMessage;

  const VehicleState({
    this.vehicles = const [],
    this.status = VehicleStatus.initial,
    this.errorMessage,
  });

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    VehicleStatus? status,
    String? errorMessage,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [vehicles, status, errorMessage];
}

// Bloc
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository _vehicleRepository;

  VehicleBloc({required VehicleRepository vehicleRepository})
      : _vehicleRepository = vehicleRepository,
        super(const VehicleState()) {
    on<GetMyVehicles>(_onGetMyVehicles);
    on<CreateVehicleRequested>(_onCreateVehicleRequested);
    on<UpdateVehicleRequested>(_onUpdateVehicleRequested);
    on<DeleteVehicleRequested>(_onDeleteVehicleRequested);
  }

  Future<void> _onGetMyVehicles(
    GetMyVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(status: VehicleStatus.loading));
    try {
      final vehicles = await _vehicleRepository.getMyVehicles();
      emit(state.copyWith(status: VehicleStatus.success, vehicles: vehicles));
    } catch (e) {
      emit(state.copyWith(status: VehicleStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateVehicleRequested(
    CreateVehicleRequested event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(status: VehicleStatus.loading));
    try {
      await _vehicleRepository.createVehicle(
        brand: event.brand,
        model: event.model,
        year: event.year,
        plate: event.plate,
        color: event.color,
        category: event.category,
      );
      add(GetMyVehicles());
    } catch (e) {
      emit(state.copyWith(status: VehicleStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateVehicleRequested(
    UpdateVehicleRequested event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(status: VehicleStatus.loading));
    try {
      await _vehicleRepository.updateVehicle(
        event.id,
        brand: event.brand,
        model: event.model,
        year: event.year,
        plate: event.plate,
        color: event.color,
        category: event.category,
        isActive: event.isActive,
      );
      add(GetMyVehicles());
    } catch (e) {
      emit(state.copyWith(status: VehicleStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteVehicleRequested(
    DeleteVehicleRequested event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(status: VehicleStatus.loading));
    try {
      await _vehicleRepository.deleteVehicle(event.id);
      add(GetMyVehicles());
    } catch (e) {
      emit(state.copyWith(status: VehicleStatus.error, errorMessage: e.toString()));
    }
  }
}
