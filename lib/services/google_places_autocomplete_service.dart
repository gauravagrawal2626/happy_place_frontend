import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;

import '../core/config/env_config.dart';
import 'location_autocomplete_service.dart';

/// Google Places Autocomplete + Place Details via REST.
/// Uses [EnvConfig.placesApiKeyForCurrentPlatform] (iOS: PLACES_API_KEY, Android: PLACES_API_KEY_ANDROID).
class GooglePlacesAutocompleteService {
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  final String? _apiKey = EnvConfig.placesApiKeyForCurrentPlatform;

  /// True when a key is configured for the current platform.
  bool get isAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  /// Autocomplete: returns predictions as [LocationSuggestion] with [placeId] set and stub location.
  Future<List<LocationSuggestion>> search(String query, {int limit = 5}) async {
    if (!isAvailable || query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
        'input': query,
        'key': _apiKey!,
        'types': 'address',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return [];

      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        // e.g. REQUEST_DENIED, INVALID_REQUEST, OVER_QUERY_LIMIT
        final msg = data['error_message'] as String?;
        debugPrint('Places Autocomplete: status=$status${msg != null ? ', error_message=$msg' : ''}');
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      final list = <LocationSuggestion>[];
      for (var i = 0; i < predictions.length && list.length < limit; i++) {
        final p = predictions[i] as Map<String, dynamic>;
        final description = p['description'] as String? ?? '';
        final placeId = p['place_id'] as String?;
        if (placeId == null) continue;
        list.add(LocationSuggestion(
          displayName: description,
          location: const latlong2.LatLng(0, 0),
          placeId: placeId,
        ));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Fetches full place details and returns a [LocationSuggestion] with lat/lng and address.
  Future<LocationSuggestion?> getPlaceDetails(String placeId) async {
    if (!isAvailable || placeId.isEmpty) return null;
    try {
      final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,address_components,formatted_address',
        'key': _apiKey!,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return null;
      final detailsStatus = data['status'] as String?;
      if (detailsStatus != 'OK') {
        final msg = data['error_message'] as String?;
        debugPrint('Places Details: status=$detailsStatus${msg != null ? ', error_message=$msg' : ''}');
        return null;
      }
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return LocationSuggestion.fromGooglePlaceDetails(result);
    } catch (e) {
      return null;
    }
  }
}
