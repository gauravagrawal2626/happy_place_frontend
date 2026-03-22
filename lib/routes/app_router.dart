import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/bloc/app_bloc.dart';
import '../core/bloc/app_state.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/phone_input_screen.dart';
import '../features/auth/view/otp_verification_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/matching/view/map_comparison_screen.dart';
import '../features/matching/view/seeker_map_screen.dart';
import '../features/matching/view/lister_list_screen.dart';
import '../features/matching/view/finding_matches_screen.dart';
import '../features/location/view/seeker_location_screen.dart';
import '../features/location/view/lister_location_screen.dart';
import '../features/flat_requirements/view/flat_requirements_screen.dart';
import '../features/preferences/view/preferences_edit_screen.dart';
import '../features/profile/view/invites_screen.dart';

/// App Router with Auth Guards
/// 
/// Routes:
/// - /login → Login screen (unauthenticated users)
/// - /onboarding → Onboarding screen (authenticated, not onboarded)
/// - /home → Home screen (authenticated, onboarded)
/// - /matching → Map comparison screen
/// 
/// Route Guards:
/// - Unauthenticated users → redirect to /login
/// - Authenticated without onboarding → redirect to /onboarding
/// - Authenticated with onboarding → can access /home

/// Create router based on current app state.
/// Pass [observers] (e.g. [AnalyticsNavigatorObserver]) for automatic screen analytics.
GoRouter createRouter(
  AppState appState, {
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: _getInitialLocation(appState),
    observers: observers.isEmpty ? null : observers,
    redirect: (context, state) {
      // Read current AppBloc state from context (always up-to-date)
      final currentAppState = context.read<AppBloc>().state;
      return _handleRedirect(currentAppState, state);
    },
    routes: [
      // Splash/Loading screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      // Login screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Phone input screen (before onboarding)
      GoRoute(
        path: '/phone-input',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      // OTP verification screen
      GoRoute(
        path: '/phone-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          final phoneNumber = extra?['phoneNumber'] ?? '';
          final sessionId = extra?['sessionId'] ?? '';
          return OTPVerificationScreen(
            phoneNumber: phoneNumber,
            sessionId: sessionId,
          );
        },
      ),
      // Onboarding screen
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Location screens (Phase 4)
      GoRoute(
        path: '/location/seeker',
        builder: (context, state) => const SeekerLocationScreen(),
      ),
      GoRoute(
        path: '/location/lister',
        builder: (context, state) => const ListerLocationScreen(),
      ),
      // Home screen (kept for backward compatibility, but not used in main flow)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // SEEKER Map screen (Frame 11)
      GoRoute(
        path: '/map/seeker',
        builder: (context, state) => const SeekerMapScreen(),
      ),
      // LISTER List screen (placeholder)
      GoRoute(
        path: '/list/lister',
        builder: (context, state) => const ListerListScreen(),
      ),
      // Map comparison screen (legacy)
      GoRoute(
        path: '/matching',
        builder: (context, state) => const MapComparisonScreen(),
      ),
      // Flat Requirements screen (Phase 5)
      // Pass isLister via extra: true = Add Flat Details, false = Modify Preferences
      GoRoute(
        path: '/flat-requirements',
        builder: (context, state) {
          final isLister = state.extra as bool?;
          print('[AppRouter] /flat-requirements - state.extra: ${state.extra}, isLister: $isLister');
          return FlatRequirementsScreen(isListerOverride: isLister);
        },
      ),
      // Preferences Editing screen
      GoRoute(
        path: '/preferences/edit',
        builder: (context, state) => const PreferencesEditScreen(),
      ),
      // Invites screen (sent/received requests)
      GoRoute(
        path: '/account/invites',
        builder: (context, state) => const InvitesScreen(),
      ),
      // Finding Matches screen (shared by location and flat details flows)
      GoRoute(
        path: '/finding-matches/:source',
        builder: (context, state) {
          final sourceParam = state.pathParameters['source'] ?? 'location-seeker';
          final source = switch (sourceParam) {
            'location-seeker' => FindingMatchesSource.locationSeeker,
            'location-lister' => FindingMatchesSource.locationLister,
            'flat-seeker' => FindingMatchesSource.flatDetailsSeeker,
            'flat-lister' => FindingMatchesSource.flatDetailsLister,
            _ => FindingMatchesSource.locationSeeker,
          };
          return FindingMatchesScreen(source: source);
        },
      ),
    ],
  );
}

/// Determine initial location based on app state
String _getInitialLocation(AppState appState) {
  if (appState is AppLoading) {
    return '/splash';
  } else if (appState is AppUnauthenticated) {
    return '/login';
  } else if (appState is AppAuthenticated) {
    // Check phone verification first
    if (!appState.authResponse.phoneVerified) {
      return '/phone-input';
    }
    if (!appState.onboardingCompleted) {
      return '/onboarding';
    }
    // Route based on user role
    return _getMainScreenForRole(appState.authResponse.role);
  }
  return '/login';
}

/// Get the main screen path based on user role
String _getMainScreenForRole(String role) {
  return role == 'LISTER' ? '/list/lister' : '/map/seeker';
}

/// Handle route redirects based on auth state
String? _handleRedirect(AppState appState, GoRouterState state) {
  final currentPath = state.matchedLocation;
  
  // App is loading - show splash
  if (appState is AppLoading) {
    if (currentPath != '/splash') {
      return '/splash';
    }
    return null;
  }
  
  // User is not authenticated
  if (appState is AppUnauthenticated) {
    // Allow only login page
    if (currentPath != '/login') {
      return '/login';
    }
    return null;
  }
  
  // User is authenticated
  if (appState is AppAuthenticated) {
    final onboardingCompleted = appState.onboardingCompleted;
    final phoneVerified = appState.authResponse.phoneVerified;
    
    // PHONE VERIFICATION FLOW: Handled by feature BLoC and screens
    // Router only provides basic guards (prevent access if already verified)
    if (currentPath == '/phone-input' || currentPath == '/phone-verify') {
      // If phone is already verified, redirect away from phone screens
      if (phoneVerified) {
        if (!onboardingCompleted) {
          return '/onboarding';
        }
        return _getMainScreenForRole(appState.authResponse.role);
      }
      // Allow phone verification screens if phone not verified
      return null;
    }
    
    // CASE 1: Phone NOT verified - let AppBloc initial location handle this
    // (Removed redirect logic - screens will handle navigation based on BLoC states)
    
    // CASE 2: Phone verified but onboarding NOT completed
    // Allow onboarding and location screens (part of onboarding flow)
    if (!onboardingCompleted) {
      // Allow onboarding screen
      if (currentPath == '/onboarding') {
        return null;
      }
      // Allow location screens - they appear during onboarding flow
      if (currentPath == '/location/seeker' || currentPath == '/location/lister') {
        return null;
      }
      // Allow flat requirements screen - part of onboarding flow
      if (currentPath == '/flat-requirements') {
        return null;
      }
      // Allow finding matches screen - part of onboarding flow
      if (currentPath.startsWith('/finding-matches')) {
        return null;
      }
      // Redirect everything else to onboarding
      return '/onboarding';
    }
    
    // CASE 3: Phone verified AND onboarding completed
    // Allow all main app screens
    if (onboardingCompleted) {
      // Allow location screens (can be accessed after onboarding too)
      if (currentPath == '/location/seeker' || currentPath == '/location/lister') {
        return null;
      }
      // Allow map/list screens (main screens)
      if (currentPath == '/map/seeker' || currentPath == '/list/lister') {
        return null;
      }
      // Allow flat requirements screen
      if (currentPath == '/flat-requirements') {
        return null;
      }
      // Allow preferences editing screen
      if (currentPath == '/preferences/edit') {
        return null;
      }
      // Allow invites screen (from account modal)
      if (currentPath == '/account/invites') {
        return null;
      }
      // Allow finding matches screen
      if (currentPath.startsWith('/finding-matches')) {
        return null;
      }
      // If trying to access onboarding after completion, redirect to main screen
      if (currentPath == '/onboarding') {
        return _getMainScreenForRole(appState.authResponse.role);
      }
      // If on login or splash, redirect to main screen
      if (currentPath == '/login' || currentPath == '/splash') {
        return _getMainScreenForRole(appState.authResponse.role);
      }
    }
  }
  
  return null;
}

/// Simple splash screen shown during app initialization
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF4DD0E1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon would go here
            Icon(
              Icons.home_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Happy Place',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legacy router variable for backwards compatibility
/// This creates a basic router - prefer using createRouter(appState)
final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/matching',
      builder: (context, state) => const MapComparisonScreen(),
    ),
  ],
);
