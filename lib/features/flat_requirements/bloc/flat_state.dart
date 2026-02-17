/// Flat BLoC States
/// 
/// States for flat requirements (SEEKER) and flat details (LISTER) flows.

import '../model/flat_question_model.dart';

abstract class FlatState {}

/// Initial state before loading
class FlatInitial extends FlatState {}

/// Loading questions from API
class FlatLoading extends FlatState {}

/// Questions and data loaded successfully
class FlatLoaded extends FlatState {
  final List<FlatQuestion> questions;
  final String? flatId; // null for SEEKER, auto-found DRAFT for LISTER
  final ExistingFormFields existingFormFields;
  final bool hasExistingData;
  final bool showImageUpload; // Backend flag to show image upload widget
  final bool showDescription; // Backend flag to show description widget
  
  // Current form state
  final Map<String, dynamic> formFields;
  final Map<String, dynamic> questionAnswers;
  final List<String> uploadedImages; // S3 URLs
  final List<String> uploadingImages; // Local file names being uploaded
  final String? uploadError; // Transient error message (e.g. upload failed)

  FlatLoaded({
    required this.questions,
    this.flatId,
    required this.existingFormFields,
    required this.hasExistingData,
    this.showImageUpload = false,
    this.showDescription = false,
    required this.formFields,
    required this.questionAnswers,
    this.uploadedImages = const [],
    this.uploadingImages = const [],
    this.uploadError,
  });

  /// Create copy with updated fields.
  /// Set [clearUploadError] to true to clear the transient upload error.
  FlatLoaded copyWith({
    List<FlatQuestion>? questions,
    String? flatId,
    ExistingFormFields? existingFormFields,
    bool? hasExistingData,
    bool? showImageUpload,
    bool? showDescription,
    Map<String, dynamic>? formFields,
    Map<String, dynamic>? questionAnswers,
    List<String>? uploadedImages,
    List<String>? uploadingImages,
    String? uploadError,
    bool clearUploadError = false,
  }) {
    return FlatLoaded(
      questions: questions ?? this.questions,
      flatId: flatId ?? this.flatId,
      existingFormFields: existingFormFields ?? this.existingFormFields,
      hasExistingData: hasExistingData ?? this.hasExistingData,
      showImageUpload: showImageUpload ?? this.showImageUpload,
      showDescription: showDescription ?? this.showDescription,
      formFields: formFields ?? this.formFields,
      questionAnswers: questionAnswers ?? this.questionAnswers,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      uploadingImages: uploadingImages ?? this.uploadingImages,
      uploadError: clearUploadError ? null : (uploadError ?? this.uploadError),
    );
  }

  /// Check if a question has been answered
  bool isQuestionAnswered(String questionId) {
    final answer = questionAnswers[questionId];
    if (answer == null) return false;
    if (answer is List) return answer.isNotEmpty;
    if (answer is String) return answer.isNotEmpty;
    return true;
  }

  /// Get all required questions that are unanswered
  List<FlatQuestion> get unansweredRequiredQuestions {
    return questions
        .where((q) => q.isRequired && !isQuestionAnswered(q.id))
        .toList();
  }

  /// Check if form is valid (all required questions answered)
  bool get isFormValid => unansweredRequiredQuestions.isEmpty;
}

/// Photo is being uploaded
class FlatPhotoUploading extends FlatState {
  final FlatLoaded previousState;
  final String fileName;

  FlatPhotoUploading({
    required this.previousState,
    required this.fileName,
  });
}

/// Submitting data to API
class FlatSubmitting extends FlatState {
  final FlatLoaded previousState;

  FlatSubmitting({required this.previousState});
}

/// Data submitted successfully - triggers finding matches
class FlatSubmitSuccess extends FlatState {
  final String message;
  final String userRole;

  FlatSubmitSuccess({
    required this.message,
    required this.userRole,
  });
}

/// Finding matches after submit (like onboarding flow)
class FlatFindingMatches extends FlatState {
  final String userRole;

  FlatFindingMatches({required this.userRole});
}

/// Error state
class FlatError extends FlatState {
  final String message;
  final FlatLoaded? previousState; // Can retry from this state

  FlatError({
    required this.message,
    this.previousState,
  });
}
