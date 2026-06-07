/// Button / action names for [AnalyticsEventNames.buttonClicked].
abstract final class AnalyticsButtonNames {
  AnalyticsButtonNames._();

  static const String loginGoogle = 'login_google';
  static const String loginLinkedIn = 'login_linkedin';
  static const String onboardingNext = 'onboarding_next';
  static const String onboardingSubmit = 'onboarding_submit';
  static const String savePreferences = 'save_preferences';
  static const String saveFlatDetails = 'save_flat_details';
  static const String openProfile = 'open_profile';
  static const String sendRequest = 'send_request';
  static const String acceptRequest = 'accept_request';
  static const String rejectRequest = 'reject_request';
  static const String completeMatch = 'complete_match';
  static const String logout = 'logout';

  /// Phone verification
  static const String phoneSendOtp = 'phone_send_otp';
  static const String phoneVerifyOtp = 'phone_verify_otp';
  static const String phoneResendOtp = 'phone_resend_otp';
  static const String phoneVerifyNotNow = 'phone_verify_not_now';

  /// Location flow
  static const String locationSeekerNext = 'location_seeker_next';
  static const String locationSeekerSkip = 'location_seeker_skip';
  static const String locationListerNext = 'location_lister_next';
  static const String locationListerSkip = 'location_lister_skip';

  /// Map / list primary CTAs
  static const String mapFlatmatePreference = 'map_flatmate_preference';
  static const String mapAddFlatDetails = 'map_add_flat_details';
  static const String bottomNavSearchResults = 'bottom_nav_search_results';
  static const String bottomNavChat = 'bottom_nav_chat';
  static const String bottomNavAccount = 'bottom_nav_account';

  /// Finding matches loading screen
  static const String findingMatchesSkip = 'finding_matches_skip';
  static const String findingMatchesContinueAnyway = 'finding_matches_continue_anyway';

  /// Invites list
  static const String invitesOpenProfile = 'invites_open_profile';
  static const String invitesRetry = 'invites_retry';

  /// Profile modal (other user)
  static const String profileModalSkip = 'profile_modal_skip';
  static const String profileModalRetry = 'profile_modal_retry';
  /// When API returns a label we cannot map to [sendRequest] / [acceptRequest] / etc.
  static const String profileRequestOther = 'profile_request_other';
}
