/// Preferences BLoC
/// 
/// Manages preference editing flow after onboarding.
/// 
/// Features:
/// - Loads questions filtered by show_in_preferences: true
/// - Tracks answer changes
/// - Submits only changed answers
/// - Pre-populates with existing answers

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/preferences_repository.dart';
import 'preferences_event.dart';
import 'preferences_state.dart';

// Import PreferenceResponse for use in bloc
import '../repository/preferences_repository.dart' show PreferenceResponse;

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesRepository _repository;

  PreferencesBloc({required PreferencesRepository repository})
      : _repository = repository,
        super(PreferencesInitial()) {
    on<LoadPreferenceQuestions>(_onLoadQuestions);
    on<UpdatePreferenceAnswer>(_onUpdateAnswer);
    on<SubmitPreferences>(_onSubmit);
    on<ResetPreferences>(_onReset);
  }

  /// Load questions for preference editing
  Future<void> _onLoadQuestions(
    LoadPreferenceQuestions event,
    Emitter<PreferencesState> emit,
  ) async {
    emit(PreferencesLoading());

    try {
      final questions = await _repository.getPreferenceQuestions();

      // Initialize answers from existing_answer in questions
      final answers = <String, dynamic>{};
      final originalAnswers = <String, dynamic>{};

      for (final question in questions) {
        if (question.existingAnswer != null) {
          var answer = question.existingAnswer;
          
          // Handle sub-options: if existing_answer is a sub-option ID,
          // we need to also include the parent option for proper display
          if (answer is String) {
            // Check if this is a sub-option ID
            for (final option in question.options) {
              if (option.isParent && option.subOptions != null) {
                for (final subOption in option.subOptions!) {
                  if (subOption.id == answer) {
                    // This is a sub-option, add parent to answer if multi-select
                    if (question.isMultiSelect) {
                      answer = [option.id, answer];
                    } else {
                      // For single select, keep sub-option but we'll handle display in UI
                      answer = answer; // Keep as is, UI will handle parent selection
                    }
                    break;
                  }
                }
              }
            }
          } else if (answer is List) {
            // For multi-select, check if any sub-options are selected
            final updatedAnswer = List<String>.from(answer.cast<String>());
            for (final option in question.options) {
              if (option.isParent && option.subOptions != null) {
                bool hasSubOptionSelected = false;
                for (final subOption in option.subOptions!) {
                  if (updatedAnswer.contains(subOption.id)) {
                    hasSubOptionSelected = true;
                    // Ensure parent is also in the list
                    if (!updatedAnswer.contains(option.id)) {
                      updatedAnswer.add(option.id);
                    }
                    break;
                  }
                }
              }
            }
            answer = updatedAnswer;
          }
          
          answers[question.id] = answer;
          originalAnswers[question.id] = question.existingAnswer; // Keep original for comparison
        }
      }

      emit(PreferencesLoaded(
        questions: questions,
        answers: answers,
        originalAnswers: originalAnswers,
      ));
    } catch (e) {
      emit(PreferencesError(
        message: e.toString(),
      ));
    }
  }

  /// Update answer for a question
  void _onUpdateAnswer(
    UpdatePreferenceAnswer event,
    Emitter<PreferencesState> emit,
  ) {
    final currentState = state;
    if (currentState is PreferencesLoaded) {
      final updatedAnswers = Map<String, dynamic>.from(currentState.answers);
      updatedAnswers[event.questionId] = event.answer;

      emit(currentState.copyWith(answers: updatedAnswers));
    }
  }

  /// Submit updated preferences
  Future<void> _onSubmit(
    SubmitPreferences event,
    Emitter<PreferencesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PreferencesLoaded) return;

    // Only submit changed answers
    final changedAnswers = currentState.changedAnswers;
    if (changedAnswers.isEmpty) {
      emit(PreferencesError(
        message: 'No changes to save',
        previousState: currentState,
      ));
      return;
    }

    emit(PreferencesSubmitting(previousState: currentState));

    try {
      // Convert to API format
      // Note: answers map may contain parent IDs added for display purposes
      // We need to submit the actual selected values (sub-options if selected, not parents)
      final responses = changedAnswers.entries.map((entry) {
        final questionId = entry.key;
        var answer = entry.value;
        
        // Find the question
        final question = currentState.questions.firstWhere(
          (q) => q.id == questionId,
          orElse: () => throw Exception('Question not found: $questionId'),
        );
        
        // For multi-select: if answer contains both parent and sub-options,
        // remove parent IDs (keep only sub-options or non-parent options)
        if (question.isMultiSelect && answer is List) {
          final answerList = List<String>.from(answer.cast<String>());
          final filteredAnswer = <String>[];
          
          for (final ans in answerList) {
            bool shouldInclude = true;
            // Check if this is a parent that has selected sub-options
            for (final option in question.options) {
              if (option.id == ans && option.isParent && option.subOptions != null) {
                // Check if any sub-option of this parent is in the answer list
                for (final sub in option.subOptions!) {
                  if (answerList.contains(sub.id)) {
                    shouldInclude = false; // Don't include parent if sub-option is selected
                    break;
                  }
                }
                break;
              }
            }
            if (shouldInclude) {
              filteredAnswer.add(ans);
            }
          }
          answer = filteredAnswer;
        }
        // For single select: if answer is a parent ID but a sub-option was originally selected,
        // we need to preserve the sub-option. But since user interaction sets the actual value,
        // we can just submit what's in the answer (which should be the user's actual selection).
        
        return PreferenceResponse(
          questionId: questionId,
          answer: answer,
        );
      }).toList();

      final result = await _repository.updatePreferences(responses: responses);

      emit(PreferencesSubmitSuccess(
        message: result.message,
        responsesUpdated: result.responsesUpdated,
      ));
    } catch (e) {
      emit(PreferencesError(
        message: e.toString(),
        previousState: currentState,
      ));
    }
  }

  /// Reset state
  void _onReset(
    ResetPreferences event,
    Emitter<PreferencesState> emit,
  ) {
    emit(PreferencesInitial());
  }
}
