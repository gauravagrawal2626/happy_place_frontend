import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linkedin_login/linkedin_login.dart';
import '../repository/auth_repository.dart';
import '../model/linkedin_user_model.dart';
import '../model/auth_response.dart';
import 'linkedin_auth_event.dart';
import 'linkedin_auth_state.dart';

/// LinkedIn Auth BLoC
/// 
/// Handles LinkedIn authentication flow:
/// 1. User initiates LinkedIn login
/// 2. LinkedIn SDK returns user profile
/// 3. BLoC calls backend API with LinkedIn data
/// 4. Backend returns JWT token + user info
/// 5. BLoC emits success state
class LinkedInAuthBloc extends Bloc<LinkedInAuthEvent, LinkedInAuthState> {
  final AuthRepository _authRepository;
  AuthResponse? _authResponse;

  LinkedInAuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(LinkedInAuthInitial()) {
    on<LinkedInLoginRequested>(_onLinkedInLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<LinkedInLogoutRequested>(_onLinkedInLogoutRequested);
    _log('LinkedInAuthBloc initialized');
  }

  void _log(String message) {
    debugPrint('[LinkedInAuthBloc] $message');
  }

  /// Get the current auth response (for accessing token, user info)
  AuthResponse? get authResponse => _authResponse;

  Future<void> _onLinkedInLoginRequested(
    LinkedInLoginRequested event,
    Emitter<LinkedInAuthState> emit,
  ) async {
    emit(LinkedInAuthLoading());
  }

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<LinkedInAuthState> emit,
  ) async {
    emit(LinkedInAuthLoading());

    final result = await _authRepository.loginWithGoogle();

    if (result.isSuccess && result.data != null) {
      _log('Google login successful');
      final authData = result.data!;
      _authResponse = authData;
      await _authRepository.saveAuthData(authData);
      emit(GoogleAuthSuccess(authResponse: authData));
    } else {
      _log('Google login failed: ${result.errorMessage}');
      emit(LinkedInAuthFailure(
        error: result.errorMessage ?? 'Google authentication failed',
      ));
    }
  }

  Future<void> _onLinkedInLogoutRequested(
    LinkedInLogoutRequested event,
    Emitter<LinkedInAuthState> emit,
  ) async {
    await _authRepository.logout();
    _authResponse = null;
    emit(LinkedInAuthInitial());
  }

  /// Called when LinkedIn SDK returns user profile
  /// Now calls backend API for authentication
  Future<void> handleLoginSuccess(UserSucceededAction userSucceededAction) async {
    _log('Processing LinkedIn login...');
    
    final linkedInUser = AppLinkedInUser.fromLinkedInUser(userSucceededAction);
    
    // Call backend API with LinkedIn token
    final result = await _authRepository.loginWithLinkedIn(
      accessToken: linkedInUser.accessTokenString,
    );

    if (result.isSuccess && result.data != null) {
      _log('Login successful');
      final authData = result.data!;
      _authResponse = authData;
      
      // Save auth data to secure storage for session persistence
      await _authRepository.saveAuthData(authData);
      
      emit(LinkedInAuthSuccess(
        user: linkedInUser,
        authResponse: authData,
      ));
    } else {
      _log('❌ Login failed: ${result.errorMessage}');
      emit(LinkedInAuthFailure(
        error: result.errorMessage ?? 'Backend authentication failed',
      ));
    }
  }

  void handleLoginError(UserFailedAction error) {
    emit(LinkedInAuthFailure(error: error.toString()));
  }
} 
