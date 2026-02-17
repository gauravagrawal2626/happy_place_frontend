import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/location_model.dart';

/// Location Repository - Phase 4
/// 
/// Handles location-related API calls:
/// - Get popular areas for a city (SEEKER)
/// - Save preferred locations (SEEKER)
/// - Create draft flat with location (LISTER)
class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  void _log(String message) {
    debugPrint('[LocationRepository] $message');
  }

  /// Get popular areas for a city (SEEKER)
  /// 
  /// GET /api/locations/areas?city=Bangalore
  Future<LocationResult<AreasResponse>> getAreasForCity(String city) async {
    _log('Fetching areas for city: $city');
    
    final response = await _apiClient.get(
      ApiConfig.locationAreas,
      queryParams: {'city': city},
    );

    if (response.isSuccess && response.data != null) {
      try {
        // response.data is already the full response: {"areas": [...], "city": "...", "total": 46}
        final areasResponse = AreasResponse.fromJson(response.data as Map<String, dynamic>);
        _log('✅ Loaded ${areasResponse.areas.length} areas for $city');
        return LocationResult.success(areasResponse);
      } catch (e) {
        _log('❌ Failed to parse areas: $e');
        return LocationResult.failure('Failed to parse areas: $e');
      }
    } else {
      _log('❌ API error: ${response.errorMessage}');
      return LocationResult.failure(response.errorMessage ?? 'Failed to load areas');
    }
  }

  /// Save preferred locations (SEEKER)
  /// 
  /// POST /api/users/preferred-locations
  /// Body: { locations: [...], search_radius_km: 3.0 }
  Future<LocationResult<void>> savePreferredLocations(
    PreferredLocationsRequest request,
  ) async {
    _log('Saving ${request.locations.length} preferred locations...');
    
    final response = await _apiClient.post(
      ApiConfig.preferredLocations,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      _log('✅ Preferred locations saved successfully');
      return LocationResult.success(null);
    } else {
      _log('❌ Save failed: ${response.errorMessage}');
      return LocationResult.failure(response.errorMessage ?? 'Failed to save locations');
    }
  }

  /// Create draft flat with location (LISTER)
  /// 
  /// POST /api/flats
  /// Body: { location: {...}, locality: "...", city: "...", pincode: "...", is_draft: true }
  Future<LocationResult<DraftFlatResponse>> createDraftFlat(
    CreateDraftFlatRequest request,
  ) async {
    _log('Creating draft flat...');
    
    final response = await _apiClient.post(
      ApiConfig.flats,
      body: request.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      try {
        final draftResponse = DraftFlatResponse.fromJson(response.data);
        _log('✅ Draft flat created: ${draftResponse.flatId}');
        return LocationResult.success(draftResponse);
      } catch (e) {
        _log('❌ Failed to parse draft response: $e');
        return LocationResult.failure('Failed to parse response: $e');
      }
    } else {
      _log('❌ Create failed: ${response.errorMessage}');
      return LocationResult.failure(response.errorMessage ?? 'Failed to create draft flat');
    }
  }
}

/// Result wrapper for location operations
class LocationResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  LocationResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory LocationResult.success(T? data) {
    return LocationResult._(isSuccess: true, data: data);
  }

  factory LocationResult.failure(String message) {
    return LocationResult._(isSuccess: false, errorMessage: message);
  }
}
