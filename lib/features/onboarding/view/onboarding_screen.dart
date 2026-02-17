import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/progress_indicator_widget.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/bloc/app_state.dart';
import '../../../core/network/api_client.dart';
import '../../auth/bloc/linkedin_auth_bloc.dart';
import '../../auth/bloc/linkedin_auth_state.dart';
import '../../auth/model/auth_response.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/text_input_question.dart';
import '../widgets/text_mcq_question.dart';
import '../widgets/image_mcq_question.dart';
import '../widgets/slider_question.dart';

/// Onboarding Screen - Phase 2
/// 
/// Dynamic onboarding flow fetched from API:
/// - Progress bar at bottom
/// - Next/Previous navigation
/// - Supports TEXT_MCQ, IMAGE_MCQ, SLIDER, TEXT_INPUT
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        // Wait for app to finish initializing (don't show onboarding during AppLoading)
        if (appState is AppLoading) {
          return AppScaffold(
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.textDark,
              ),
            ),
          );
        }
        
        // Only proceed if user is authenticated
        if (appState is! AppAuthenticated) {
          // If not authenticated, router will redirect to login
          // Show loading while waiting for redirect
          return AppScaffold(
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.textDark,
              ),
            ),
          );
        }
        
        // App is authenticated - proceed with onboarding
        final authResponse = appState.authResponse;
        final userName = authResponse.fullName.split(' ').first;
        
        // Use API client from AuthRepository (already has token set from restoreSession)
        final appBloc = context.read<AppBloc>();
        final authRepository = appBloc.authRepository;
        final apiClient = authRepository.apiClient;

        return BlocProvider(
          create: (context) => OnboardingBloc(
            apiClient: apiClient,
            userName: userName,
          )..add(LoadQuestions()),
          child: _OnboardingContent(userName: userName),
        );
      },
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final String? userName;

  const _OnboardingContent({this.userName});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            // Get user role from OnboardingCompleted state
            final userRole = state.userRole;
            
            // DON'T update AppBloc yet - wait until location is submitted
            // This prevents router from redirecting to /home
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Onboarding completed!'),
                backgroundColor: AppColors.success,
              ),
            );
            
            // Navigate to location screen based on role
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final targetRoute = userRole == 'LISTER' ? '/location/lister' : '/location/seeker';
              context.go(targetRoute);
            });
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          // Initial state or loading - show loading spinner
          if (state is OnboardingInitial || state is OnboardingLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textDark,
              ),
            );
          }

          if (state is OnboardingLoaded) {
            return _buildQuestionView(context, state);
          }

          if (state is OnboardingSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.textDark),
                  SizedBox(height: 16),
                  Text(
                    'Submitting...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          // Onboarding completed - show loading while navigating
          if (state is OnboardingCompleted) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.textDark),
                  SizedBox(height: 16),
                  Text(
                    'Redirecting...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state - retry button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    context.read<OnboardingBloc>().add(LoadQuestions());
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionView(BuildContext context, OnboardingLoaded state) {
    final question = state.currentQuestion;
    final currentAnswer = state.getCurrentAnswer();
    final progress = (state.currentQuestionIndex + 1) / state.questions.length;

    return SafeArea(
      child: Column(
        children: [
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildQuestionByType(context, state, currentAnswer),
            ),
          ),

          // Bottom section: Navigation + Progress bar (Figma order)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              children: [
                // Navigation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (hidden on first question)
                    if (!state.isFirstQuestion)
                      TextButton(
                        onPressed: () {
                          context.read<OnboardingBloc>().add(PreviousQuestion());
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, size: 18, color: AppColors.textDark),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    
                    // Next/Submit button
                    TextButton(
                      onPressed: _isAnswerValid(question, currentAnswer)
                          ? () {
                              if (state.isLastQuestion) {
                                context.read<OnboardingBloc>().add(SubmitOnboarding());
                              } else {
                                context.read<OnboardingBloc>().add(NextQuestion());
                              }
                            }
                          : null,
                      child: Row(
                        children: [
                Text(
                            state.isLastQuestion ? 'Submit' : 'Next',
                  style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _isAnswerValid(question, currentAnswer)
                                  ? AppColors.textDark
                                  : AppColors.textDark.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: _isAnswerValid(question, currentAnswer)
                                ? AppColors.textDark
                                : AppColors.textDark.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar using shared widget
                ProgressIndicatorWidget(progress: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionByType(
    BuildContext context,
    OnboardingLoaded state,
    dynamic currentAnswer,
  ) {
    final question = state.currentQuestion;

    switch (question.type) {
      case 'TEXT_INPUT':
        return TextInputQuestion(
          question: question,
          currentAnswer: currentAnswer as String?,
          userName: userName,
          onAnswerChanged: (answer) {
            context.read<OnboardingBloc>().add(
                  AnswerQuestion(questionId: question.id, answer: answer),
                );
          },
        );

      case 'TEXT_MCQ':
        return TextMcqQuestion(
          question: question,
          currentAnswer: currentAnswer,
          userName: userName,
          onAnswerChanged: (answer) {
            context.read<OnboardingBloc>().add(
                  AnswerQuestion(questionId: question.id, answer: answer),
                );
          },
        );

      case 'IMAGE_MCQ':
        return ImageMcqQuestion(
          question: question,
          currentAnswer: currentAnswer,
          userName: userName,
          onAnswerChanged: (answer) {
            context.read<OnboardingBloc>().add(
                  AnswerQuestion(questionId: question.id, answer: answer),
                );
          },
        );

      case 'SLIDER':
        return SliderQuestion(
          question: question,
          currentAnswer: currentAnswer as int?,
          onAnswerChanged: (answer) {
            context.read<OnboardingBloc>().add(
                  AnswerQuestion(questionId: question.id, answer: answer),
                );
          },
        );

      default:
        return Center(
          child: Text(
            'Unknown question type: ${question.type}',
            style: const TextStyle(color: AppColors.error),
          ),
        );
    }
  }

  bool _isAnswerValid(dynamic question, dynamic answer) {
    if (!question.isRequired) return true;
    if (answer == null) return false;
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is List) return answer.isNotEmpty;
    if (answer is int) return true;
    return false;
  }
}
