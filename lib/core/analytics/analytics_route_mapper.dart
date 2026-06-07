import 'analytics_screen_names.dart';

/// Maps GoRouter [RouteSettings.name] (full path) to funnel [screen_name] values.
String mapRouteNameToScreenName(String? routeName) {
  if (routeName == null || routeName.isEmpty) {
    return AnalyticsScreenNames.unknown;
  }
  final path = routeName.split('?').first;
  if (path == '/splash') return AnalyticsScreenNames.splash;
  if (path == '/login') return AnalyticsScreenNames.login;
  if (path == '/phone-input') return AnalyticsScreenNames.phoneInput;
  if (path.startsWith('/phone-verify')) return AnalyticsScreenNames.phoneVerify;
  if (path == '/onboarding') return AnalyticsScreenNames.onboarding;
  if (path == '/location/seeker') return AnalyticsScreenNames.seekerLocation;
  if (path == '/location/lister') return AnalyticsScreenNames.listerLocation;
  if (path == '/home') return AnalyticsScreenNames.home;
  if (path == '/map/seeker') return AnalyticsScreenNames.seekerMap;
  if (path == '/list/lister') return AnalyticsScreenNames.listerList;
  if (path == '/matching') return AnalyticsScreenNames.mapComparison;
  if (path == '/flat-requirements') return AnalyticsScreenNames.flatRequirements;
  if (path == '/preferences/edit') return AnalyticsScreenNames.preferencesEdit;
  if (path == '/account/invites') return AnalyticsScreenNames.invites;
  if (path == '/chats') return AnalyticsScreenNames.conversationsList;
  if (path.startsWith('/chat/')) return AnalyticsScreenNames.chatThread;
  if (path.startsWith('/finding-matches')) {
    return AnalyticsScreenNames.findingMatches;
  }
  return AnalyticsScreenNames.unknown;
}
