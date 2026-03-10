import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads env variables loaded from .env (see main.dart).
/// Single place for API keys; platform-specific keys are resolved here.
class EnvConfig {
  static String? _trimmed(String? v) =>
      (v != null && v.trim().isNotEmpty) ? v.trim() : null;

  /// Google Places API key for the current platform. iOS: PLACES_API_KEY; Android: PLACES_API_KEY_ANDROID. Web/other: null.
  static String? get placesApiKeyForCurrentPlatform {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _trimmed(dotenv.maybeGet('PLACES_API_KEY'));
      case TargetPlatform.android:
        return _trimmed(dotenv.maybeGet('PLACES_API_KEY_ANDROID'));
      default:
        return null;
    }
  }

  /// LinkedIn OAuth (from .env). Required for LinkedIn login.
  static String get linkedInClientId => _trimmed(dotenv.maybeGet('LINKEDIN_CLIENT_ID')) ?? '';
  static String get linkedInClientSecret => _trimmed(dotenv.maybeGet('LINKEDIN_CLIENT_SECRET')) ?? '';
  static String get linkedInRedirectUri => _trimmed(dotenv.maybeGet('LINKEDIN_REDIRECT_URI')) ?? '';

  /// Google Sign-In (from .env).
  /// Web client ID is used as serverClientId so we get an ID token for backend verification.
  /// iOS client ID is the native OAuth client registered for the iOS bundle.
  static String get googleWebClientId => _trimmed(dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID')) ?? '';
  static String get googleIosClientId => _trimmed(dotenv.maybeGet('GOOGLE_IOS_CLIENT_ID')) ?? '';
}
