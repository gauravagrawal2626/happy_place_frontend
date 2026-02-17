import 'package:linkedin_login/linkedin_login.dart';

class AppLinkedInUser {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicture;
  final String? sub;
  final LinkedInTokenObject? accessToken;

  AppLinkedInUser({
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicture,
    this.sub,
    this.accessToken,
  });

  String? get accessTokenString => accessToken?.accessToken;

  factory AppLinkedInUser.fromLinkedInUser(UserSucceededAction userSucceededAction) {
    final user = userSucceededAction.user;
    
    return AppLinkedInUser(
      firstName: user.givenName,
      lastName: user.familyName,
      email: user.email,
      profilePicture: user.picture,
      sub: user.sub,
      accessToken: user.token,
    );
  }
} 