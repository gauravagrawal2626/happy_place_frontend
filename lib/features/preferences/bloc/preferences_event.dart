/// Preferences Editing Events
/// 
/// Events for editing flatmate preferences after onboarding

abstract class PreferencesEvent {}

/// Load questions for preference editing
class LoadPreferenceQuestions extends PreferencesEvent {}

/// Update answer for a question
class UpdatePreferenceAnswer extends PreferencesEvent {
  final String questionId;
  final dynamic answer; // Can be String, int, List<String>

  UpdatePreferenceAnswer({
    required this.questionId,
    required this.answer,
  });
}

/// Submit updated preferences
class SubmitPreferences extends PreferencesEvent {}

/// Reset preferences state
class ResetPreferences extends PreferencesEvent {}
