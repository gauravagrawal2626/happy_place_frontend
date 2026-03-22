import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../config/env_config.dart';
import 'analytics_facade.dart';
import 'noop_analytics_provider.dart';
import 'posthog_analytics_provider.dart';

/// Initializes PostHog from [.env] when [EnvConfig.posthogApiClientKey] is set; otherwise no-op.
Future<AnalyticsFacade> bootstrapAnalytics() async {
  final apiKey = EnvConfig.posthogApiClientKey;
  final host = EnvConfig.posthogHost;

  if (apiKey == null || apiKey.isEmpty) {
    debugPrint('[Analytics] POSTHOG_API_CLIENT_KEY missing — analytics disabled (no-op)');
    return AnalyticsFacade(NoOpAnalyticsProvider());
  }

  final config = PostHogConfig(apiKey);
  config.host = host ?? 'https://us.i.posthog.com';
  config.debug = kDebugMode;
  config.captureApplicationLifecycleEvents = true;

  try {
    await Posthog().setup(config);
    debugPrint('[Analytics] PostHog initialized');
  } catch (e, st) {
    debugPrint('[Analytics] PostHog setup failed: $e\n$st');
    return AnalyticsFacade(NoOpAnalyticsProvider());
  }

  return AnalyticsFacade(PosthogAnalyticsProvider());
}
