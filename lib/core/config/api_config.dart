/// API Configuration
/// 
/// Centralized configuration for backend API connections.
/// Change baseUrl based on environment (local/staging/production).
class ApiConfig {
  // For iOS Simulator: use 127.0.0.1 instead of localhost
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For real device on same network: use your machine's IP (e.g., 192.168.x.x)
  
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // API Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String onboardingQuestions = '/api/questions/onboarding';
  static const String onboardingSubmit = '/api/users/onboard';
  
  // Location Endpoints (Phase 4)
  static const String locationAreas = '/api/locations/areas';
  static const String preferredLocations = '/api/users/preferred-locations';
  static const String flats = '/api/flats';
  static const String currentUser = '/api/auth/me'; // Get current user data
  
  // Flat Requirements Endpoints (Phase 5)
  static const String flatListingQuestions = '/api/questions/flat-listing';
  static const String flatRequirements = '/api/users/flat-requirements';
  static const String uploadPresignedUrl = '/api/upload/presigned-url';
  
  // Preferences Endpoints
  static const String preferencesUpdate = '/api/users/preferences';
  
  // Matches Endpoints
  static const String matches = '/api/flats/matches';
  
  // Profile & Requests Endpoints
  static String publicProfile(String userId) => '/api/users/$userId/public-profile';
  static const String requests = '/api/requests';
  
  // Phone Verification Endpoints
  static const String sendOTP = '/api/auth/send-otp';
  static const String verifyOTP = '/api/auth/verify-otp';
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}

