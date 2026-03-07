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

class ResolvedQuestionResponse {
  final String question;
  final String answer;

  const ResolvedQuestionResponse({required this.question, required this.answer});

  factory ResolvedQuestionResponse.fromJson(Map<String, dynamic> json) {
    return ResolvedQuestionResponse(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class PreferredLocationInfo {
  final String name;
  final String city;
  final double? radiusKm;

  const PreferredLocationInfo({required this.name, required this.city, this.radiusKm});

  factory PreferredLocationInfo.fromJson(Map<String, dynamic> json) {
    return PreferredLocationInfo(
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      radiusKm: (json['radius_km'] as num?)?.toDouble(),
    );
  }
}

class FlatInfo {
  final String role; // "lister" or "seeker"
  final List<ResolvedQuestionResponse> questionResponses;
  // Lister-only fields
  final String? flatId;
  final String? title;
  final String? type;
  final int? rent;
  final int? securityDeposit;
  final int? bedrooms;
  final int? bathrooms;
  final int? areaSqft;
  final List<String> images;
  final String? locality;
  final String? city;
  final String? formattedAddress;
  final Map<String, dynamic> amenities;
  final Map<String, dynamic> rules;
  // Seeker-only fields
  final String? preferredListingType;
  final String? preferredFlatSize;
  final int? maxRent;
  final List<String> requiredFacilities;
  final List<PreferredLocationInfo> preferredLocations;

  FlatInfo({
    required this.role,
    this.questionResponses = const [],
    this.flatId,
    this.title,
    this.type,
    this.rent,
    this.securityDeposit,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.images = const [],
    this.locality,
    this.city,
    this.formattedAddress,
    this.amenities = const {},
    this.rules = const {},
    this.preferredListingType,
    this.preferredFlatSize,
    this.maxRent,
    this.requiredFacilities = const [],
    this.preferredLocations = const [],
  });

  bool get isLister => role == 'lister';
  bool get isSeeker => role == 'seeker';

  factory FlatInfo.fromJson(Map<String, dynamic> json) {
    return FlatInfo(
      role: json['role'] as String? ?? '',
      questionResponses: (json['question_responses'] as List?)
              ?.map((e) => ResolvedQuestionResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      flatId: json['flat_id'] as String?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      rent: json['rent'] as int?,
      securityDeposit: json['security_deposit'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      areaSqft: json['area_sqft'] as int?,
      images: (json['images'] as List?)?.cast<String>() ?? [],
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      formattedAddress: json['formatted_address'] as String?,
      amenities: json['amenities'] is Map
          ? Map<String, dynamic>.from(json['amenities'] as Map)
          : {},
      rules: json['rules'] is Map
          ? Map<String, dynamic>.from(json['rules'] as Map)
          : {},
      preferredListingType: json['preferred_listing_type'] as String?,
      preferredFlatSize: json['preferred_flat_size'] as String?,
      maxRent: json['max_rent'] as int?,
      requiredFacilities: (json['required_facilities'] as List?)?.cast<String>() ?? [],
      preferredLocations: (json['preferred_locations'] as List?)
              ?.map((e) => PreferredLocationInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
  final FlatInfo? flatInfo;

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
    this.flatInfo,
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
      flatInfo: json['flat_info'] != null
          ? FlatInfo.fromJson(Map<String, dynamic>.from(json['flat_info'] as Map))
          : null,
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
