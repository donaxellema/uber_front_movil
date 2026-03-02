import 'package:app_front_transport/core/network/google_maps_api_service.dart';
import 'package:app_front_transport/features/trip/domain/entities/trip.dart';
import 'package:app_front_transport/features/trip/presentation/bloc/trip_bloc.dart';
import 'package:app_front_transport/features/trip/presentation/bloc/trip_event.dart';
import 'package:app_front_transport/features/trip/presentation/bloc/trip_state.dart';
import 'package:app_front_transport/features/app_mode/app_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:hux/hux.dart';
import 'dart:async';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GetIt.I<TripBloc>()),
        BlocProvider(create: (context) => GetIt.I<AppModeCubit>()),
      ],
      child: const _MapPageContent(),
    );
  }
}

class _MapPageContent extends StatefulWidget {
  const _MapPageContent();

  @override
  State<_MapPageContent> createState() => _MapPageContentState();
}

class _MapPageContentState extends State<_MapPageContent> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(
    -0.2521,
    -79.1753,
  ); // Santo Domingo, Ecuador
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsApiService _googleMapsApiService =
      GetIt.I<GoogleMapsApiService>();

  List<dynamic> _placePredictions = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? _origin;
  LatLng? _destination;
  String? _destinationAddress;
  VehicleCategory _selectedCategory = VehicleCategory.comfort;

  // Para el modo conductor
  bool _isDriverActive = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    print('📍 Solicitando ubicación actual...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('   Servicio de ubicación habilitado: $serviceEnabled');
    if (!serviceEnabled) {
      print('❌ Servicio de ubicación deshabilitado');
      return;
    }

    permission = await Geolocator.checkPermission();
    print('   Permiso actual: $permission');

    if (permission == LocationPermission.denied) {
      print('⚠️ Permiso denegado, solicitando...');
      permission = await Geolocator.requestPermission();
      print('   Nuevo permiso: $permission');
      if (permission == LocationPermission.denied) {
        print('❌ Permiso denegado por el usuario');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permiso denegado permanentemente');
      return;
    }

    try {
      print('🔍 Obteniendo posición GPS...');
      final position = await Geolocator.getCurrentPosition();
      print(
        '✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}',
      );

      setState(() {
        _origin = LatLng(position.latitude, position.longitude);

        print('📍 Agregando marcador de origen...');
        _addMarker(
          'origin',
          _origin!,
          'Mi Ubicación',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );

        print('🗺️ Moviendo cámara a ubicación actual...');
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _origin!, zoom: 15.0),
          ),
        );
      });
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(
    String id,
    LatLng position,
    String title,
    BitmapDescriptor icon,
  ) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: title),
          icon: icon,
        ),
      );
    });
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }
    final predictions = await _googleMapsApiService.searchPlaces(value);
    setState(() => _placePredictions = predictions);
  }

  Future<void> _selectPlace(String placeId, String description) async {
    final details = await _googleMapsApiService.getPlaceDetails(placeId);
    if (details != null) {
      final lat = details['geometry']['location']['lat'];
      final lng = details['geometry']['location']['lng'];
      final latLng = LatLng(lat, lng);

      setState(() {
        _destination = latLng;
        _destinationAddress = description;
        _addMarker(
          'destination',
          _destination!,
          description,
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        _searchController.text = description;
        _placePredictions = [];
      });

      if (_origin != null && _destination != null) {
        _getAndDrawRoute();
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _origin!.latitude < _destination!.latitude
                  ? _origin!.latitude
                  : _destination!.latitude,
              _origin!.longitude < _destination!.longitude
                  ? _origin!.longitude
                  : _destination!.longitude,
            ),
            northeast: LatLng(
              _origin!.latitude > _destination!.latitude
                  ? _origin!.latitude
                  : _destination!.latitude,
              _origin!.longitude > _destination!.longitude
                  ? _origin!.longitude
                  : _destination!.longitude,
            ),
          ),
          100.0,
        ),
      );
    }
    FocusScope.of(context).unfocus();
  }

  Future<void> _getAndDrawRoute() async {
    if (_origin != null && _destination != null) {
      print('🗺️ Solicitando ruta de $_origin a $_destination');
      final polylineCoordinates = await _googleMapsApiService.getDirections(
        _origin!,
        _destination!,
      );
      print('📍 Polyline recibida con ${polylineCoordinates.length} puntos');

      if (polylineCoordinates.isEmpty) {
        print('⚠️ No se pudo obtener la ruta');
        return;
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 8,
            geodesic: true,
            visible: true,
          ),
        );
        print('✅ Polyline agregada al mapa: ${_polylines.length} polylines');
        print('   Color: azul, Width: 8, Visible: true');
        print('   Puntos: ${polylineCoordinates.take(3).toList()}...');
      });
    }
  }

  void _requestTrip() {
    print('🎯 _requestTrip llamado');
    print('   Origen: $_origin');
    print('   Destino: $_destination');
    print('   Dirección destino: $_destinationAddress');
    print('   Vehículo seleccionado: $_selectedCategory');

    if (_origin == null ||
        _destination == null ||
        _destinationAddress == null) {
      print(
        '❌ Faltan datos: origen=$_origin, destino=$_destination, address=$_destinationAddress',
      );
      return;
    }

    print('✅ Todos los datos presentes, solicitando viaje...');

    context.read<TripBloc>().add(
      TripRequested(
        originLat: _origin!.latitude,
        originLng: _origin!.longitude,
        originAddress: 'Mi ubicación',
        destinationLat: _destination!.latitude,
        destinationLng: _destination!.longitude,
        destinationAddress: _destinationAddress!,
        vehicleCategory: _selectedCategory,
        paymentMethod: PaymentMethod.cash,
      ),
    );
  }

  void _toggleDriverActive() {
    setState(() {
      _isDriverActive = !_isDriverActive;
    });

    if (_isDriverActive) {
      print('🚗 Conductor activado - iniciando disponibilidad');
      _startLocationUpdates();
      // Emitir evento de disponibilidad al backend
      context.read<TripBloc>().add(DriverSetAvailable(isAvailable: true));
    } else {
      print('🛑 Conductor desactivado - deteniendo disponibilidad');
      _stopLocationUpdates();
      // Emitir evento de no disponible al backend
      context.read<TripBloc>().add(DriverSetAvailable(isAvailable: false));
    }
  }

  void _startLocationUpdates() {
    print('🚗 Conductor activado - iniciando actualizaciones de ubicación');

    // Emitir ubicación inmediatamente
    _emitCurrentLocation();

    // Luego cada 10 segundos
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _emitCurrentLocation();
    });
  }

  void _stopLocationUpdates() {
    print('🛑 Conductor desactivado - deteniendo actualizaciones');
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _emitCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final tripBloc = context.read<TripBloc>();

      tripBloc.add(
        DriverUpdateLocation(
          lat: position.latitude,
          lng: position.longitude,
          tripId: tripBloc.state.currentTrip?.id,
        ),
      );

      print(
        '📍 Ubicación emitida: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AppModeCubit, AppMode>(
          builder: (context, appMode) {
            return Text(
              appMode == AppMode.passenger
                  ? 'Skyfast - Pasajero'
                  : 'Skyfast - Conductor',
            );
          },
        ),
        actions: [
          BlocBuilder<AppModeCubit, AppMode>(
            builder: (context, appMode) {
              return IconButton(
                icon: Icon(
                  appMode == AppMode.passenger
                      ? Icons.local_taxi
                      : Icons.person,
                ),
                onPressed: () {
                  context.read<AppModeCubit>().toggleMode();
                },
                tooltip: appMode == AppMode.passenger
                    ? 'Cambiar a modo conductor'
                    : 'Cambiar a modo pasajero',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AppModeCubit, AppMode>(
        builder: (context, appMode) {
          if (appMode == AppMode.driver) {
            return _buildDriverMode(context);
          }
          return _buildPassengerMode(context);
        },
      ),
    );
  }

  Widget _buildPassengerMode(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state.status == TripStateStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error al solicitar viaje'),
            ),
          );
        }

        // Actualizar marcadores de conductores cercanos
        if (state.nearbyDrivers.isNotEmpty) {
          _updateNearbyDriversMarkers(state.nearbyDrivers);
        }

        // Actualizar ubicación del conductor asignado
        if (state.driverLocation != null) {
          _addMarker(
            'driver',
            state.driverLocation!,
            'Conductor',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
        }
      },
      builder: (context, tripState) {
        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),

            // Barra de búsqueda
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Buscar destino...',
                    hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    suffixIcon: Icon(Icons.search, color: Colors.black87),
                  ),
                ),
              ),
            ),

            // Predicciones de búsqueda
            if (_placePredictions.isNotEmpty &&
                _searchController.text.isNotEmpty)
              Positioned(
                top: 70,
                left: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _placePredictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _placePredictions[index];
                      return ListTile(
                        title: Text(
                          prediction['description'],
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => _selectPlace(
                          prediction['place_id'],
                          prediction['description'],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Sheet de solicitud de viaje
            if (_destination != null) _buildTripSheet(tripState),
          ],
        );
      },
    );
  }

  Widget _buildDriverMode(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        // Actualizar ubicación del conductor asignado
        if (state.driverLocation != null) {
          _addMarker(
            'user',
            state.driverLocation!,
            'Usuario',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          );
        }
      },
      builder: (context, tripState) {
        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),

            // Botón flotante para conectar/desconectar como conductor
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: _toggleDriverActive,
                backgroundColor: _isDriverActive ? Colors.green : Colors.grey,
                child: Icon(
                  _isDriverActive
                      ? Icons.check_circle
                      : Icons.power_settings_new,
                ),
              ),
            ),

            // Sheet para viajes disponibles o viaje actual
            if (tripState.currentTrip != null) _buildDriverTripSheet(tripState),
          ],
        );
      },
    );
  }

  Widget _buildDriverTripSheet(TripState tripState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contenido según estado
              if (tripState.status == TripStateStatus.waitingDriver)
                _buildNewTripRequest(tripState),

              if (tripState.status == TripStateStatus.driverAccepted)
                _buildAcceptedTrip(tripState),

              if (tripState.status == TripStateStatus.inProgress)
                _buildInProgressTripDriver(tripState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewTripRequest(TripState state) {
    final trip = state.currentTrip;
    if (trip == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva solicitud de viaje',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Origen: ${trip.originAddress}',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Destino: ${trip.destinationAddress}',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Categoría: ${trip.vehicleCategory.name}',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Precio base: \$${trip.basePrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: HuxButton(
                onPressed: () {
                  if (trip.id.isNotEmpty) {
                    context.read<TripBloc>().add(DriverAcceptTrip(trip.id));
                  }
                },
                child: const Text('Aceptar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HuxButton(
                onPressed: () {
                  context.read<TripBloc>().add(
                    const TripCancelled(reason: 'Rechazado por conductor'),
                  );
                },
                variant: HuxButtonVariant.secondary,
                child: const Text('Rechazar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcceptedTrip(TripState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Viaje aceptado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dirígete al punto de recogida',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: HuxButton(
            onPressed: () {
              if (state.currentTrip != null) {
                context.read<TripBloc>().add(
                  DriverStartTrip(state.currentTrip!.id),
                );
              }
            },
            child: const Text('Iniciar viaje'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: HuxButton(
            onPressed: () {
              context.read<TripBloc>().add(
                const TripCancelled(reason: 'Cancelado por conductor'),
              );
            },
            variant: HuxButtonVariant.secondary,
            child: const Text('Cancelar viaje'),
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressTripDriver(TripState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Viaje en curso',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Llevando al pasajero a su destino',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: HuxButton(
            onPressed: () {
              if (state.currentTrip != null) {
                context.read<TripBloc>().add(
                  DriverCompleteTrip(state.currentTrip!.id),
                );
              }
            },
            child: const Text('Completar viaje'),
          ),
        ),
      ],
    );
  }

  void _updateNearbyDriversMarkers(List<LatLng> drivers) {
    setState(() {
      // Remover marcadores viejos de conductores
      _markers.removeWhere(
        (m) => m.markerId.value.startsWith('nearby_driver_'),
      );

      // Agregar nuevos marcadores
      for (var i = 0; i < drivers.length; i++) {
        _markers.add(
          Marker(
            markerId: MarkerId('nearby_driver_$i'),
            position: drivers[i],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
          ),
        );
      }
    });
  }

  Widget _buildTripSheet(TripState tripState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contenido según estado
              if (tripState.status == TripStateStatus.initial ||
                  tripState.status == TripStateStatus.error)
                _buildInitialState(),

              if (tripState.status == TripStateStatus.requesting)
                _buildRequestingState(),

              if (tripState.status == TripStateStatus.waitingDriver)
                _buildWaitingDriverState(),

              if (tripState.status == TripStateStatus.driverAccepted)
                _buildDriverAcceptedState(tripState),

              if (tripState.status == TripStateStatus.inProgress)
                _buildInProgressState(tripState),

              if (tripState.status == TripStateStatus.completed)
                _buildCompletedState(tripState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destino: ${_searchController.text}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Selecciona un vehículo',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildVehicleOption(
              Icons.motorcycle,
              'Moto',
              '\$3,000',
              VehicleCategory.moto,
            ),
            _buildVehicleOption(
              Icons.local_taxi,
              'Básico',
              '\$5,000',
              VehicleCategory.economy,
            ),
            _buildVehicleOption(
              Icons.directions_car,
              'Comfort',
              '\$8,000',
              VehicleCategory.comfort,
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: HuxButton(
            onPressed: _requestTrip,
            child: const Text('Confirmar Viaje'),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestingState() {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Procesando solicitud...',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildWaitingDriverState() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text(
          'Buscando conductor...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Estamos buscando el conductor más cercano',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        HuxButton(
          onPressed: () {
            context.read<TripBloc>().add(
              const TripCancelled(reason: 'Cancelado por usuario'),
            );
          },
          variant: HuxButtonVariant.secondary,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildDriverAcceptedState(TripState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¡Conductor asignado!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'El conductor va en camino',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        HuxButton(
          onPressed: () {
            context.read<TripBloc>().add(
              const TripCancelled(reason: 'Cancelado por usuario'),
            );
          },
          variant: HuxButtonVariant.secondary,
          child: const Text('Cancelar viaje'),
        ),
      ],
    );
  }

  Widget _buildInProgressState(TripState state) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viaje en curso',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Disfruta tu viaje',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCompletedState(TripState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¡Viaje completado!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Precio final: \$${state.currentTrip?.finalPrice?.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        HuxButton(
          onPressed: () {
            context.read<TripBloc>().add(TripReset());
            setState(() {
              _destination = null;
              _destinationAddress = null;
              _searchController.clear();
              _markers.removeWhere((m) => m.markerId.value == 'destination');
              _polylines.clear();
            });
          },
          child: const Text('Nuevo viaje'),
        ),
      ],
    );
  }

  Widget _buildVehicleOption(
    IconData icon,
    String name,
    String price,
    VehicleCategory category,
  ) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100, // Ancho fijo para área táctil consistente
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF2563EB) : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
