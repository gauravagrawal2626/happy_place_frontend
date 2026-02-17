import '../../features/auth/model/auth_response.dart';

/// App States
/// 
/// Represents the current state of the app:
/// - Loading: App is initializing (checking stored session)
/// - Unauthenticated: No valid session, show login screen
/// - Authenticated: Valid session exists
///   - onboardingCompleted: false -> show onboarding
///   - onboardingCompleted: true -> show home
abstract class AppState {
  const AppState();
}

/// App is initializing (checking stored session)
class AppLoading extends AppState {
  const AppLoading();
}

/// User is not authenticated - show login screen
class AppUnauthenticated extends AppState {
  const AppUnauthenticated();
}

/// User is authenticated
class AppAuthenticated extends AppState {
  final AuthResponse authResponse;
  final bool onboardingCompleted;

  const AppAuthenticated({
    required this.authResponse,
    required this.onboardingCompleted,
  });
}

