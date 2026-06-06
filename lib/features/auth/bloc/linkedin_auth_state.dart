import '../model/linkedin_user_model.dart';
import '../model/auth_response.dart';

abstract class LinkedInAuthState {}

class LinkedInAuthInitial extends LinkedInAuthState {}

class LinkedInAuthLoading extends LinkedInAuthState {}

class GoogleAuthLoading extends LinkedInAuthState {}

class DevAuthLoading extends LinkedInAuthState {}

class LinkedInAuthSuccess extends LinkedInAuthState {
  final AppLinkedInUser user;
  final AuthResponse authResponse; // JWT token + user info from backend
  
  LinkedInAuthSuccess({
    required this.user,
    required this.authResponse,
  });
}

class GoogleAuthSuccess extends LinkedInAuthState {
  final AuthResponse authResponse;

  GoogleAuthSuccess({required this.authResponse});
}

class LinkedInAuthFailure extends LinkedInAuthState {
  final String error;
  LinkedInAuthFailure({required this.error});
} 