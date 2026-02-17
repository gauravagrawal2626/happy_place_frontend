/// Preferences Editing States
/// 
/// States for preference editing flow

import '../../onboarding/model/question_model.dart';

abstract class PreferencesState {}

/// Initial state
class PreferencesInitial extends PreferencesState {}

/// Loading questions
class PreferencesLoading extends PreferencesState {}

/// Questions loaded, ready to edit
class PreferencesLoaded extends PreferencesState {
  final List<Question> questions; // Filtered to show_in_preferences: true
  final Map<String, dynamic> answers; // questionId -> answer (current form state)
  final Map<String, dynamic> originalAnswers; // Original answers from API

  PreferencesLoaded({
    required this.questions,
    required this.answers,
    required this.originalAnswers,
  });

  /// Check if any answers have changed
  bool get hasChanges {
    if (answers.length != originalAnswers.length) return true;
    for (final entry in answers.entries) {
      if (originalAnswers[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }

  /// Get changed answers only
  Map<String, dynamic> get changedAnswers {
    final changed = <String, dynamic>{};
    for (final entry in answers.entries) {
      if (originalAnswers[entry.key] != entry.value) {
        changed[entry.key] = entry.value;
      }
    }
    return changed;
  }

  PreferencesLoaded copyWith({
    List<Question>? questions,
    Map<String, dynamic>? answers,
    Map<String, dynamic>? originalAnswers,
  }) {
    return PreferencesLoaded(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      originalAnswers: originalAnswers ?? this.originalAnswers,
    );
  }
}

/// Submitting preferences
class PreferencesSubmitting extends PreferencesState {
  final PreferencesLoaded previousState;

  PreferencesSubmitting({required this.previousState});
}

/// Preferences submitted successfully
class PreferencesSubmitSuccess extends PreferencesState {
  final String message;
  final int responsesUpdated;

  PreferencesSubmitSuccess({
    required this.message,
    required this.responsesUpdated,
  });
}

/// Error state
class PreferencesError extends PreferencesState {
  final String message;
  final PreferencesLoaded? previousState;

  PreferencesError({
    required this.message,
    this.previousState,
  });
}
