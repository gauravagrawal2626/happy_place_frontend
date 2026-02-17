/// App User Model
/// 
/// Represents the authenticated user in the app
class AppUser {
  final String userId;
  final String email;
  final String role; // "SEEKER" or "LISTER"
  final String fullName;
  final bool onboardingCompleted;

  AppUser({
    required this.userId,
    required this.email,
    required this.role,
    required this.fullName,
    required this.onboardingCompleted,
  });

  /// Create AppUser from AuthResponse
  factory AppUser.fromAuthResponse(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'role': role,
      'full_name': fullName,
      'onboarding_completed': onboardingCompleted,
    };
  }

  /// Copy with method for updates
  AppUser copyWith({
    String? userId,
    String? email,
    String? role,
    String? fullName,
    bool? onboardingCompleted,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

