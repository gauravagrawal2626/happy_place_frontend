/// Flat Requirements Question Models
/// 
/// Data models for GET /api/questions/flat-listing response.
/// Supports both SEEKER (requirements) and LISTER (flat details) flows.
/// 
/// Key Features:
/// - Same Question structure as onboarding (reuses parsing logic)
/// - existing_answer field for pre-population
/// - flat_id returned by backend (for LISTER only)
/// - existing_form_fields for pre-populating form data

import '../../onboarding/model/question_model.dart';

/// Extended Question with existing answer support
class FlatQuestion {
  final String id;
  final String fieldName;
  final String? tertiaryText;
  final String primaryText;
  final String? secondaryText;
  final String type;
  final String questionSet;
  final String category;
  final List<QuestionOption> options;
  final bool isRequired;
  final int order;
  final String? helpText;
  final UiConfig uiConfig;
  final dynamic existingAnswer; // Pre-populated answer (String, int, or List<String>)

  FlatQuestion({
    required this.id,
    required this.fieldName,
    this.tertiaryText,
    required this.primaryText,
    this.secondaryText,
    required this.type,
    required this.questionSet,
    required this.category,
    required this.options,
    required this.isRequired,
    required this.order,
    this.helpText,
    required this.uiConfig,
    this.existingAnswer,
  });

  /// Check if this is a multi-select question
  bool get isMultiSelect => uiConfig.maxSelections != null && uiConfig.maxSelections! > 1;

  /// Get max selections (defaults to 1 for single select)
  int get maxSelections => uiConfig.maxSelections ?? 1;

  factory FlatQuestion.fromJson(Map<String, dynamic> json) {
    return FlatQuestion(
      id: json['_id'] as String,
      fieldName: json['field_name'] as String? ?? '',
      tertiaryText: json['tertiary_text'] as String?,
      primaryText: json['primary_text'] as String? ?? json['text'] as String? ?? '',
      secondaryText: json['secondary_text'] as String?,
      type: json['type'] as String,
      questionSet: json['question_set'] as String? ?? '',
      category: json['category'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => QuestionOption.fromJson(opt as Map<String, dynamic>))
              .toList() ??
          [],
      isRequired: json['is_required'] as bool? ?? true,
      order: json['order'] as int? ?? 1,
      helpText: json['help_text'] as String?,
      uiConfig: UiConfig.fromJson(json['ui_config'] as Map<String, dynamic>?),
      existingAnswer: json['existing_answer'], // Can be String, int, or List
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'field_name': fieldName,
      'tertiary_text': tertiaryText,
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'type': type,
      'question_set': questionSet,
      'category': category,
      'options': options.map((opt) => opt.toJson()).toList(),
      'is_required': isRequired,
      'order': order,
      'help_text': helpText,
      'ui_config': uiConfig.toJson(),
      if (existingAnswer != null) 'existing_answer': existingAnswer,
    };
  }
}

/// Existing form fields from API response
/// Different fields for SEEKER vs LISTER
class ExistingFormFields {
  // SEEKER fields (preferences)
  final String? preferredFlatSize;
  final int? maxRent;
  final String? bedroomType;
  final int? maxDeposit;
  final String? washroomType;
  final String? preferredListingType;
  final List<String>? requiredFacilities;

  // LISTER fields (actual values)
  final String? flatSize;
  final int? rent;
  final int? securityDeposit;
  final String? listingType;
  final List<String>? facilities;
  final List<String>? images;
  final String? description;
  final String? status;
  
  // Location fields (from DRAFT flat for LISTER)
  final Map<String, dynamic>? location; // GeoJSON Point
  final String? locality;
  final String? city;
  final String? pincode;

  ExistingFormFields({
    // SEEKER
    this.preferredFlatSize,
    this.maxRent,
    this.bedroomType,
    this.maxDeposit,
    this.washroomType,
    this.preferredListingType,
    this.requiredFacilities,
    // LISTER
    this.flatSize,
    this.rent,
    this.securityDeposit,
    this.listingType,
    this.facilities,
    this.images,
    this.description,
    this.status,
    // Location
    this.location,
    this.locality,
    this.city,
    this.pincode,
  });

  factory ExistingFormFields.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ExistingFormFields();
    
    return ExistingFormFields(
      // SEEKER
      preferredFlatSize: json['preferred_flat_size'] as String?,
      maxRent: json['max_rent'] as int?,
      bedroomType: json['bedroom_type'] as String?,
      maxDeposit: json['max_deposit'] as int?,
      washroomType: json['washroom_type'] as String?,
      preferredListingType: json['preferred_listing_type'] as String?,
      requiredFacilities: (json['required_facilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      // LISTER
      flatSize: json['flat_size'] as String?,
      rent: json['rent'] as int?,
      securityDeposit: json['security_deposit'] as int?,
      listingType: json['listing_type'] as String?,
      facilities: (json['facilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      status: json['status'] as String?,
      // Location
      location: json['location'] as Map<String, dynamic>?,
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (preferredFlatSize != null) 'preferred_flat_size': preferredFlatSize,
      if (maxRent != null) 'max_rent': maxRent,
      if (bedroomType != null) 'bedroom_type': bedroomType,
      if (maxDeposit != null) 'max_deposit': maxDeposit,
      if (washroomType != null) 'washroom_type': washroomType,
      if (preferredListingType != null) 'preferred_listing_type': preferredListingType,
      if (requiredFacilities != null) 'required_facilities': requiredFacilities,
      if (flatSize != null) 'flat_size': flatSize,
      if (rent != null) 'rent': rent,
      if (securityDeposit != null) 'security_deposit': securityDeposit,
      if (listingType != null) 'listing_type': listingType,
      if (facilities != null) 'facilities': facilities,
      if (images != null) 'images': images,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (locality != null) 'locality': locality,
      if (city != null) 'city': city,
      if (pincode != null) 'pincode': pincode,
    };
  }
}

/// Response from GET /api/questions/flat-listing
class FlatQuestionsResponse {
  final List<FlatQuestion> questions;
  final int totalQuestions;
  final String? flatId; // null for SEEKER, auto-found DRAFT for LISTER
  final ExistingFormFields existingFormFields;
  final bool hasExistingData;
  final bool showImageUpload; // Backend flag to show image upload widget
  final bool showDescription; // Backend flag to show description widget

  FlatQuestionsResponse({
    required this.questions,
    required this.totalQuestions,
    this.flatId,
    required this.existingFormFields,
    required this.hasExistingData,
    this.showImageUpload = false,
    this.showDescription = false,
  });

  factory FlatQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return FlatQuestionsResponse(
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => FlatQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      totalQuestions: json['total_questions'] as int? ?? 0,
      flatId: json['flat_id'] as String?,
      existingFormFields: ExistingFormFields.fromJson(
          json['existing_form_fields'] as Map<String, dynamic>?),
      hasExistingData: json['has_existing_data'] as bool? ?? false,
      showImageUpload: json['show_image_upload'] as bool? ?? false,
      showDescription: json['show_description'] as bool? ?? false,
    );
  }
}
