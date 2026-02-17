/// Flat BLoC
/// 
/// Manages flat requirements (SEEKER) and flat details (LISTER) flows.
/// 
/// Key Features:
/// - Loads questions from API with existing data pre-populated
/// - Stores flat_id from GET response (for LISTER)
/// - Handles form field updates and question answers
/// - Manages photo uploads to S3 (LISTER only)
/// - Submits data to appropriate endpoint based on role

import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/flat_request_model.dart';
import '../repository/flat_repository.dart';
import 'flat_event.dart';
import 'flat_state.dart';

class FlatBloc extends Bloc<FlatEvent, FlatState> {
  final FlatRepository _repository;
  String? _flatId; // Stored from GET response (LISTER only)

  FlatBloc({required FlatRepository repository})
      : _repository = repository,
        super(FlatInitial()) {
    on<LoadFlatQuestions>(_onLoadQuestions);
    on<UpdateFormField>(_onUpdateFormField);
    on<UpdateQuestionAnswer>(_onUpdateQuestionAnswer);
    on<AddPhoto>(_onAddPhoto);
    on<RemovePhoto>(_onRemovePhoto);
    on<ClearUploadError>(_onClearUploadError);
    on<SubmitFlatData>(_onSubmit);
    on<ResetFlatState>(_onReset);
  }

  /// Load questions and existing data from API
  Future<void> _onLoadQuestions(
      LoadFlatQuestions event, Emitter<FlatState> emit) async {
    emit(FlatLoading());

    try {
      final response = await _repository.getQuestions(isLister: event.isLister);

      // Store flat_id from response (for LISTER)
      _flatId = response.flatId;

      // Initialize form fields from existing data
      final formFields = <String, dynamic>{};
      final existingFields = response.existingFormFields;

      // SEEKER fields
      if (existingFields.preferredFlatSize != null) {
        formFields['preferred_flat_size'] = existingFields.preferredFlatSize;
      }
      if (existingFields.maxRent != null) {
        formFields['max_rent'] = existingFields.maxRent;
      }
      if (existingFields.bedroomType != null) {
        formFields['bedroom_type'] = existingFields.bedroomType;
      }
      if (existingFields.maxDeposit != null) {
        formFields['max_deposit'] = existingFields.maxDeposit;
      }
      if (existingFields.washroomType != null) {
        formFields['washroom_type'] = existingFields.washroomType;
      }
      if (existingFields.preferredListingType != null) {
        formFields['preferred_listing_type'] = existingFields.preferredListingType;
      }
      if (existingFields.requiredFacilities != null) {
        formFields['required_facilities'] = existingFields.requiredFacilities;
      }

      // LISTER fields
      if (existingFields.flatSize != null) {
        formFields['flat_size'] = existingFields.flatSize;
      }
      if (existingFields.rent != null) {
        formFields['rent'] = existingFields.rent;
      }
      if (existingFields.securityDeposit != null) {
        formFields['security_deposit'] = existingFields.securityDeposit;
      }
      if (existingFields.listingType != null) {
        formFields['listing_type'] = existingFields.listingType;
      }
      if (existingFields.facilities != null) {
        formFields['facilities'] = existingFields.facilities;
      }
      if (existingFields.description != null) {
        formFields['description'] = existingFields.description;
      }

      // Location fields (from DRAFT flat)
      if (existingFields.locality != null) {
        formFields['locality'] = existingFields.locality;
      }
      if (existingFields.city != null) {
        formFields['city'] = existingFields.city;
      }
      if (existingFields.pincode != null) {
        formFields['pincode'] = existingFields.pincode;
      }

      // Initialize question answers from existing_answer
      final questionAnswers = <String, dynamic>{};
      for (final question in response.questions) {
        if (question.existingAnswer != null) {
          questionAnswers[question.id] = question.existingAnswer;
        }
      }

      // Initialize uploaded images from existing data
      final uploadedImages = existingFields.images ?? <String>[];

      emit(FlatLoaded(
        questions: response.questions,
        flatId: response.flatId,
        existingFormFields: response.existingFormFields,
        hasExistingData: response.hasExistingData,
        showImageUpload: response.showImageUpload,
        showDescription: response.showDescription,
        formFields: formFields,
        questionAnswers: questionAnswers,
        uploadedImages: List<String>.from(uploadedImages),
        uploadingImages: [],
      ));
    } catch (e) {
      emit(FlatError(message: e.toString()));
    }
  }

  /// Update a form field value
  void _onUpdateFormField(UpdateFormField event, Emitter<FlatState> emit) {
    final currentState = state;
    if (currentState is FlatLoaded) {
      final updatedFields = Map<String, dynamic>.from(currentState.formFields);
      updatedFields[event.fieldName] = event.value;
      emit(currentState.copyWith(formFields: updatedFields));
    }
  }

  /// Update answer for a question
  void _onUpdateQuestionAnswer(
      UpdateQuestionAnswer event, Emitter<FlatState> emit) {
    final currentState = state;
    if (currentState is FlatLoaded) {
      final updatedAnswers =
          Map<String, dynamic>.from(currentState.questionAnswers);
      updatedAnswers[event.questionId] = event.answer;
      emit(currentState.copyWith(questionAnswers: updatedAnswers));
    }
  }

  /// Add a photo (LISTER only). One presigned URL per image, then PUT to S3.
  Future<void> _onAddPhoto(AddPhoto event, Emitter<FlatState> emit) async {
    final currentState = state;
    if (currentState is! FlatLoaded) return;

    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${event.fileName}';
    final updatedUploading = List<String>.from(currentState.uploadingImages)
      ..add(uniqueName);
    emit(currentState.copyWith(uploadingImages: updatedUploading));

    String? fileUrl;
    try {
      fileUrl = await _repository.uploadPhoto(
        fileName: uniqueName,
        contentType: event.contentType,
        fileBytes: event.fileBytes,
      );
    } catch (_) {
      fileUrl = null;
    }

    final latestState = state;
    if (latestState is! FlatLoaded) return;

    final finalUploading = List<String>.from(latestState.uploadingImages)
      ..remove(uniqueName);

    if (fileUrl != null) {
      final finalUploaded = List<String>.from(latestState.uploadedImages)
        ..add(fileUrl);
      emit(latestState.copyWith(
        uploadedImages: finalUploaded,
        uploadingImages: finalUploading,
      ));
    } else {
      emit(latestState.copyWith(
        uploadingImages: finalUploading,
        uploadError: 'Failed to upload photo',
      ));
    }
  }

  void _onClearUploadError(ClearUploadError event, Emitter<FlatState> emit) {
    final currentState = state;
    if (currentState is FlatLoaded && currentState.uploadError != null) {
      emit(currentState.copyWith(clearUploadError: true));
    }
  }

  /// Remove a photo by index
  void _onRemovePhoto(RemovePhoto event, Emitter<FlatState> emit) {
    final currentState = state;
    if (currentState is FlatLoaded) {
      final updatedImages = List<String>.from(currentState.uploadedImages)
        ..removeAt(event.index);
      emit(currentState.copyWith(uploadedImages: updatedImages));
    }
  }

  /// Submit data to API based on role
  Future<void> _onSubmit(SubmitFlatData event, Emitter<FlatState> emit) async {
    final currentState = state;
    if (currentState is! FlatLoaded) return;

    emit(FlatSubmitting(previousState: currentState));

    try {
      if (event.userRole == 'SEEKER') {
        await _submitSeekerRequirements(currentState);
      } else {
        await _submitListerDetails(currentState);
      }

      emit(FlatSubmitSuccess(
        message: event.userRole == 'SEEKER'
            ? 'Requirements saved successfully'
            : 'Flat listing updated successfully',
        userRole: event.userRole,
      ));
    } catch (e) {
      emit(FlatError(
        message: e.toString(),
        previousState: currentState,
      ));
    }
  }

  /// Submit SEEKER requirements
  Future<void> _submitSeekerRequirements(FlatLoaded state) async {
    // Build question responses
    final responses = state.questionAnswers.entries.map((entry) {
      return QuestionResponse(
        questionId: entry.key,
        answer: entry.value,
      );
    }).toList();

    final request = FlatRequirementsRequest(
      responses: responses,
      preferredFlatSize: state.formFields['preferred_flat_size'] as String?,
      maxRent: state.formFields['max_rent'] as int?,
      bedroomType: state.formFields['bedroom_type'] as String?,
      maxDeposit: state.formFields['max_deposit'] as int?,
      washroomType: state.formFields['washroom_type'] as String?,
      preferredListingType:
          state.formFields['preferred_listing_type'] as String?,
      requiredFacilities:
          (state.formFields['required_facilities'] as List<dynamic>?)
              ?.cast<String>(),
    );

    await _repository.saveRequirements(request);
  }

  /// Submit LISTER flat details
  Future<void> _submitListerDetails(FlatLoaded state) async {
    // Build question responses
    final responses = state.questionAnswers.entries.map((entry) {
      return QuestionResponse(
        questionId: entry.key,
        answer: entry.value,
      );
    }).toList();

    final request = FlatDetailsRequest(
      flatId: _flatId, // From GET response
      flatSize: state.formFields['flat_size'] as String?,
      rent: state.formFields['rent'] as int?,
      securityDeposit: state.formFields['security_deposit'] as int?,
      bedroomType: state.formFields['bedroom_type'] as String?,
      washroomType: state.formFields['washroom_type'] as String?,
      listingType: state.formFields['listing_type'] as String?,
      facilities: (state.formFields['facilities'] as List<dynamic>?)?.cast<String>(),
      images: state.uploadedImages,
      description: state.formFields['description'] as String?,
      questionResponses: responses,
      isDraft: false, // Convert DRAFT to ACTIVE
      // Location fields from existing_form_fields (required by backend)
      location: state.existingFormFields.location,
      locality: state.existingFormFields.locality,
      city: state.existingFormFields.city,
      pincode: state.existingFormFields.pincode,
    );

    await _repository.saveFlatDetails(request);
  }

  /// Reset state
  void _onReset(ResetFlatState event, Emitter<FlatState> emit) {
    _flatId = null;
    emit(FlatInitial());
  }
}
