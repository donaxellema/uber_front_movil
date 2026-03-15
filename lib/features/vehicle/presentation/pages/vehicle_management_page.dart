import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../features/trip/domain/entities/trip.dart';
import '../domain/entities/vehicle.dart';
import '../presentation/bloc/vehicle_bloc.dart';

class VehicleManagementPage extends StatelessWidget {
  const VehicleManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<VehicleBloc>()..add(GetMyVehicles()),
      child: const VehicleManagementView(),
    );
  }
}

class VehicleManagementView extends StatelessWidget {
  const VehicleManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state.status == VehicleStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == VehicleStatus.loading && state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.vehicles.isEmpty) {
            return const Center(
              child: Text('No tienes vehículos registrados'),
            );
          }

          return ListView.builder(
            itemCount: state.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = state.vehicles[index];
              return ListTile(
                leading: Icon(
                  vehicle.category == VehicleCategory.moto
                      ? Icons.motorcycle
                      : Icons.directions_car,
                  color: vehicle.isActive ? Colors.blue : Colors.grey,
                ),
                title: Text('${vehicle.brand} ${vehicle.model}'),
                subtitle: Text('Placa: ${vehicle.plate} - ${vehicle.color}'),
                trailing: Switch(
                  value: vehicle.isActive,
                  onChanged: (value) {
                    context.read<VehicleBloc>().add(
                          UpdateVehicleRequested(vehicle.id, isActive: value),
                        );
                  },
                ),
                onLongPress: () => _showDeleteConfirm(context, vehicle),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final plateController = TextEditingController();
    final colorController = TextEditingController();
    VehicleCategory selectedCategory = VehicleCategory.economy;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Vehículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              DropdownButtonFormField<VehicleCategory>(
                value: selectedCategory,
                items: VehicleCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<VehicleBloc>().add(
                    CreateVehicleRequested(
                      brand: brandController.text,
                      model: modelController.text,
                      year: int.tryParse(yearController.text) ?? 2024,
                      plate: plateController.text,
                      color: colorController.text,
                      category: selectedCategory,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Vehículo'),
        content: Text('¿Estás seguro de eliminar el vehículo ${vehicle.plate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<VehicleBloc>().add(DeleteVehicleRequested(vehicle.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
