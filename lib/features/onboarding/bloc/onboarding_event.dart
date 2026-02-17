/// Onboarding Events - Phase 2

abstract class OnboardingEvent {}

/// Load questions (uses mock data in Phase 2)
class LoadQuestions extends OnboardingEvent {}

/// Answer a question
class AnswerQuestion extends OnboardingEvent {
  final String questionId;
  final dynamic answer; // String or List<String>

  AnswerQuestion({
    required this.questionId,
    required this.answer,
  });
}

/// Navigate to next question
class NextQuestion extends OnboardingEvent {}

/// Navigate to previous question
class PreviousQuestion extends OnboardingEvent {}

/// Submit all answers (placeholder for Phase 2)
class SubmitOnboarding extends OnboardingEvent {}

