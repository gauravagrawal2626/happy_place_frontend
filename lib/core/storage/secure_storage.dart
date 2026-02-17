import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_keys.dart';

/// SecureStorage provides a wrapper around flutter_secure_storage
/// for storing sensitive data like tokens securely on device
class SecureStorage {
  static SecureStorage? _instance;
  late final FlutterSecureStorage _storage;

  SecureStorage._() {
    // Configure Android options for better security
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
    );
    _storage = const FlutterSecureStorage(aOptions: androidOptions);
  }

  /// Singleton instance
  static SecureStorage get instance {
    _instance ??= SecureStorage._();
    return _instance!;
  }

  // =====================
  // Generic Methods
  // =====================

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // =====================
  // Auth Token Methods
  // =====================

  Future<void> saveAccessToken(String token) async {
    await write(StorageKeys.accessToken, token);
  }

  Future<String?> getAccessToken() async {
    return await read(StorageKeys.accessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await write(StorageKeys.refreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    return await read(StorageKeys.refreshToken);
  }

  // =====================
  // User Data Methods
  // =====================

  Future<void> saveUserData({
    required String userId,
    required String email,
    String? name,
    String? role,
    String? profilePicture,
  }) async {
    await write(StorageKeys.userId, userId);
    await write(StorageKeys.userEmail, email);
    if (name != null) await write(StorageKeys.userName, name);
    if (role != null) await write(StorageKeys.userRole, role);
    if (profilePicture != null) {
      await write(StorageKeys.profilePicture, profilePicture);
    }
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'userId': await read(StorageKeys.userId),
      'email': await read(StorageKeys.userEmail),
      'name': await read(StorageKeys.userName),
      'role': await read(StorageKeys.userRole),
      'profilePicture': await read(StorageKeys.profilePicture),
    };
  }

  Future<String?> getUserId() async {
    return await read(StorageKeys.userId);
  }

  Future<String?> getUserName() async {
    return await read(StorageKeys.userName);
  }

  // =====================
  // Onboarding Status
  // =====================

  Future<void> setOnboardingCompleted(bool completed) async {
    await write(StorageKeys.isOnboardingCompleted, completed.toString());
  }

  Future<bool> isOnboardingCompleted() async {
    final value = await read(StorageKeys.isOnboardingCompleted);
    return value == 'true';
  }

  // =====================
  // Session Management
  // =====================

  /// Check if user is logged in (has valid access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all auth-related data (logout)
  Future<void> clearAuthData() async {
    await delete(StorageKeys.accessToken);
    await delete(StorageKeys.refreshToken);
    await delete(StorageKeys.userId);
    await delete(StorageKeys.userEmail);
    await delete(StorageKeys.userName);
    await delete(StorageKeys.userRole);
    await delete(StorageKeys.profilePicture);
    await delete(StorageKeys.isOnboardingCompleted);
  }
}

