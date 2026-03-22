import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_provider.dart';

/// PostHog implementation of [AnalyticsProvider].
class PosthogAnalyticsProvider implements AnalyticsProvider {
  @override
  Future<void> identify({required String userId, Map<String, Object>? userProperties}) {
    return Posthog().identify(
      userId: userId,
      userProperties: userProperties,
    );
  }

  @override
  Future<void> logEvent({required String eventName, Map<String, Object>? properties}) {
    return Posthog().capture(
      eventName: eventName,
      properties: properties,
    );
  }

  @override
  Future<void> reset() => Posthog().reset();
}
