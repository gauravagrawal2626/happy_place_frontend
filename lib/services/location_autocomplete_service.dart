import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;

/// Represents a location suggestion from autocomplete.
/// When [placeId] is set, this is a Google prediction (display only); lat/lng/address come after Place Details.
class LocationSuggestion {
  final String displayName;
  final latlong2.LatLng location;
  final String? address;
  final String? type; // e.g., "city", "suburb", "road"
  /// Google Place ID; when non-null, suggestion is a prediction and full details must be fetched.
  final String? placeId;

  // Parsed address details
  final String? locality;  // suburb, neighbourhood, or city_district
  final String? city;      // city, town, or village
  final String? pincode;   // postcode
  final String? state;     // state
  final String? country;   // country

  LocationSuggestion({
    required this.displayName,
    required this.location,
    this.address,
    this.type,
    this.placeId,
    this.locality,
    this.city,
    this.pincode,
    this.state,
    this.country,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0;
    
    // Parse address details from Nominatim response
    final addressDetails = json['address'] as Map<String, dynamic>? ?? {};
    
    // Extract locality (prefer suburb, then neighbourhood, then city_district)
    final locality = addressDetails['suburb'] as String? ??
        addressDetails['neighbourhood'] as String? ??
        addressDetails['city_district'] as String? ??
        addressDetails['town'] as String?;
    
    // Extract city (prefer city, then town, then village)
    final city = addressDetails['city'] as String? ??
        addressDetails['town'] as String? ??
        addressDetails['village'] as String? ??
        addressDetails['municipality'] as String?;
    
    // Extract pincode
    final pincode = addressDetails['postcode'] as String?;
    
    // Extract state
    final state = addressDetails['state'] as String? ??
        addressDetails['state_district'] as String?;
    
    // Extract country
    final country = addressDetails['country'] as String?;
    
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      location: latlong2.LatLng(lat, lon),
      address: json['display_name'],
      type: json['type'],
      locality: locality,
      city: city,
      pincode: pincode,
      state: state,
      country: country,
    );
  }

  /// Builds from Google Place Details API result (result object, not full response).
  static LocationSuggestion fromGooglePlaceDetails(Map<String, dynamic> result) {
    final geo = result['geometry'] as Map<String, dynamic>?;
    final loc = geo?['location'] as Map<String, dynamic>? ?? {};
    final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc['lng'] as num?)?.toDouble() ?? 0.0;
    final formattedAddress = result['formatted_address'] as String? ?? '';
    final components = result['address_components'] as List<dynamic>? ?? [];
    String? locality;
    String? city;
    String? pincode;
    String? state;
    String? country;
    for (final c in components) {
      final map = c as Map<String, dynamic>;
      final types = (map['types'] as List<dynamic>?)?.cast<String>() ?? [];
      final longName = map['long_name'] as String? ?? '';
      if (types.contains('locality')) locality ??= longName;
      if (types.contains('administrative_area_level_2')) city ??= longName;
      if (types.contains('postal_code')) pincode ??= longName;
      if (types.contains('administrative_area_level_1')) state ??= longName;
      if (types.contains('country')) country ??= longName;
    }
    city ??= locality;
    return LocationSuggestion(
      displayName: formattedAddress,
      location: latlong2.LatLng(lat, lng),
      address: formattedAddress,
      placeId: null,
      locality: locality,
      city: city,
      pincode: pincode,
      state: state,
      country: country,
    );
  }
}

/// LocationAutocompleteService provides location search with autocomplete suggestions.
/// 
/// Uses OpenStreetMap Nominatim API (free, no API key required)
/// Rate limit: 1 request per second (we use debouncing to respect this)
class LocationAutocompleteService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  
  DateTime? _lastRequestTime;
  String? _lastQuery;
  List<LocationSuggestion>? _lastResults;

  /// Search for locations with autocomplete suggestions
  /// 
  /// [query] - Search text entered by user
  /// [countryCode] - Optional country code to limit results (e.g., 'in' for India)
  /// [limit] - Maximum number of results (default: 5)
  Future<List<LocationSuggestion>> search(
    String query, {
    String? countryCode,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Debounce: Don't make request if query hasn't changed
    if (_lastQuery == query && _lastResults != null) {
      return _lastResults!;
    }

    // Rate limiting: Wait at least 1 second between requests
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < const Duration(seconds: 1)) {
        await Future.delayed(
          const Duration(seconds: 1) - timeSinceLastRequest,
        );
      }
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        if (countryCode != null) 'countrycodes': countryCode,
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'HappyPlaceApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data
            .map((item) => LocationSuggestion.fromJson(item))
            .toList();

        _lastRequestTime = DateTime.now();
        _lastQuery = query;
        _lastResults = suggestions;

        return suggestions;
      } else {
        return [];
      }
    } catch (e) {
      print('Error in location autocomplete: $e');
      return [];
    }
  }

  /// Clear cached results
  void clearCache() {
    _lastQuery = null;
    _lastResults = null;
  }
}

