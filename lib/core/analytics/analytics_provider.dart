/// Pluggable analytics backend (PostHog, Firebase, or no-op).
abstract class AnalyticsProvider {
  Future<void> logEvent({
    required String eventName,
    Map<String, Object>? properties,
  });

  Future<void> identify({required String userId, Map<String, Object>? userProperties});

  Future<void> reset();
}
