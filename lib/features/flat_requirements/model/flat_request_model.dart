/// Flat Request Models
/// 
/// Request models for submitting flat requirements (SEEKER) and flat details (LISTER).
/// 
/// SEEKER: POST /api/users/flat-requirements
/// LISTER: POST /api/flats

/// Question response for both SEEKER and LISTER
class QuestionResponse {
  final String questionId;
  final dynamic answer; // String, int, or List<String>

  QuestionResponse({
    required this.questionId,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer': answer,
    };
  }
}

/// SEEKER request for POST /api/users/flat-requirements
class FlatRequirementsRequest {
  final List<QuestionResponse> responses;
  final String? preferredFlatSize;
  final int? maxRent;
  final String? bedroomType;
  final int? maxDeposit;
  final String? washroomType;
  final String? preferredListingType;
  final List<String>? requiredFacilities;

  FlatRequirementsRequest({
    required this.responses,
    this.preferredFlatSize,
    this.maxRent,
    this.bedroomType,
    this.maxDeposit,
    this.washroomType,
    this.preferredListingType,
    this.requiredFacilities,
  });

  Map<String, dynamic> toJson() {
    return {
      'responses': responses.map((r) => r.toJson()).toList(),
      if (preferredFlatSize != null) 'preferred_flat_size': preferredFlatSize,
      if (maxRent != null) 'max_rent': maxRent,
      if (bedroomType != null) 'bedroom_type': bedroomType,
      if (maxDeposit != null) 'max_deposit': maxDeposit,
      if (washroomType != null) 'washroom_type': washroomType,
      if (preferredListingType != null) 'preferred_listing_type': preferredListingType,
      if (requiredFacilities != null) 'required_facilities': requiredFacilities,
    };
  }
}

/// LISTER request for POST /api/flats
class FlatDetailsRequest {
  final String? flatId; // From GET response - updates existing DRAFT
  final String? flatSize;
  final int? rent;
  final int? securityDeposit;
  final String? bedroomType;
  final String? washroomType;
  final String? listingType;
  final List<String>? facilities;
  final List<String>? images;
  final String? description;
  final List<QuestionResponse>? questionResponses;
  final bool isDraft; // false to convert DRAFT to ACTIVE
  
  // Location fields (from existing_form_fields)
  final Map<String, dynamic>? location; // GeoJSON Point
  final String? locality;
  final String? city;
  final String? pincode;

  FlatDetailsRequest({
    this.flatId,
    this.flatSize,
    this.rent,
    this.securityDeposit,
    this.bedroomType,
    this.washroomType,
    this.listingType,
    this.facilities,
    this.images,
    this.description,
    this.questionResponses,
    this.isDraft = false,
    this.location,
    this.locality,
    this.city,
    this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      if (flatId != null) 'flat_id': flatId,
      if (flatSize != null) 'flat_size': flatSize,
      if (rent != null) 'rent': rent,
      if (securityDeposit != null) 'security_deposit': securityDeposit,
      if (bedroomType != null) 'bedroom_type': bedroomType,
      if (washroomType != null) 'washroom_type': washroomType,
      if (listingType != null) 'listing_type': listingType,
      if (facilities != null) 'facilities': facilities,
      if (images != null) 'images': images,
      if (description != null) 'description': description,
      if (questionResponses != null)
        'question_responses': questionResponses!.map((r) => r.toJson()).toList(),
      'is_draft': isDraft,
      // Location fields
      if (location != null) 'location': location,
      if (locality != null) 'locality': locality,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
    };
  }
}

/// Response from POST /api/users/flat-requirements
class FlatRequirementsResponse {
  final String message;
  final String userId;
  final int responsesSaved;

  FlatRequirementsResponse({
    required this.message,
    required this.userId,
    required this.responsesSaved,
  });

  factory FlatRequirementsResponse.fromJson(Map<String, dynamic> json) {
    return FlatRequirementsResponse(
      message: json['message'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      responsesSaved: json['responses_saved'] as int? ?? 0,
    );
  }
}

/// Response from POST /api/flats (update)
class FlatDetailsResponse {
  final String id;
  final String status;
  final String? flatSize;
  final int? rent;
  final List<String>? images;

  FlatDetailsResponse({
    required this.id,
    required this.status,
    this.flatSize,
    this.rent,
    this.images,
  });

  factory FlatDetailsResponse.fromJson(Map<String, dynamic> json) {
    return FlatDetailsResponse(
      id: json['_id'] as String? ?? json['flat_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      flatSize: json['flat_size'] as String?,
      rent: json['rent'] as int?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Response from POST /api/upload/presigned-url.
/// Use [uploadUrl] only for the one-time PUT to S3; store [fileUrl] in state and send to API for DB.
class PresignedUrlResponse {
  /// One-time presigned URL for PUT (do not store).
  final String uploadUrl;
  /// Permanent file URL to store in DB and use for display.
  final String fileUrl;

  PresignedUrlResponse({
    required this.uploadUrl,
    required this.fileUrl,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadUrl: (json['upload_url'] ?? json['uploadUrl']) as String,
      fileUrl: (json['file_url'] ?? json['fileUrl']) as String,
    );
  }
}
