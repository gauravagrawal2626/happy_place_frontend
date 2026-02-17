import '../model/question_model.dart';

/// Onboarding States - Enhanced with role tracking and text variations

abstract class OnboardingState {}

/// Initial state
class OnboardingInitial extends OnboardingState {}

/// Loading questions
class OnboardingLoading extends OnboardingState {}

/// Questions loaded, ready to answer
class OnboardingLoaded extends OnboardingState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final Map<String, dynamic> answers;         // questionId -> answer
  final Map<String, dynamic> answersByField;  // fieldName -> answer (for text_variations)
  final String userRole;                       // LISTER or SEEKER
  final String? userName;                      // For {name} placeholder

  OnboardingLoaded({
    required this.questions,
    required this.currentQuestionIndex,
    required this.answers,
    Map<String, dynamic>? answersByField,
    this.userRole = 'SEEKER',
    this.userName,
  }) : answersByField = answersByField ?? {};

  OnboardingLoaded copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    Map<String, dynamic>? answers,
    Map<String, dynamic>? answersByField,
    String? userRole,
    String? userName,
  }) {
    return OnboardingLoaded(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      answersByField: answersByField ?? this.answersByField,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
    );
  }

  /// Get the raw question (without text_variations applied)
  Question get rawCurrentQuestion => questions[currentQuestionIndex];

  /// Get the current question with text_variations and {name} applied
  Question get currentQuestion {
    final question = rawCurrentQuestion;
    return _applyTextVariations(question);
  }

  /// Apply text variations based on previous answers or role
  Question _applyTextVariations(Question question) {
    final variations = question.textVariations;
    if (variations == null || variations.isEmpty) {
      return _applyNamePlaceholder(question);
    }

    // Determine which key to use for variations
    String? key;
    if (variations.basedOn == 'role') {
      key = userRole;
    } else {
      // Look up in answersByField (e.g., GENDER answer)
      key = answersByField[variations.basedOn]?.toString();
    }

    if (key == null) {
      return _applyNamePlaceholder(question);
    }

    // Get the variation overrides
    final overrides = variations.getVariation(key);
    if (overrides == null) {
      return _applyNamePlaceholder(question);
    }

    // Apply overrides
    final modifiedQuestion = question.copyWithTextOverrides(
      tertiaryText: overrides['tertiary_text'],
      primaryText: overrides['primary_text'],
      secondaryText: overrides['secondary_text'],
    );

    return _applyNamePlaceholder(modifiedQuestion);
  }

  /// Replace {name} placeholder with actual user name
  Question _applyNamePlaceholder(Question question) {
    if (userName == null || userName!.isEmpty) {
      // Remove {name} placeholder if no name available
      return question.copyWithTextOverrides(
        tertiaryText: question.tertiaryText?.replaceAll('{name}', 'there'),
      );
    }

    return question.copyWithTextOverrides(
      tertiaryText: question.tertiaryText?.replaceAll('{name}', userName!),
    );
  }

  bool get isFirstQuestion => currentQuestionIndex == 0;

  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  dynamic getCurrentAnswer() => answers[rawCurrentQuestion.id];

  /// Get answer by field name (for text_variations lookup)
  dynamic getAnswerByField(String fieldName) => answersByField[fieldName];
}

/// Submitting answers
class OnboardingSubmitting extends OnboardingState {}

/// Onboarding completed successfully
class OnboardingCompleted extends OnboardingState {
  final String userRole; // LISTER or SEEKER

  OnboardingCompleted({required this.userRole});
}

/// Error occurred
class OnboardingError extends OnboardingState {
  final String message;

  OnboardingError(this.message);
}
