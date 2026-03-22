/// Logical screen names for [AnalyticsEventNames.screenView] (snake_case).
abstract final class AnalyticsScreenNames {
  AnalyticsScreenNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String phoneInput = 'phone_input';
  static const String phoneVerify = 'phone_verify';
  static const String onboarding = 'onboarding';
  static const String seekerLocation = 'seeker_location';
  static const String listerLocation = 'lister_location';
  static const String home = 'home';
  static const String seekerMap = 'seeker_map';
  static const String listerList = 'lister_list';
  static const String mapComparison = 'map_comparison';
  static const String flatRequirements = 'flat_requirements';
  static const String preferencesEdit = 'preferences_edit';
  static const String invites = 'invites';
  static const String findingMatches = 'finding_matches';
  /// Account bottom sheet (map / list)
  static const String accountModal = 'account_modal';
  /// Profile bottom sheet (map / list / invites)
  static const String profileModal = 'profile_modal';
  static const String unknown = 'unknown';
}
