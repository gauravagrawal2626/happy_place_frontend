/// Auth API Response Model
/// 
/// Represents the response from POST /api/auth/login
/// 
/// Example response:
/// ```json
/// {
///   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///   "user_id": "693d68239a59ae7dc230b88c",
///   "email": "user@example.com",
///   "role": "SEEKER",
///   "full_name": "John Doe",
///   "onboarding_completed": false,
///   "phone_verified": false
/// }
/// ```
class AuthResponse {
  final String token;
  final String userId;
  final String email;
  final String role;
  final String fullName;
  final bool onboardingCompleted;
  final bool phoneVerified; // Phone verification status

  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
    required this.fullName,
    required this.onboardingCompleted,
    this.phoneVerified = false, // Default to false if not provided
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_id': userId,
      'email': email,
      'role': role,
      'full_name': fullName,
      'onboarding_completed': onboardingCompleted,
      'phone_verified': phoneVerified,
    };
  }
  
  /// Create a copy with updated phone verification status
  AuthResponse copyWith({
    String? token,
    String? userId,
    String? email,
    String? role,
    String? fullName,
    bool? onboardingCompleted,
    bool? phoneVerified,
  }) {
    return AuthResponse(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }
}
