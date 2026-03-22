import 'package:flutter/foundation.dart';

import 'analytics_button_names.dart';
import 'analytics_event_names.dart';
import 'analytics_property_keys.dart';
import 'analytics_provider.dart';
import 'analytics_screen_names.dart';

/// App-wide analytics API. Use constants from [AnalyticsScreenNames] / [AnalyticsButtonNames].
class AnalyticsFacade {
  AnalyticsFacade(this._provider);

  final AnalyticsProvider _provider;

  Map<String, Object> _baseProps({String? screenName}) {
    final m = <String, Object>{
      AnalyticsPropertyKeys.platform: _platformLabel(),
    };
    if (screenName != null) {
      m[AnalyticsPropertyKeys.screenName] = screenName;
    }
    return m;
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Funnel-friendly screen event.
  Future<void> screen(String screenName, {String? routePath}) async {
    final props = _baseProps();
    props[AnalyticsPropertyKeys.screenName] = screenName;
    if (routePath != null) {
      props[AnalyticsPropertyKeys.routePath] = routePath;
    }
    await _provider.logEvent(
      eventName: AnalyticsEventNames.screenView,
      properties: props,
    );
  }

  /// Button / action click.
  Future<void> button(
    String buttonName, {
    String? screenName,
    Map<String, Object>? extra,
  }) async {
    final props = _baseProps(screenName: screenName);
    props[AnalyticsPropertyKeys.buttonName] = buttonName;
    if (extra != null) {
      props.addAll(extra);
    }
    await _provider.logEvent(
      eventName: AnalyticsEventNames.buttonClicked,
      properties: props,
    );
  }

  /// Custom outcome event (e.g. onboarding_completed).
  Future<void> track(
    String eventName, {
    String? screenName,
    Map<String, Object>? properties,
  }) async {
    final props = _baseProps(screenName: screenName);
    if (properties != null) {
      props.addAll(properties);
    }
    await _provider.logEvent(eventName: eventName, properties: props);
  }

  Future<void> identifyUser(String userId, {String? email, String? role}) async {
    final userProps = <String, Object>{};
    if (email != null) userProps['email'] = email;
    if (role != null) userProps[AnalyticsPropertyKeys.role] = role;
    await _provider.identify(
      userId: userId,
      userProperties: userProps.isEmpty ? null : userProps,
    );
  }

  /// User tapped logout — log button + reset. Call before [AppUserLoggedOut].
  Future<void> logOutButtonTap() async {
    await _provider.logEvent(
      eventName: AnalyticsEventNames.buttonClicked,
      properties: {
        ..._baseProps(),
        AnalyticsPropertyKeys.buttonName: AnalyticsButtonNames.logout,
      },
    );
    await _provider.reset();
  }

  /// Clear analytics identity (token expiry, session end). Safe to call after [logOutButtonTap].
  Future<void> resetSession() => _provider.reset();
}
