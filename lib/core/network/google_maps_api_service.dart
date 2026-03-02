import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:dio/dio.dart';

// Solo importar dart:js en web
import 'dart:js' as js show context;

class GoogleMapsApiService {
  final Dio _dio;
  static const String _apiKey = 'AIzaSyBfBB8OlJW5MSRBD--ukYSNBPR7wwbie8s';

  GoogleMapsApiService(this._dio) {
    if (kIsWeb) {
      print('GoogleMapsApiService: Usando JavaScript API de Google Maps (Web)');
      _ensureGoogleMapsLoaded();
    } else {
      print('GoogleMapsApiService: Usando HTTP API de Google Maps (Mobile)');
    }
  }

  void _ensureGoogleMapsLoaded() {
    if (kIsWeb) {
      if (js.context['google'] == null ||
          js.context['google']['maps'] == null) {
        print('⚠️ Google Maps JavaScript API no está cargada');
        throw Exception('Google Maps API not loaded');
      }
      print('✅ Google Maps JavaScript API cargada correctamente');
    }
  }

  /// Busca lugares usando Google Places Autocomplete API
  Future<List<dynamic>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

    if (kIsWeb) {
      return _searchPlacesWeb(query);
    } else {
      return _searchPlacesMobile(query);
    }
  }

  /// Versión web usando JavaScript API
  Future<List<dynamic>> _searchPlacesWeb(String query) async {
    try {
      final completer = Completer<List<dynamic>>();
      final callbackName =
          'placesCallback_${DateTime.now().millisecondsSinceEpoch}';

      js.context[callbackName] = (response) {
        try {
          js.context.deleteProperty(callbackName);

          if (response != null && response['suggestions'] != null) {
            final suggestions = response['suggestions'];
            final List<dynamic> results = [];
            final length = suggestions['length'];

            for (var i = 0; i < length; i++) {
              final suggestion = suggestions[i];
              final placePrediction = suggestion['placePrediction'];

              if (placePrediction != null) {
                final text = placePrediction['text'];
                final placeId = placePrediction['placeId'];

                results.add({
                  'description': text != null
                      ? text['text']
                      : 'Sin descripción',
                  'place_id': placeId,
                });
              }
            }

            print(
              'GoogleMapsAPI: Encontrados ${results.length} lugares para "$query"',
            );
            completer.complete(results);
          } else {
            print('GoogleMapsAPI: No se encontraron lugares para "$query"');
            completer.complete([]);
          }
        } catch (e) {
          print('Error procesando resultados: $e');
          completer.complete([]);
        }
      };

      final escapedQuery = query.replaceAll('"', '\\"').replaceAll("'", "\\'");

      js.context.callMethod('eval', [
        '''
        (async function() {
          try {
            const { AutocompleteSuggestion } = await google.maps.importLibrary("places");
            const request = {
              input: "$escapedQuery",
              includedRegionCodes: ["ec"],
              language: "es"
            };
            const response = await AutocompleteSuggestion.fetchAutocompleteSuggestions(request);
            window.$callbackName(response);
          } catch (error) {
            console.error('Error en fetchAutocompleteSuggestions:', error);
            window.$callbackName(null);
          }
        })();
      ''',
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          js.context.deleteProperty(callbackName);
          print('Timeout buscando lugares');
          return [];
        },
      );
    } catch (e) {
      print('Exception during place search: $e');
      return [];
    }
  }

  /// Versión mobile usando HTTP API
  Future<List<dynamic>> _searchPlacesMobile(String query) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:ec',
          'language': 'es',
        },
      );

      if (response.statusCode == 200 && response.data['predictions'] != null) {
        return (response.data['predictions'] as List).map((prediction) {
          return {
            'description': prediction['description'],
            'place_id': prediction['place_id'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching places (mobile): $e');
      return [];
    }
  }

  /// Obtiene los detalles de un lugar específico
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (kIsWeb) {
      return _getPlaceDetailsWeb(placeId);
    } else {
      return _getPlaceDetailsMobile(placeId);
    }
  }

  /// Versión web
  Future<Map<String, dynamic>?> _getPlaceDetailsWeb(String placeId) async {
    try {
      final completer = Completer<Map<String, dynamic>?>();
      final callbackName =
          'detailsCallback_${DateTime.now().millisecondsSinceEpoch}';

      js.context[callbackName] = (place) {
        try {
          js.context.deleteProperty(callbackName);

          if (place != null) {
            final location = place['location'];
            final formattedAddress = place['formattedAddress'];

            if (location != null) {
              final lat = location['lat'];
              final lng = location['lng'];

              print(
                'GoogleMapsAPI: Lugar encontrado: $formattedAddress ($lat, $lng)',
              );

              completer.complete({
                'geometry': {
                  'location': {'lat': lat, 'lng': lng},
                },
                'formatted_address': formattedAddress ?? 'Sin dirección',
              });
            } else {
              completer.complete(null);
            }
          } else {
            completer.complete(null);
          }
        } catch (e) {
          print('Error procesando place details: $e');
          completer.complete(null);
        }
      };

      final escapedPlaceId = placeId
          .replaceAll('"', '\\"')
          .replaceAll("'", "\\'");

      js.context.callMethod('eval', [
        '''
        (async function() {
          try {
            const { Place } = await google.maps.importLibrary("places");
            const place = new Place({ id: "$escapedPlaceId" });
            await place.fetchFields({ fields: ["location", "formattedAddress"] });
            window.$callbackName({
              location: { lat: place.location.lat(), lng: place.location.lng() },
              formattedAddress: place.formattedAddress
            });
          } catch (error) {
            console.error('Error en fetchFields:', error);
            window.$callbackName(null);
          }
        })();
      ''',
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          js.context.deleteProperty(callbackName);
          return null;
        },
      );
    } catch (e) {
      print('Exception during place details fetch: $e');
      return null;
    }
  }

  /// Versión mobile
  Future<Map<String, dynamic>?> _getPlaceDetailsMobile(String placeId) async {
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

      if (response.statusCode == 200 && response.data['result'] != null) {
        return response.data['result'];
      }
      return null;
    } catch (e) {
      print('Error getting place details (mobile): $e');
      return null;
    }
  }

  /// Obtiene las direcciones entre dos puntos
  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    if (kIsWeb) {
      return _getDirectionsWeb(origin, destination);
    } else {
      return _getDirectionsMobile(origin, destination);
    }
  }

  /// Versión web
  Future<List<LatLng>> _getDirectionsWeb(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final completer = Completer<List<LatLng>>();
      final callbackName =
          'routesCallback_${DateTime.now().millisecondsSinceEpoch}';

      js.context[callbackName] = (response) {
        try {
          js.context.deleteProperty(callbackName);

          if (response != null && response['ok']) {
            final data = response['data'];

            if (data != null &&
                data['routes'] != null &&
                data['routes'].length > 0) {
              final route = data['routes'][0];
              final polyline = route['polyline'];

              if (polyline != null && polyline['encodedPolyline'] != null) {
                final encodedPolyline = polyline['encodedPolyline'];
                PolylinePoints polylinePoints = PolylinePoints();
                List<PointLatLng> result = polylinePoints.decodePolyline(
                  encodedPolyline.toString(),
                );
                List<LatLng> decodedPath = result
                    .map((point) => LatLng(point.latitude, point.longitude))
                    .toList();

                print('GoogleMapsAPI: Ruta con ${decodedPath.length} puntos');
                completer.complete(decodedPath);
              } else {
                completer.complete([]);
              }
            } else {
              completer.complete([]);
            }
          } else {
            completer.complete([]);
          }
        } catch (e) {
          print('Error procesando routes: $e');
          completer.complete([]);
        }
      };

      js.context.callMethod('eval', [
        '''
        (async function() {
          try {
            const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': '$_apiKey',
                'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs'
              },
              body: JSON.stringify({
                origin: { location: { latLng: { latitude: ${origin.latitude}, longitude: ${origin.longitude} } } },
                destination: { location: { latLng: { latitude: ${destination.latitude}, longitude: ${destination.longitude} } } },
                travelMode: 'DRIVE',
                routingPreference: 'TRAFFIC_AWARE',
                computeAlternativeRoutes: false
              })
            });
            
            if (response.ok) {
              const data = await response.json();
              window.$callbackName({ ok: true, data: data });
            } else {
              window.$callbackName({ ok: false });
            }
          } catch (error) {
            console.error('Error en computeRoutes:', error);
            window.$callbackName({ ok: false });
          }
        })();
      ''',
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          js.context.deleteProperty(callbackName);
          return [];
        },
      );
    } catch (e) {
      print('Exception during directions fetch: $e');
      return [];
    }
  }

  /// Versión mobile
  Future<List<LatLng>> _getDirectionsMobile(
    LatLng origin,
    LatLng destination,
  ) async {
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

      if (response.statusCode == 200 &&
          response.data['routes'] != null &&
          (response.data['routes'] as List).isNotEmpty) {
        final route = response.data['routes'][0];
        final polyline = route['overview_polyline']['points'];

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(polyline);
        return result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting directions (mobile): $e');
      return [];
    }
  }
}
