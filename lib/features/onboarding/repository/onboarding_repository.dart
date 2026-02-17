import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/question_model.dart';

/// Onboarding Repository
/// 
/// Handles all onboarding-related API calls:
/// - Fetch onboarding questions
/// - Submit onboarding answers
class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  void _log(String message) {
    debugPrint('[OnboardingRepository] $message');
  }

  /// Fetch onboarding questions from API
  /// 
  /// GET /api/questions/onboarding
  /// Requires: Authorization header with JWT token
  Future<OnboardingResult<OnboardingQuestionsResponse>> getQuestions() async {
    _log('Fetching onboarding questions...');
    
    final response = await _apiClient.get(ApiConfig.onboardingQuestions);

    if (response.isSuccess && response.data != null) {
      try {
        final questionsResponse = OnboardingQuestionsResponse.fromJson(response.data);
        _log('✅ Loaded ${questionsResponse.totalQuestions} questions');
        return OnboardingResult.success(questionsResponse);
      } catch (e) {
        _log('❌ Failed to parse questions: $e');
        return OnboardingResult.failure('Failed to parse questions: $e');
      }
    } else {
      _log('❌ API error: ${response.errorMessage}');
      return OnboardingResult.failure(response.errorMessage ?? 'Failed to load questions');
    }
  }

  /// Submit onboarding answers
  /// 
  /// POST /api/users/onboard
  /// Body: { "responses": [{"question_id": "...", "answer": ...}, ...] }
  Future<OnboardingResult<void>> submitAnswers(List<OnboardingAnswer> answers) async {
    _log('Submitting ${answers.length} answers...');
    
    final response = await _apiClient.post(
      ApiConfig.onboardingSubmit,
      body: {
        'responses': answers.map((a) => a.toJson()).toList(),
      },
    );

    if (response.isSuccess) {
      _log('✅ Onboarding submitted successfully');
      return OnboardingResult.success(null);
    } else {
      _log('❌ Submit failed: ${response.errorMessage}');
      return OnboardingResult.failure(response.errorMessage ?? 'Failed to submit');
    }
  }
}

/// Result wrapper for onboarding operations
class OnboardingResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  OnboardingResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory OnboardingResult.success(T? data) {
    return OnboardingResult._(isSuccess: true, data: data);
  }

  factory OnboardingResult.failure(String message) {
    return OnboardingResult._(isSuccess: false, errorMessage: message);
  }
}

