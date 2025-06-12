abstract class LinkedInAuthEvent {}

class LinkedInLoginRequested extends LinkedInAuthEvent {}

class LinkedInLogoutRequested extends LinkedInAuthEvent {}

class LinkedInCheckAuthStatus extends LinkedInAuthEvent {} 