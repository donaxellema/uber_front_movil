import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GoogleMapsApiService {
  final Dio _dio;
  final String _apiKey = "YOUR_API_KEY";
  late final bool _isMocking;

  GoogleMapsApiService(this._dio) {
    _isMocking = _apiKey == "YOUR_API_KEY";
    if (_isMocking) {
      print('GoogleMapsApiService: Mdodo de prueba sin YOUR_API_KEY');
    }
  }

  Future<List<dynamic>> searchPlaces(String query) async {
    if (_isMocking) {
      // Mock data for places search
      if (query.toLowerCase().contains('bogota')) {
        return [
          {'description': 'Bogotá, Colombia', 'place_id': 'mock_bogota_id'},
          {
            'description': 'Bogotá, D.C., Colombia',
            'place_id': 'mock_bogota_dc_id',
          },
        ];
      } else if (query.toLowerCase().contains('medellin')) {
        return [
          {
            'description': 'Medellín, Antioquia, Colombia',
            'place_id': 'mock_medellin_id',
          },
        ];
      }
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {'input': query, 'key': _apiKey, 'language': 'es'},
      );

      if (response.statusCode == 200) {
        return response.data['predictions'];
      } else {
        print(
          'Error searching places: ${response.statusCode} - ${response.data}',
        );
        return [];
      }
    } catch (e) {
      print('Exception during place search: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (_isMocking) {
      // Mock data for place details
      if (placeId == 'mock_bogota_id' || placeId == 'mock_bogota_dc_id') {
        return {
          'geometry': {
            'location': {'lat': 4.710989, 'lng': -74.072092},
          }, // Bogota center
          'formatted_address': 'Bogotá, Colombia',
        };
      } else if (placeId == 'mock_medellin_id') {
        return {
          'geometry': {
            'location': {'lat': 6.244203, 'lng': -75.581215},
          }, // Medellin center
          'formatted_address': 'Medellín, Antioquia, Colombia',
        };
      }
      return null;
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry,formatted_address',
          'language': 'es',
        },
      );

      if (response.statusCode == 200) {
        return response.data['result'];
      } else {
        print(
          'Error fetching place details: ${response.statusCode} - ${response.data}',
        );
        return null;
      }
    } catch (e) {
      print('Exception during place details fetch: $e');
      return null;
    }
  }

  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    if (_isMocking) {
      // Mock data for directions (a simple straight line)
      return [
        origin,
        LatLng(
          (origin.latitude + destination.latitude) / 2,
          (origin.longitude + destination.longitude) / 2,
        ),
        destination,
      ];
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
          'mode': 'driving',
          'language': 'es',
        },
      );

      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final leg = routes[0]['legs'][0];
          final polyline = routes[0]['overview_polyline']['points'];
          final PolylinePoints polylinePoints = PolylinePoints();
          final List<PointLatLng> decodedPolyline = polylinePoints
              .decodePolyline(polyline);

          final List<LatLng> latLngList = decodedPolyline
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return latLngList;
        }
      } else {
        print(
          'Error fetching directions: ${response.statusCode} - ${response.data}',
        );
      }
      return [];
    } catch (e) {
      print('Exception during directions fetch: $e');
      return [];
    }
  }
}

