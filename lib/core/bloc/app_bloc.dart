import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import 'app_event.dart';
import 'app_state.dart';

/// App BLoC
/// 
/// Manages the overall app state:
/// - Initialization (checks for stored session)
/// - Authentication state changes
/// - Onboarding completion
/// 
/// Flow:
/// 1. App starts -> AppInitialized event
/// 2. Check secure storage for saved session
/// 3. If valid session -> AppAuthenticated (with onboardingCompleted flag)
/// 4. If no session -> AppUnauthenticated (show login)
/// 5. After login -> AppUserAuthenticated event
/// 6. After onboarding -> AppOnboardingCompleted event
class AppBloc extends Bloc<AppEvent, AppState> {
  final AuthRepository _authRepository;

  AppBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AppLoading()) {
    on<AppInitialized>(_onAppInitialized);
    on<AppUserAuthenticated>(_onUserAuthenticated);
    on<AppOnboardingCompleted>(_onOnboardingCompleted);
    on<AppUserLoggedOut>(_onUserLoggedOut);
    on<AppPhoneVerified>(_onPhoneVerified);
    
    _log('AppBloc initialized');
  }

  void _log(String message) {
    debugPrint('[AppBloc] $message');
  }

  /// Get the auth repository (for sharing with other blocs)
  AuthRepository get authRepository => _authRepository;

  /// Initialize app - check for stored session
  Future<void> _onAppInitialized(
    AppInitialized event,
    Emitter<AppState> emit,
  ) async {
    _log('Initializing app...');
    
    try {
      // Try to restore session from secure storage
      final authResponse = await _authRepository.restoreSession();
      
      if (authResponse != null) {
        _log('Session restored: ${authResponse.email}');
        
        emit(AppAuthenticated(
          authResponse: authResponse,
          onboardingCompleted: authResponse.onboardingCompleted,
        ));
      } else {
        // authResponse is null - either no session or token expired
        _log('No valid session - user needs to login');
        // Clear any stale data
        await _authRepository.logout();
        emit(const AppUnauthenticated());
      }
    } catch (e) {
      _log('❌ Error during initialization: $e');
      // Clear any stale data on error
      await _authRepository.logout();
      emit(const AppUnauthenticated());
    }
  }

  /// User authenticated (after login)
  Future<void> _onUserAuthenticated(
    AppUserAuthenticated event,
    Emitter<AppState> emit,
  ) async {
    _log('User authenticated - onboarding completed: ${event.onboardingCompleted}');
    
    final authResponse = await _authRepository.restoreSession();
    
    if (authResponse != null) {
      emit(AppAuthenticated(
        authResponse: authResponse,
        onboardingCompleted: event.onboardingCompleted,
      ));
    }
  }

  /// Onboarding completed
  /// Syncs user data from backend and updates AppBloc state
  Future<void> _onOnboardingCompleted(
    AppOnboardingCompleted event,
    Emitter<AppState> emit,
  ) async {
    _log('Onboarding completed - syncing with backend...');
    
    // Sync user data from backend (source of truth)
    final syncedAuthResponse = await _authRepository.syncUserData();
    
    final currentState = state;
    if (currentState is AppAuthenticated) {
      // Use synced data if available, otherwise use current state
      final authResponse = syncedAuthResponse ?? currentState.authResponse;
      final onboardingCompleted = syncedAuthResponse?.onboardingCompleted ?? 
                                   currentState.onboardingCompleted;
      
      // IMPORTANT: Preserve phone verification status from current state
      // If user already completed onboarding, they must have verified phone earlier
      // Don't let backend sync override phoneVerified to false (could be timing issue)
      final phoneVerified = currentState.authResponse.phoneVerified || 
                           (syncedAuthResponse?.phoneVerified ?? false);
      
      emit(AppAuthenticated(
        authResponse: authResponse.copyWith(phoneVerified: phoneVerified),
        onboardingCompleted: onboardingCompleted,
      ));
    }
  }

  /// User logged out
  Future<void> _onUserLoggedOut(
    AppUserLoggedOut event,
    Emitter<AppState> emit,
  ) async {
    _log('User logged out');
    await _authRepository.logout();
    emit(const AppUnauthenticated());
  }

  /// Phone number verified
  /// Syncs user data from backend to update phone verification status
  Future<void> _onPhoneVerified(
    AppPhoneVerified event,
    Emitter<AppState> emit,
  ) async {
    _log('Phone verified - syncing with backend...');
    
    // Sync user data from backend to get updated phone_verified status
    final syncedAuthResponse = await _authRepository.syncUserData();
    
    final currentState = state;
    if (currentState is AppAuthenticated) {
      // Use synced data if available, otherwise update phoneVerified in current state
      final authResponse = syncedAuthResponse ?? currentState.authResponse.copyWith(phoneVerified: true);
      final phoneVerified = syncedAuthResponse?.phoneVerified ?? true;
      
      emit(AppAuthenticated(
        authResponse: authResponse,
        onboardingCompleted: currentState.onboardingCompleted,
      ));
      
      _log('Phone verification status updated: $phoneVerified');
    }
  }
}

