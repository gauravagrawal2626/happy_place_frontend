/// Property keys sent with analytics events (consistent across backends).
abstract final class AnalyticsPropertyKeys {
  AnalyticsPropertyKeys._();

  static const String screenName = 'screen_name';
  static const String buttonName = 'button_name';
  static const String platform = 'platform';
  static const String routePath = 'route_path';
  static const String userId = 'user_id';
  static const String role = 'role';
  static const String source = 'source';
  static const String questionId = 'question_id';
}
