import 'package:app_front_transport/core/network/google_maps_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart'; // Import get_it

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final LatLng _center = const LatLng(4.60971, -74.08175); // Bogotá as default
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapsApiService _googleMapsApiService =
      GetIt.I<GoogleMapsApiService>(); // Get service instance
  List<dynamic> _placePredictions = [];
  Set<Marker> _markers = {}; // To store markers
  Set<Polyline> _polylines = {}; // To store polylines

  LatLng? _origin;
  LatLng? _destination;
  String? _routeInfo; // For displaying distance and duration

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _origin = LatLng(
        position.latitude,
        position.longitude,
      ); // Set current location as origin
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _origin!, zoom: 15.0),
        ),
      );
      _addMarker(
        'origin',
        _origin!,
        'Mi Ubicación',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
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
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: icon,
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    final predictions = await _googleMapsApiService.searchPlaces(value);
    setState(() {
      _placePredictions = predictions;
    });
  }

  Future<void> _selectPlace(String placeId, String description) async {
    final details = await _googleMapsApiService.getPlaceDetails(placeId);
    if (details != null) {
      final lat = details['geometry']['location']['lat'];
      final lng = details['geometry']['location']['lng'];
      final latLng = LatLng(lat, lng);

      setState(() {
        _destination = latLng;
        _addMarker(
          'destination',
          _destination!,
          description,
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        _searchController.text = description;
        _placePredictions = []; // Clear predictions
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
          100.0, // padding
        ),
      );
    }
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  Future<void> _getAndDrawRoute() async {
    if (_origin != null && _destination != null) {
      final polylineCoordinates = await _googleMapsApiService.getDirections(
        _origin!,
        _destination!,
      );
      setState(() {
        _polylines.clear(); // Clear previous polylines
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        );
        // TODO: Implementar la distancia calculada
        _routeInfo = 'Ruta calculada (distancia/duración placeholder)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers, // Display markers
            polylines: _polylines, // Display polylines
          ),
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
                decoration: InputDecoration(
                  hintText: 'Buscar destino...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          if (_placePredictions.isNotEmpty && _searchController.text.isNotEmpty)
            Positioned(
              top: 70, // Adjust this based on the height of your search bar
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
                      title: Text(prediction['description']),
                      onTap: () {
                        _selectPlace(
                          prediction['place_id'],
                          prediction['description'],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          if (_destination != null) _buildTripRequestSheet(),
        ],
      ),
    );
  }

  Widget _buildTripRequestSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.5,
      builder: (BuildContext context, ScrollController scrollController) {
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

              // Destination info
              Text(
                'Destino: ${_searchController.text}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _routeInfo ?? 'Calculando ruta...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const Divider(height: 32),

              // Vehicle selection (placeholder)
              const Text(
                'Selecciona un vehículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // TODO: Implementar la seleccion del vehiculo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVehicleOption(Icons.local_taxi, 'Básico', 'COP 12,000'),
                  _buildVehicleOption(
                    Icons.directions_car,
                    'Comfort',
                    'COP 18,000',
                    isSelected: true,
                  ),
                  _buildVehicleOption(
                    Icons.airport_shuttle,
                    'XL',
                    'COP 25,000',
                  ),
                ],
              ),
              const Divider(height: 32),

              // Confirm button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement trip request logic
                    print('Requesting trip...');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirmar Viaje',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleOption(
    IconData icon,
    String name,
    String price, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2563EB).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: isSelected ? const Color(0xFF2563EB) : Colors.black,
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
