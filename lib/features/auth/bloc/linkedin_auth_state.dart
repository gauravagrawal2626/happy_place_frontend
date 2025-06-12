import '../model/linkedin_user_model.dart';

abstract class LinkedInAuthState {}

class LinkedInAuthInitial extends LinkedInAuthState {}

class LinkedInAuthLoading extends LinkedInAuthState {}

class LinkedInAuthSuccess extends LinkedInAuthState {
  final AppLinkedInUser user;
  LinkedInAuthSuccess({required this.user});
}

class LinkedInAuthFailure extends LinkedInAuthState {
  final String error;
  LinkedInAuthFailure({required this.error});
} 