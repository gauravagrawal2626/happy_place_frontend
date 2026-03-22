import 'analytics_provider.dart';

/// No-op provider for tests or when analytics keys are missing.
class NoOpAnalyticsProvider implements AnalyticsProvider {
  @override
  Future<void> identify({required String userId, Map<String, Object>? userProperties}) async {}

  @override
  Future<void> logEvent({required String eventName, Map<String, Object>? properties}) async {}

  @override
  Future<void> reset() async {}
}
