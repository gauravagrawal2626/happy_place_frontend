/// Preferences Repository
/// 
/// Handles API calls for preference editing.
/// 
/// Endpoints:
/// - GET /api/questions/onboarding - Get questions (filtered by show_in_preferences)
/// - PUT /api/users/preferences - Update preferences

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../onboarding/model/question_model.dart';

class PreferencesRepository {
  final ApiClient _apiClient;

  PreferencesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get questions for preference editing
  /// 
  /// Uses the same endpoint as onboarding but filters by show_in_preferences: true
  Future<List<Question>> getPreferenceQuestions() async {
    try {
      print('[PreferencesRepository] Fetching preference questions from: ${ApiConfig.onboardingQuestions}');
      final response = await _apiClient.get(ApiConfig.onboardingQuestions);
      
      print('[PreferencesRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to load preference questions');
      }
      
      if (response.data == null) {
        throw Exception('No data received from server');
      }
      
      // Parse response
      final questionsJson = response.data['questions'] as List<dynamic>? ?? [];
      final allQuestions = questionsJson
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
      
      // Filter to only questions with show_in_preferences: true
      final preferenceQuestions = allQuestions
          .where((q) => q.showInPreferences)
          .toList();
      
      print('[PreferencesRepository] Loaded ${preferenceQuestions.length} preference questions');
      return preferenceQuestions;
    } catch (e) {
      print('[PreferencesRepository] Error getting preference questions: $e');
      rethrow;
    }
  }

  /// Update user preferences
  /// 
  /// PUT /api/users/preferences
  /// Only sends changed responses
  Future<PreferencesUpdateResponse> updatePreferences({
    required List<PreferenceResponse> responses,
  }) async {
    try {
      print('[PreferencesRepository] Updating preferences to: ${ApiConfig.preferencesUpdate}');
      print('[PreferencesRepository] Request body: ${responses.map((r) => r.toJson()).toList()}');
      
      final response = await _apiClient.put(
        ApiConfig.preferencesUpdate,
        body: {
          'responses': responses.map((r) => r.toJson()).toList(),
        },
      );
      
      print('[PreferencesRepository] Response - isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}');
      
      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Failed to update preferences');
      }
      
      if (response.data == null) {
        throw Exception('No response data received');
      }
      
      print('[PreferencesRepository] Preferences updated successfully');
      return PreferencesUpdateResponse.fromJson(response.data);
    } catch (e) {
      print('[PreferencesRepository] Error updating preferences: $e');
      rethrow;
    }
  }
}

/// Preference response for API
class PreferenceResponse {
  final String questionId;
  final dynamic answer; // Can be String, int, List<String>

  PreferenceResponse({
    required this.questionId,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer': answer,
    };
  }
}

/// Response from preferences update
class PreferencesUpdateResponse {
  final String message;
  final String userId;
  final int responsesUpdated;
  final bool onboardingCompleted;

  PreferencesUpdateResponse({
    required this.message,
    required this.userId,
    required this.responsesUpdated,
    required this.onboardingCompleted,
  });

  factory PreferencesUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PreferencesUpdateResponse(
      message: json['message'] as String? ?? 'Preferences updated successfully',
      userId: json['user_id'] as String? ?? '',
      responsesUpdated: json['responses_updated'] as int? ?? 0,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? true,
    );
  }
}
