/// Profile Repository
///
/// Fetches public profile via GET /api/users/{user_id}/public-profile

import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/public_profile_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get public profile for a user
  Future<PublicProfile> getPublicProfile(
    String userId, {
    String? flatId,
    double? matchScore,
    bool includeRequestStatus = true,
  }) async {
    final path = ApiConfig.publicProfile(userId);
    final queryParams = <String, String>{
      if (flatId != null) 'flat_id': flatId,
      if (matchScore != null) 'match_score': matchScore.toString(),
      'include_request_status': includeRequestStatus.toString(),
    };
    debugPrint('[ProfileRepository] getPublicProfile userId=$userId flatId=$flatId path=$path queryParams=$queryParams');

    final response = await _apiClient.get(
      path,
      queryParams: queryParams,
    );
    debugPrint('[ProfileRepository] getPublicProfile response isSuccess=${response.isSuccess} statusCode=${response.statusCode}');

    if (!response.isSuccess) {
      throw Exception(response.errorMessage ?? 'Failed to load profile');
    }
    if (response.data == null) {
      throw Exception('No profile data');
    }

    final raw = response.data as Map<String, dynamic>;
    debugPrint('[ProfileRepository] response top-level keys: ${raw.keys.toList()}');

    // Unwrap if backend nests profile under "data" or "result"
    final data = raw.containsKey('data') && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw.containsKey('result') && raw['result'] is Map
            ? Map<String, dynamic>.from(raw['result'] as Map)
            : raw;

    if (data != raw) {
      debugPrint('[ProfileRepository] unwrapped; profile keys: ${data.keys.toList()}');
    }
    debugPrint('[ProfileRepository] request_status: ${data['request_status']}');
    debugPrint('[ProfileRepository] requestStatus (camelCase): ${data['requestStatus']}');

    return PublicProfile.fromJson(data);
  }
}
