/// Centralized storage keys for consistency across the app
/// All keys used in secure storage and shared preferences are defined here
class StorageKeys {
  StorageKeys._();

  // Authentication tokens
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // User data
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';
  static const String profilePicture = 'profile_picture';

  // Onboarding status
  static const String isOnboardingCompleted = 'is_onboarding_completed';

  // App state
  static const String isFirstLaunch = 'is_first_launch';
}

