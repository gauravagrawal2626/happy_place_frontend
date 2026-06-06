import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/api_config.dart';
import '../../../core/config/env_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorage.instance;

  void _log(String message) {
    debugPrint('[AuthRepository] $message');
  }

  /// Login with LinkedIn credentials
  /// 
  /// Sends LinkedIn auth token to backend for authentication.
  /// Backend validates with LinkedIn and returns JWT token + user info.
  /// 
  /// Request body:
  /// ```json
  /// {
  ///   "provider": "linkedin",
  ///   "auth_token": "linkedin_access_token"
  /// }
  /// ```
  Future<AuthResult> loginWithLinkedIn({
    required String? accessToken,
  }) async {
    _log('Login with LinkedIn');
    
    final response = await _apiClient.post(
      ApiConfig.authLogin,
      body: {
        'provider': 'linkedin',
        'auth_token': accessToken ?? '',
      },
    );

    if (!response.isSuccess) {
    }

    if (response.isSuccess && response.data != null) {
      try {
        final authResponse = AuthResponse.fromJson(response.data);
        _log('Auth successful: ${authResponse.fullName}');
        // Set token for future authenticated requests
        _apiClient.setAuthToken(authResponse.token);
        return AuthResult.success(authResponse);
      } catch (e) {
        _log('❌ Failed to parse response: $e');
        return AuthResult.failure('Failed to parse auth response: $e');
      }
    } else {
      _log('❌ Login failed: ${response.errorMessage}');
      return AuthResult.failure(response.errorMessage ?? 'Login failed');
    }
  }

  /// Login with Google Sign-In
  ///
  /// Uses the google_sign_in package to get a Google ID token, then sends
  /// it to the backend with provider = "google" for verification & JWT issuance.
  Future<AuthResult> loginWithGoogle() async {
    _log('Login with Google');

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: EnvConfig.googleWebClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return AuthResult.failure('Google sign-in cancelled');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      _log('Got Google ID token, sending to backend...');

      final response = await _apiClient.post(
        ApiConfig.authLogin,
        body: {
          'provider': 'google',
          'auth_token': idToken,
        },
      );

      if (response.isSuccess && response.data != null) {
        try {
          final authResponse = AuthResponse.fromJson(response.data);
          _log('Google auth successful: ${authResponse.fullName}');
          _apiClient.setAuthToken(authResponse.token);
          return AuthResult.success(authResponse);
        } catch (e) {
          _log('Failed to parse response: $e');
          return AuthResult.failure('Failed to parse auth response: $e');
        }
      } else {
        _log('Google login failed: ${response.errorMessage}');
        return AuthResult.failure(response.errorMessage ?? 'Google login failed');
      }
    } catch (e) {
      _log('Google sign-in error: $e');
      return AuthResult.failure('Google sign-in error: $e');
    }
  }

  /// Dev mock login (iOS debug only — UI gated with kDebugMode).
  ///
  /// POST /api/auth/login with dev_user: true. Backend must have
  /// DEV_MOCK_AUTH_ENABLED=true and the dev user in MongoDB.
  Future<AuthResult> loginWithDevMock() async {
    _log('Dev mock login');

    final response = await _apiClient.post(
      ApiConfig.authLogin,
      body: {
        'provider': 'google',
        'auth_token': 'simulator',
        'dev_user': true,
      },
    );

    if (response.isSuccess && response.data != null) {
      try {
        final authResponse = AuthResponse.fromJson(response.data);
        _log('Dev mock auth successful: ${authResponse.fullName}');
        _apiClient.setAuthToken(authResponse.token);
        return AuthResult.success(authResponse);
      } catch (e) {
        _log('Failed to parse dev login response: $e');
        return AuthResult.failure('Failed to parse auth response: $e');
      }
    }

    if (response.statusCode == 403) {
      return AuthResult.failure(
        'Dev login disabled on backend (DEV_MOCK_AUTH_ENABLED=false)',
      );
    }
    if (response.statusCode == 404) {
      return AuthResult.failure(
        'Dev user not found in DB (gauravagrawal.2626@gmail.com)',
      );
    }

    _log('Dev mock login failed: ${response.errorMessage}');
    return AuthResult.failure(response.errorMessage ?? 'Dev login failed');
  }

  /// Logout - clear token and storage
  Future<void> logout() async {
    _log('Logging out - clearing auth data...');
    _apiClient.clearAuthToken();
    await _secureStorage.clearAuthData();
    _log('✅ Logout complete');
    // Optionally call logout endpoint to invalidate token on server
    // await _apiClient.post(ApiConfig.authLogout);
  }

  /// Set auth token (used when restoring from local storage)
  void setAuthToken(String token) {
    _apiClient.setAuthToken(token);
  }

  /// Get the API client (for other repositories to reuse)
  ApiClient get apiClient => _apiClient;

  // =====================
  // Session Persistence
  // =====================

  /// Save auth data to secure storage after successful login
  Future<void> saveAuthData(AuthResponse authResponse) async {
    
    // Save tokens
    await _secureStorage.saveAccessToken(authResponse.token);
    
    // Save user data
    await _secureStorage.saveUserData(
      userId: authResponse.userId,
      email: authResponse.email,
      name: authResponse.fullName,
      role: authResponse.role,
    );
    
    // Save onboarding status
    await _secureStorage.setOnboardingCompleted(authResponse.onboardingCompleted);
    
    // Set token for API client
    _apiClient.setAuthToken(authResponse.token);
    
  }

  /// Restore session from secure storage and sync with backend
  /// Returns AuthResponse if valid session exists, null otherwise
  /// Fetches latest user data from backend to ensure state is in sync
  Future<AuthResponse?> restoreSession() async {
    _log('Restoring session...');
    
    final token = await _secureStorage.getAccessToken();
    
    if (token == null || token.isEmpty) {
      _log('No token found in storage');
      return null;
    }
    
    // Restore token to API client first (needed for backend call)
    _apiClient.setAuthToken(token);
    
    // Get stored user data (fallback if backend call fails)
    final userData = await _secureStorage.getUserData();
    final storedOnboardingCompleted = await _secureStorage.isOnboardingCompleted();
    
    if (userData['userId'] == null || userData['email'] == null) {
      _log('Incomplete user data in storage');
      return null;
    }
    
    // Try to sync with backend to get latest user data
    try {
      final response = await _apiClient.get(ApiConfig.currentUser);
      
      // Check for 401 Unauthorized (token expired)
      if (response.statusCode == 401) {
        _log('🔒 Token expired (401) - clearing session and logging out');
        // Clear all stored data
        await _secureStorage.clearAuthData();
        _apiClient.clearAuthToken();
        return null; // Return null to trigger logout
      }
      
      if (response.isSuccess && response.data != null) {
        final backendUserData = response.data as Map<String, dynamic>;
        _log('✅ Fetched latest user data from backend');
        
        // Use backend data (source of truth)
        final authResponse = AuthResponse(
          token: token,
          userId: backendUserData['user_id'] as String? ?? backendUserData['userId'] as String? ?? userData['userId']!,
          email: backendUserData['email'] as String? ?? userData['email']!,
          role: backendUserData['role'] as String? ?? userData['role'] ?? 'SEEKER',
          fullName: backendUserData['full_name'] as String? ?? backendUserData['fullName'] as String? ?? userData['name'] ?? '',
          onboardingCompleted: backendUserData['onboarding_completed'] as bool? ?? storedOnboardingCompleted,
          phoneVerified: backendUserData['phone_verified'] as bool? ?? false,
        );
        
        // Update local storage with backend data to keep it in sync
        await saveAuthData(authResponse);
        _log('Session restored: ${authResponse.email}');
        
        return authResponse;
      } else {
        _log('Failed to fetch from backend, using stored data');
      }
    } catch (e) {
      _log('Error fetching from backend, using stored data: $e');
    }
    
    // Fallback: use stored data if backend call fails (but only if not 401)
    // Note: If we got here, it means the error was not 401, so token might still be valid
    _log('Session restored from storage: ${userData['email']}');
    
    return AuthResponse(
      token: token,
      userId: userData['userId']!,
      email: userData['email']!,
      role: userData['role'] ?? 'SEEKER',
      fullName: userData['name'] ?? '',
      onboardingCompleted: storedOnboardingCompleted,
      phoneVerified: false, // Default to false if not in storage
    );
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _secureStorage.isLoggedIn();
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    return await _secureStorage.isOnboardingCompleted();
  }

  /// Fetch and sync current user data from backend
  /// This is the primary method for syncing user data - used by AppBloc
  /// Updates local storage with backend values (source of truth)
  /// Returns null if token expired (401) - triggers logout
  Future<AuthResponse?> syncUserData() async {
    _log('Syncing user data from backend...');
    
    try {
      final response = await _apiClient.get(ApiConfig.currentUser);
      
      // Check for 401 Unauthorized (token expired)
      if (response.statusCode == 401) {
        _log('🔒 Token expired (401) during sync - clearing session');
        // Clear all stored data
        await _secureStorage.clearAuthData();
        _apiClient.clearAuthToken();
        return null; // Return null to trigger logout
      }
      
      if (response.isSuccess && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        
        // Get current token
        final token = await _secureStorage.getAccessToken();
        if (token == null) {
          _log('❌ No token found, cannot sync');
          return null;
        }
        
        // Create AuthResponse from user data
        final authResponse = AuthResponse(
          token: token,
          userId: userData['user_id'] as String? ?? userData['userId'] as String? ?? '',
          email: userData['email'] as String? ?? '',
          role: userData['role'] as String? ?? 'SEEKER',
          fullName: userData['full_name'] as String? ?? userData['fullName'] as String? ?? '',
          onboardingCompleted: userData['onboarding_completed'] as bool? ?? false,
          phoneVerified: userData['phone_verified'] as bool? ?? false,
        );
        
        // Update local storage
        await saveAuthData(authResponse);
        _log('User data synced from backend');
        return authResponse;
      } else {
        _log('Failed to fetch user data: ${response.errorMessage}');
        return null;
      }
    } catch (e) {
      _log('Error syncing user data: $e');
      return null;
    }
  }
}

/// Auth Result wrapper
class AuthResult {
  final bool isSuccess;
  final AuthResponse? data;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory AuthResult.success(AuthResponse data) {
    return AuthResult._(isSuccess: true, data: data);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}

