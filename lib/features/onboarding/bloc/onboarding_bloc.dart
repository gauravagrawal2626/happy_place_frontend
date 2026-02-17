import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../model/question_model.dart';
import '../repository/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Onboarding BLoC - Enhanced
/// 
/// Manages onboarding flow with:
/// - Real API integration
/// - Text variations based on previous answers
/// - Role tracking (LISTER/SEEKER)
/// - {name} placeholder interpolation
/// - Sub-options support
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _repository;
  final String? userName; // For personalized greetings

  OnboardingBloc({
    required ApiClient apiClient,
    this.userName,
  })  : _repository = OnboardingRepository(apiClient: apiClient),
        super(OnboardingInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<AnswerQuestion>(_onAnswerQuestion);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<SubmitOnboarding>(_onSubmitOnboarding);
    _log('OnboardingBloc initialized with userName: $userName');
  }

  void _log(String message) {
    debugPrint('[OnboardingBloc] $message');
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<OnboardingState> emit,
  ) async {
    _log('Loading questions from API...');
    emit(OnboardingLoading());

    try {
      final result = await _repository.getQuestions();
      
      if (result.isSuccess && result.data != null) {
        final questions = result.data!.questions;
        final initialRole = result.data!.userRole;
        
        // Sort by order
        questions.sort((a, b) => a.order.compareTo(b.order));
        
        _log('✅ Loaded ${questions.length} questions');
        _log('   Initial role: $initialRole');

        emit(OnboardingLoaded(
          questions: questions,
          currentQuestionIndex: 0,
          answers: {},
          answersByField: {},
          userRole: initialRole,
          userName: userName,
        ));
      } else {
        _log('❌ Failed to load: ${result.errorMessage}');
        emit(OnboardingError(result.errorMessage ?? 'Failed to load questions'));
      }
    } catch (e) {
      _log('❌ Exception: $e');
      emit(OnboardingError('Failed to load questions: $e'));
    }
  }

  void _onAnswerQuestion(
    AnswerQuestion event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      
      // Update answers by question ID
      final updatedAnswers = Map<String, dynamic>.from(currentState.answers);
      updatedAnswers[event.questionId] = event.answer;

      // Find the question to get its field name
      final question = currentState.questions.firstWhere(
        (q) => q.id == event.questionId,
        orElse: () => currentState.rawCurrentQuestion,
      );

      // Update answers by field name (for text_variations lookup)
      final updatedAnswersByField = Map<String, dynamic>.from(currentState.answersByField);
      updatedAnswersByField[question.fieldName] = event.answer;

      _log('Answer saved: ${question.fieldName} = ${event.answer}');

      // Check if this answer updates the user role
      String newRole = currentState.userRole;
      if (question.updatesRole && question.matchingConfig?.roleMapping != null) {
        final roleMapping = question.matchingConfig!.roleMapping!;
        final answerStr = event.answer.toString();
        
        if (roleMapping.containsKey(answerStr)) {
          newRole = roleMapping[answerStr]!;
          _log('Role updated to: $newRole');
        } else {
          // Fallback: If answer not in mapping, infer role from option ID
          if (answerStr.contains('search') || answerStr.contains('no_flat')) {
            newRole = 'SEEKER';
          } else if (answerStr.contains('flatmate') || answerStr.contains('replacement') || answerStr.contains('have_flat')) {
            newRole = 'LISTER';
          }
        }
      }

      emit(currentState.copyWith(
        answers: updatedAnswers,
        answersByField: updatedAnswersByField,
        userRole: newRole,
      ));
    }
  }

  void _onNextQuestion(
    NextQuestion event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      
      // Validate current answer before proceeding
      final currentQuestion = currentState.rawCurrentQuestion;
      final currentAnswer = currentState.getCurrentAnswer();
      
      if (currentQuestion.isRequired && _isAnswerEmpty(currentAnswer)) {
        emit(OnboardingError('Please answer this question before continuing'));
        emit(currentState);
        return;
      }

      // For questions with sub-options, ensure a sub-option is selected
      if (currentQuestion.hasSubOptions) {
        if (!_isValidSubOptionAnswer(currentQuestion, currentAnswer)) {
          emit(OnboardingError('Please select an option to continue'));
          emit(currentState);
          return;
        }
      }

      if (!currentState.isLastQuestion) {
        _log('Moving to question ${currentState.currentQuestionIndex + 2}');
        emit(currentState.copyWith(
          currentQuestionIndex: currentState.currentQuestionIndex + 1,
        ));
      }
    }
  }

  /// Validate that a sub-option is selected (not just parent)
  bool _isValidSubOptionAnswer(Question question, dynamic answer) {
    if (answer == null) return false;
    
    final answerStr = answer.toString();
    
    // Check if answer is a sub-option ID
    for (final option in question.options) {
      if (option.isParent && option.subOptions != null) {
        for (final subOption in option.subOptions!) {
          if (subOption.id == answerStr) {
            return true;
          }
        }
      }
      // Also allow non-parent options
      if (!option.isParent && option.id == answerStr) {
        return true;
      }
    }
    
    return false;
  }

  void _onPreviousQuestion(
    PreviousQuestion event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      
      if (!currentState.isFirstQuestion) {
        _log('Going back to question ${currentState.currentQuestionIndex}');
        emit(currentState.copyWith(
          currentQuestionIndex: currentState.currentQuestionIndex - 1,
        ));
      }
    }
  }

  Future<void> _onSubmitOnboarding(
    SubmitOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      
      // Validate all required questions
      for (final question in currentState.questions) {
        if (question.isRequired) {
          final answer = currentState.answers[question.id];
          if (_isAnswerEmpty(answer)) {
            emit(OnboardingError('Please answer all required questions'));
            emit(currentState);
            return;
          }
        }
      }

      _log('Submitting onboarding answers...');
      _log('User role: ${currentState.userRole}');
      emit(OnboardingSubmitting());

      try {
        // Convert answers to OnboardingAnswer objects
        final answers = currentState.questions
            .where((q) => currentState.answers.containsKey(q.id))
            .map((q) {
          return OnboardingAnswer(
            questionId: q.id,
            answer: currentState.answers[q.id],
          );
        }).toList();

        final result = await _repository.submitAnswers(answers);

        if (result.isSuccess) {
          _log('Onboarding submitted successfully');
          emit(OnboardingCompleted(userRole: currentState.userRole));
        } else {
          _log('❌ Submit failed: ${result.errorMessage}');
          emit(OnboardingError(result.errorMessage ?? 'Failed to submit'));
          emit(currentState);
        }
      } catch (e) {
        _log('❌ Exception during submit: $e');
        emit(OnboardingError('Failed to submit: $e'));
        emit(currentState);
      }
    }
  }

  bool _isAnswerEmpty(dynamic answer) {
    if (answer == null) return true;
    if (answer is String) return answer.trim().isEmpty;
    if (answer is List) return answer.isEmpty;
    if (answer is int) return false; // Numbers are valid
    return false;
  }

  /// Get user name for personalized greetings
  String? get currentUserName => userName;
}
