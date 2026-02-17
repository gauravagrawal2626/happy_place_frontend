/// Public Profile Model
///
/// Response from GET /api/users/{user_id}/public-profile
///
/// match_score: Returned by the API every time; available as p.matchScore for display when needed.
///
/// request_status shape (when include_request_status=true):
///   "request_status": {
///     "buttons": [
///       { "text": "Send Request" | "PENDING" | "Accept" | "Reject" | ..., "action": "/api/requests" | null, "enabled": true | false }
///     ]
///   }
/// Example: PENDING state = { "text": "PENDING", "action": null, "enabled": false } → one disabled button showing "PENDING".

/// Button from request_status.buttons (label, action path, enabled).
class RequestStatusButton {
  final String text;
  final String? action; // Endpoint suffix e.g. /api/requests or /api/requests/{id}/accept
  final bool enabled;

  const RequestStatusButton({
    required this.text,
    this.action,
    required this.enabled,
  });

  factory RequestStatusButton.fromJson(Map<String, dynamic> json) {
    return RequestStatusButton(
      text: json['text'] as String? ?? '',
      action: json['action'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  bool get isClickable => enabled && action != null && action!.trim().isNotEmpty;
}

class LifestyleTag {
  final String label;
  final String type;

  const LifestyleTag({required this.label, required this.type});

  factory LifestyleTag.fromJson(Map<String, dynamic> json) {
    return LifestyleTag(
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class PublicProfile {
  final String userId;
  final String fullName;
  final int? age;
  final String? gender;
  final String? profilePicture;
  final String? bio;
  final String? location;
  final List<LifestyleTag> lifestyleTags;
  final List<String> topPriorities;
  final String? weekendActivities;
  final double? matchScore;
  final Map<String, dynamic>? requestStatus;

  PublicProfile({
    required this.userId,
    required this.fullName,
    this.age,
    this.gender,
    this.profilePicture,
    this.bio,
    this.location,
    this.lifestyleTags = const [],
    this.topPriorities = const [],
    this.weekendActivities,
    this.matchScore,
    this.requestStatus,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final tags = json['lifestyle_tags'];
    final priorities = json['top_priorities'];
    return PublicProfile(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      lifestyleTags: tags is List
          ? (tags as List).map((e) => LifestyleTag.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      topPriorities: priorities is List
          ? (priorities as List).map((e) => e.toString()).toList()
          : [],
      weekendActivities: json['weekend_activities'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble(),
      requestStatus: _parseRequestStatus(json['request_status'] ?? json['requestStatus']),
    );
  }

  /// Buttons from request_status.buttons; use for rendering action buttons (Send Request, Accept, Reject, etc.).
  List<RequestStatusButton> get requestStatusButtons {
    final rs = requestStatus;
    if (rs == null) return [];
    final raw = rs['buttons'];
    if (raw is! List || raw.isEmpty) return [];
    return raw
        .map((e) => e is Map ? RequestStatusButton.fromJson(Map<String, dynamic>.from(e as Map)) : null)
        .whereType<RequestStatusButton>()
        .toList();
  }

  /// Backend may send request_status as object { "buttons": [...] } or legacy { "status": "PENDING" }.
  static Map<String, dynamic>? _parseRequestStatus(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value as Map);
    if (value is String && value.trim().isNotEmpty) {
      return {'status': value.trim()};
    }
    return null;
  }
}
