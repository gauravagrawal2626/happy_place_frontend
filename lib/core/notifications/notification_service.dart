import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

/// Singleton service that manages Firebase Cloud Messaging:
/// - Requests notification permission (iOS + Android 13+)
/// - Fetches and registers FCM token with the backend
/// - Handles token refresh
/// - Listens for foreground notifications (shows SnackBar)
/// - Handles notification taps (background + terminated)
class NotificationService {
  static NotificationService? _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SecureStorage _storage = SecureStorage.instance;

  ApiClient? _apiClient;
  GoRouter? _router;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  void _log(String message) {
    debugPrint('[NotificationService] $message');
  }

  /// Initialise the service after Firebase.initializeApp().
  ///
  /// [apiClient] – authenticated client for backend calls.
  /// [router] – GoRouter instance for notification-tap navigation.
  /// [scaffoldMessengerKey] – global key for showing foreground SnackBars.
  Future<void> init({
    required ApiClient apiClient,
    required GoRouter router,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) async {
    _apiClient = apiClient;
    _router = router;
    _scaffoldMessengerKey = scaffoldMessengerKey;

    await _requestPermission();
    await _fetchAndRegisterToken();
    _listenToTokenRefresh();
    _listenToForegroundMessages();
    _listenToBackgroundMessageTaps();
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log('Permission status: ${settings.authorizationStatus}');
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  Future<void> _fetchAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _log('════════════════════════════════════════');
        _log('FCM TOKEN (copy for Firebase Console):');
        _log(token);
        _log('════════════════════════════════════════');
        await _storage.write(StorageKeys.fcmToken, token);
        await _sendTokenToBackend(token);
      } else {
        _log('FCM token is null – will retry on refresh');
      }
    } catch (e) {
      _log('Error fetching FCM token: $e');
    }
  }

  void _listenToTokenRefresh() {
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      _log('FCM token refreshed:');
      _log(newToken);
      await _storage.write(StorageKeys.fcmToken, newToken);
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    if (_apiClient == null) return;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await _apiClient!.post(
        ApiConfig.registerNotificationToken,
        body: {
          'fcm_token': fcmToken,
          'platform': platform,
        },
      );
      if (response.isSuccess) {
        _log('Token registered with backend');
      } else {
        _log('Backend token registration failed: ${response.errorMessage}');
      }
    } catch (e) {
      _log('Error sending token to backend: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground notifications (app open)
  // ---------------------------------------------------------------------------

  void _listenToForegroundMessages() {
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      _log('Foreground message: ${message.notification?.title}');
      _showInAppBanner(message);
    });
  }

  void _showInAppBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger == null) {
      _log('No ScaffoldMessenger available for foreground banner');
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null) Text(notification.body!),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateFromMessage(message),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background tap (app minimized)
  // ---------------------------------------------------------------------------

  void _listenToBackgroundMessageTaps() {
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _log('Background notification tapped: ${message.data}');
      _navigateFromMessage(message);
    });
  }

  // ---------------------------------------------------------------------------
  // Terminated-state tap (app was closed)
  // ---------------------------------------------------------------------------

  /// Call once from the root widget's initState (via addPostFrameCallback)
  /// after the router is ready.
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _log('App opened from terminated notification: ${message.data}');
      _navigateFromMessage(message);
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _navigateFromMessage(RemoteMessage message) {
    final route = _routeForScreen(message.data['screen']);
    _log('Navigating to $route');
    _router?.go(route);
  }

  String _routeForScreen(String? screen) {
    switch (screen) {
      case 'seeker_home':
        return '/map/seeker';
      case 'lister_home':
        return '/list/lister';
      default:
        return '/map/seeker';
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup (logout)
  // ---------------------------------------------------------------------------

  /// Unregisters FCM token from backend, deletes local token, and cancels
  /// listeners. Call during logout.
  Future<void> unregisterAndCleanup() async {
    _log('Cleaning up FCM token...');
    try {
      await _messaging.deleteToken();
      _log('FCM token deleted from device');
    } catch (e) {
      _log('Error deleting FCM token: $e');
    }
    await _storage.delete(StorageKeys.fcmToken);
    _log('FCM cleanup complete');
  }

  /// Cancel stream subscriptions (called if the service is torn down).
  void dispose() {
    _foregroundSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _tokenRefreshSub?.cancel();
  }
}
