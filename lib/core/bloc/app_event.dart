/// App Events
/// 
/// Events that trigger app-level state changes
abstract class AppEvent {
  const AppEvent();
}

/// Initialize the app - check stored session
class AppInitialized extends AppEvent {
  const AppInitialized();
}

/// User successfully authenticated
class AppUserAuthenticated extends AppEvent {
  final bool onboardingCompleted;

  const AppUserAuthenticated({required this.onboardingCompleted});
}

/// User completed onboarding
class AppOnboardingCompleted extends AppEvent {
  const AppOnboardingCompleted();
}

/// User logged out
class AppUserLoggedOut extends AppEvent {
  const AppUserLoggedOut();
}

/// Phone number verified
class AppPhoneVerified extends AppEvent {
  const AppPhoneVerified();
}

