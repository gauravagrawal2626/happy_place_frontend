/// Canonical PostHog / analytics event names (use for funnels in Insights).
abstract final class AnalyticsEventNames {
  AnalyticsEventNames._();

  static const String screenView = 'screen_view';
  static const String buttonClicked = 'button_clicked';

  /// Outcome events (optional funnels)
  static const String onboardingCompleted = 'onboarding_completed';
  static const String preferenceSaved = 'preference_saved';
  static const String flatDetailsSaved = 'flat_details_saved';
  static const String profileViewed = 'profile_viewed';
  static const String requestSent = 'request_sent';
  static const String requestAccepted = 'request_accepted';
  static const String requestRejected = 'request_rejected';
  static const String requestCompleted = 'request_completed';
}
