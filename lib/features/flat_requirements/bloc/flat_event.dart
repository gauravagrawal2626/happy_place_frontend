/// Flat BLoC Events
/// 
/// Events for flat requirements (SEEKER) and flat details (LISTER) flows.

import 'dart:typed_data';

abstract class FlatEvent {}

/// Load questions and existing data
class LoadFlatQuestions extends FlatEvent {
  /// Whether to load LISTER (flat details) or SEEKER (preferences) questions
  final bool isLister;

  LoadFlatQuestions({required this.isLister});
}

/// Update a form field value
class UpdateFormField extends FlatEvent {
  final String fieldName;
  final dynamic value;

  UpdateFormField({required this.fieldName, required this.value});
}

/// Update answer for a question
class UpdateQuestionAnswer extends FlatEvent {
  final String questionId;
  final dynamic answer;

  UpdateQuestionAnswer({required this.questionId, required this.answer});
}

/// Add a photo (LISTER only)
class AddPhoto extends FlatEvent {
  final String fileName;
  final String contentType;
  final Uint8List fileBytes;

  AddPhoto({
    required this.fileName,
    required this.contentType,
    required this.fileBytes,
  });
}

/// Remove a photo by index (LISTER only)
class RemovePhoto extends FlatEvent {
  final int index;

  RemovePhoto({required this.index});
}

/// Submit flat requirements (SEEKER) or flat details (LISTER)
class SubmitFlatData extends FlatEvent {
  final String userRole; // 'SEEKER' or 'LISTER'

  SubmitFlatData({required this.userRole});
}

/// Clear transient upload error message
class ClearUploadError extends FlatEvent {}

/// Reset state (when navigating away)
class ResetFlatState extends FlatEvent {}
