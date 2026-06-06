abstract class LinkedInAuthEvent {}

class LinkedInLoginRequested extends LinkedInAuthEvent {}

class GoogleLoginRequested extends LinkedInAuthEvent {}

class DevLoginRequested extends LinkedInAuthEvent {}

class LinkedInLogoutRequested extends LinkedInAuthEvent {}

class LinkedInCheckAuthStatus extends LinkedInAuthEvent {} 