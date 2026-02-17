/// Matching Repository
/// 
/// Handles API calls for fetching matches.
/// 
/// Endpoints:
/// - GET /api/flats/matches - Get compatible flats (SEEKER) or seekers (LISTER)

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
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
}
