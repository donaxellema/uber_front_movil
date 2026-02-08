import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GoogleMapsApiService {
  GoogleMapsApiService(dynamic _dio) {
    print('GoogleMapsApiService: Usando JavaScript API de Google Maps');
    _ensureGoogleMapsLoaded();
  }

  void _ensureGoogleMapsLoaded() {
    if (js.context['google'] == null || js.context['google']['maps'] == null) {
      print('⚠️ Google Maps JavaScript API no está cargada');
      throw Exception('Google Maps API not loaded');
    }
    print('✅ Google Maps JavaScript API cargada correctamente');
  }

  /// Busca lugares usando Google Places Autocomplete API (nueva versión)
  Future<List<dynamic>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

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

      // Escapar query para evitar inyección
      final escapedQuery = query.replaceAll('"', '\\"').replaceAll("'", "\\'");

      // Usar la nueva API de Places
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

  /// Obtiene los detalles de un lugar específico usando su place_id (nueva API)
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
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
              print('GoogleMapsAPI Error: No se encontró ubicación');
              completer.complete(null);
            }
          } else {
            print('GoogleMapsAPI Error: No se encontró el lugar');
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
            const place = new Place({
              id: "$escapedPlaceId"
            });
            await place.fetchFields({
              fields: ["location", "formattedAddress"]
            });
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
          print('Timeout obteniendo detalles del lugar');
          return null;
        },
      );
    } catch (e) {
      print('Exception during place details fetch: $e');
      return null;
    }
  }

  /// Obtiene las direcciones (ruta) entre dos puntos usando Google Routes API v2 (REST)
  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    try {
      final completer = Completer<List<LatLng>>();
      final callbackName =
          'routesCallback_${DateTime.now().millisecondsSinceEpoch}';

      js.context[callbackName] = (response) {
        try {
          js.context.deleteProperty(callbackName);

          if (response != null && response['ok']) {
            // Success response from fetch
            final data = response['data'];

            if (data != null &&
                data['routes'] != null &&
                data['routes'].length > 0) {
              final route = data['routes'][0];
              final legs = route['legs'];

              if (legs != null && legs.length > 0) {
                final leg = legs[0];
                final distanceMeters = leg['distanceMeters'];
                final duration = leg['duration'];

                final durationText = _formatDuration(
                  duration != null ? duration.replaceAll('s', '') : '0',
                );
                final distanceText = _formatDistance(distanceMeters ?? 0);

                print(
                  'GoogleMapsAPI: Ruta encontrada - Distancia: $distanceText, Duración: $durationText',
                );

                final polyline = route['polyline'];
                if (polyline != null && polyline['encodedPolyline'] != null) {
                  final encodedPolyline = polyline['encodedPolyline'];
                  print('🔍 Tipo de polyline: ${encodedPolyline.runtimeType}');
                  print(
                    '🔍 Polyline codificada (primeros 50 chars): ${encodedPolyline.toString().substring(0, encodedPolyline.toString().length > 50 ? 50 : encodedPolyline.toString().length)}',
                  );

                  // Usar el paquete flutter_polyline_points para decodificar
                  PolylinePoints polylinePoints = PolylinePoints();
                  List<PointLatLng> result = polylinePoints.decodePolyline(
                    encodedPolyline.toString(),
                  );

                  // Convertir a LatLng de google_maps_flutter
                  List<LatLng> decodedPath = result
                      .map((point) => LatLng(point.latitude, point.longitude))
                      .toList();

                  print('GoogleMapsAPI: Ruta con ${decodedPath.length} puntos');
                  print(
                    '🔍 Primeros 3 puntos decodificados: ${decodedPath.take(3).toList()}',
                  );
                  completer.complete(decodedPath);
                } else {
                  print('GoogleMapsAPI: No se encontró polyline en la ruta');
                  completer.complete([]);
                }
              } else {
                print('GoogleMapsAPI: No se encontraron legs en la ruta');
                completer.complete([]);
              }
            } else {
              print('GoogleMapsAPI: No se encontraron rutas en la respuesta');
              completer.complete([]);
            }
          } else if (response != null && !response['ok']) {
            print('GoogleMapsAPI Error en Routes API: ${response['error']}');
            completer.complete([]);
          } else {
            print('GoogleMapsAPI: Respuesta vacía de Routes API');
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
                'X-Goog-Api-Key': 'AIzaSyBfBB8OlJW5MSRBD--ukYSNBPR7wwbie8s',
                'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs'
              },
              body: JSON.stringify({
                origin: {
                  location: {
                    latLng: {
                      latitude: ${origin.latitude},
                      longitude: ${origin.longitude}
                    }
                  }
                },
                destination: {
                  location: {
                    latLng: {
                      latitude: ${destination.latitude},
                      longitude: ${destination.longitude}
                    }
                  }
                },
                travelMode: 'DRIVE',
                routingPreference: 'TRAFFIC_AWARE',
                computeAlternativeRoutes: false
              })
            });
            
            if (response.ok) {
              const data = await response.json();
              window.$callbackName({ ok: true, data: data });
            } else {
              const error = await response.text();
              console.error('Routes API Error:', error);
              window.$callbackName({ ok: false, error: error });
            }
          } catch (error) {
            console.error('Error en computeRoutes:', error);
            window.$callbackName({ ok: false, error: error.message });
          }
        })();
      ''',
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          js.context.deleteProperty(callbackName);
          print('Timeout obteniendo direcciones');
          return [];
        },
      );
    } catch (e) {
      print('Exception during directions fetch: $e');
      return [];
    }
  }

  /// Formatea la duración en segundos a formato legible
  String _formatDuration(String seconds) {
    try {
      final totalSeconds = int.parse(seconds);
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;

      if (hours > 0) {
        return '$hours h $minutes min';
      } else {
        return '$minutes min';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  /// Formatea la distancia en metros a formato legible
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return '$km km';
    } else {
      return '$meters m';
    }
  }
}
