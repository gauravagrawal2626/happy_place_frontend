/// Matching Repository
/// 
/// Handles API calls for fetching matches and match filters.
/// 
/// Endpoints:
/// - GET /api/flats/matches - Get compatible flats (SEEKER) or seekers (LISTER)
/// - GET /api/flats/match-filters - Get available filter options
/// - POST /api/flats/matches - Get matches with applied filters

import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../location/model/location_model.dart';
import '../model/filter_model.dart';
import '../model/match_model.dart';

class MatchingRepository {
  final ApiClient _apiClient;

  MatchingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get matches
  /// 
  /// GET /api/flats/matches
  /// 
  /// For SEEKER: Returns flats near preferred locations
  /// For LISTER: Returns seekers near flat location
  Future<MatchResponse> getMatches({
    required double radiusKm, // Required: 0.5-20
    String? flatId, // Optional: For LISTER, omit to auto-select latest
    double? latitude, // Optional: For SEEKER, ignored if preferred locations exist
    double? longitude, // Optional: For SEEKER, ignored if preferred locations exist
    int skip = 0, // Pagination offset
    int limit = 20, // Results per page
    String? listingType, // Filter: ENTIRE_FLAT or SHARED_ROOM
    double? minRent, // Minimum rent filter
    double? maxRent, // Maximum rent filter
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'radius_km': radiusKm.toString(),
        if (skip > 0) 'skip': skip.toString(),
        if (limit != 20) 'limit': limit.toString(),
        if (flatId != null) 'flat_id': flatId,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (listingType != null) 'listing_type': listingType,
        if (minRent != null) 'min_rent': minRent.toString(),
        if (maxRent != null) 'max_rent': maxRent.toString(),
      };

      print('[MatchingRepository] Fetching matches from: ${ApiConfig.matches}');
      print('[MatchingRepository] Query params: $queryParams');

      final response = await _apiClient.get(
        ApiConfig.matches,
        queryParams: queryParams,
      );

      print('[MatchingRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to load matches');
      }

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      // Print the full response from backend
      print('═══════════════════════════════════════════════════════════');
      print('🔍 MATCHES API RESPONSE:');
      print('═══════════════════════════════════════════════════════════');
      print(response.data);
      print('═══════════════════════════════════════════════════════════');

      print('[MatchingRepository] Matches loaded successfully');
      return MatchResponse.fromJson(response.data);
    } catch (e) {
      print('[MatchingRepository] Error getting matches: $e');
      rethrow;
    }
  }

  /// Get match filters
  ///
  /// GET /api/flats/match-filters
  ///
  /// Returns the list of question-based filters available for the current user.
  Future<MatchFiltersResponse> getMatchFilters() async {
    try {
      print('[MatchingRepository] Fetching match filters from: ${ApiConfig.matchFilters}');

      final response = await _apiClient.get(ApiConfig.matchFilters);

      print('[MatchingRepository] Filters response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to load match filters');
      }

      if (response.data == null) {
        throw Exception('No filter data received from server');
      }

      print('[MatchingRepository] Match filters loaded successfully');
      return MatchFiltersResponse.fromJson(response.data);
    } catch (e) {
      print('[MatchingRepository] Error getting match filters: $e');
      rethrow;
    }
  }

  /// Post matches with filters
  ///
  /// POST /api/flats/matches
  ///
  /// Sends filter selections to get filtered match results.
  Future<MatchResponse> postMatches({
    required double radiusKm,
    String? flatId,
    int skip = 0,
    int limit = 20,
    List<FilterItem>? filters,
    List<LocationOverride>? locationOverrides,
  }) async {
    try {
      final queryParams = <String, String>{
        'radius_km': radiusKm.toString(),
        if (skip > 0) 'skip': skip.toString(),
        if (limit != 20) 'limit': limit.toString(),
        if (flatId != null) 'flat_id': flatId,
      };

      final body = <String, dynamic>{};
      if (filters != null && filters.isNotEmpty) {
        body['filters'] = filters.map((f) => f.toJson()).toList();
      }
      if (locationOverrides != null && locationOverrides.isNotEmpty) {
        body['location_overrides'] =
            locationOverrides.map((l) => l.toJson()).toList();
      }

      print('[MatchingRepository] POST matches with filters');
      print('[MatchingRepository] Query params: $queryParams');
      print('[MatchingRepository] Body: ${jsonEncode(body)}');

      final response = await _apiClient.post(
        ApiConfig.matches,
        body: body,
        queryParams: queryParams,
      );

      print('[MatchingRepository] POST response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to post filtered matches');
      }

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      return MatchResponse.fromJson(response.data);
    } catch (e) {
      print('[MatchingRepository] Error posting filtered matches: $e');
      rethrow;
    }
  }

  /// Browse popular areas for a city (used by location filter sheet).
  Future<List<Area>> browseAreas(String city) async {
    final response = await _apiClient.get(
      ApiConfig.locationAreas,
      queryParams: {'city': city},
    );
    if (!response.isSuccess || response.data == null) return [];
    final areas = response.data['areas'] as List<dynamic>?;
    return areas
            ?.map((a) => Area.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// Search areas by name (used by location filter sheet).
  Future<List<Area>> searchAreas(String query, String city) async {
    final response = await _apiClient.get(
      ApiConfig.locationAreasSearch,
      queryParams: {'q': query, 'city': city},
    );
    if (!response.isSuccess || response.data == null) return [];
    final results = response.data is List
        ? response.data as List<dynamic>
        : (response.data['areas'] as List<dynamic>?) ?? [];
    return results
        .map((a) => Area.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}
