/// Preferences Editing Screen
/// 
/// Allows users to edit their flatmate preferences after onboarding.
/// Shows all questions with show_in_preferences: true in a list view.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../bloc/preferences_bloc.dart';
import '../bloc/preferences_event.dart';
import '../bloc/preferences_state.dart';
import '../../onboarding/model/question_model.dart';

class PreferencesEditScreen extends StatelessWidget {
  const PreferencesEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = PreferencesBloc(
          repository: context.read(),
        );
        bloc.add(LoadPreferenceQuestions());
        return bloc;
      },
      child: const _PreferencesEditContent(),
    );
  }
}

class _PreferencesEditContent extends StatelessWidget {
  const _PreferencesEditContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PreferencesBloc, PreferencesState>(
      listener: (context, state) {
        if (state is PreferencesSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to finding matches to refresh data based on user role
          final appState = context.read<AppBloc>().state;
          if (appState is AppAuthenticated) {
            final isLister = appState.authResponse.role == 'LISTER';
            // Use the appropriate source based on user role
            final source = isLister ? 'flat-lister' : 'flat-seeker';
            context.go('/finding-matches/$source');
          } else {
            // Fallback: go back if not authenticated (shouldn't happen)
            context.pop();
          }
        } else if (state is PreferencesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PreferencesLoading || state is PreferencesInitial) {
          return AppScaffold(
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (state is PreferencesSubmitting) {
          return AppScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'Saving preferences...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PreferencesError && state.previousState == null) {
          return AppScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PreferencesBloc>().add(LoadPreferenceQuestions());
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PreferencesLoaded) {
          return _buildMainContent(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMainContent(BuildContext context, PreferencesLoaded state) {
    return AppScaffold(
      useSafeArea: false,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Flatmate Preferences',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...state.questions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _buildQuestionSection(
                          context,
                          question,
                          state.answers[question.id],
                          (answer) {
                            context.read<PreferencesBloc>().add(
                              UpdatePreferenceAnswer(
                                questionId: question.id,
                                answer: answer,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection(
    BuildContext context,
    Question question,
    dynamic currentAnswer,
    ValueChanged<dynamic> onAnswerChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label (edit_widget_text)
        Text(
          question.editWidgetText ?? question.primaryText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Question content based on type
        if (question.type == 'SLIDER')
          _buildSliderQuestion(question, currentAnswer, onAnswerChanged)
        else if (question.type == 'TEXT_MCQ' || question.type == 'IMAGE_MCQ')
          _buildMcqQuestion(question, currentAnswer, onAnswerChanged)
        else if (question.type == 'TEXT_INPUT')
          _buildTextInputQuestion(question, currentAnswer, onAnswerChanged),
      ],
    );
  }

  Widget _buildSliderQuestion(
    Question question,
    dynamic currentAnswer,
    ValueChanged<dynamic> onAnswerChanged,
  ) {
    final value = (currentAnswer as int?) ?? question.uiConfig.defaultValue ?? question.uiConfig.min ?? 25;
    final min = question.uiConfig.min ?? 18;
    final max = question.uiConfig.max ?? 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppColors.textDark,
          inactiveColor: AppColors.textDark.withOpacity(0.2),
          onChanged: (newValue) {
            onAnswerChanged(newValue.toInt());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$min',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '$max',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMcqQuestion(
    Question question,
    dynamic currentAnswer,
    ValueChanged<dynamic> onAnswerChanged,
  ) {
    final isMultiSelect = question.isMultiSelect;
    final selectedAnswers = currentAnswer is List
        ? currentAnswer.cast<String>()
        : (currentAnswer != null ? [currentAnswer.toString()] : <String>[]);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: question.options.map((option) {
        // Check if parent is selected OR any of its sub-options are selected
        final isParentSelected = selectedAnswers.contains(option.id);
        final hasSubOptions = option.isParent && option.subOptions != null && option.subOptions!.isNotEmpty;
        final hasSubOptionSelected = hasSubOptions
            ? option.subOptions!.any((sub) => selectedAnswers.contains(sub.id))
            : false;
        final isSelected = isParentSelected || hasSubOptionSelected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent option
            GestureDetector(
              onTap: () {
                if (isMultiSelect) {
                  final updated = List<String>.from(selectedAnswers);
                  if (isSelected) {
                    updated.remove(option.id);
                    // Also remove sub-options if parent is deselected
                    if (hasSubOptions) {
                      for (final sub in option.subOptions!) {
                        updated.remove(sub.id);
                      }
                    }
                  } else {
                    if (updated.length < question.maxSelections) {
                      updated.add(option.id);
                    }
                  }
                  onAnswerChanged(updated);
                } else {
                  onAnswerChanged(option.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textDark : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option.displayText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
            
            // Sub-options (shown below parent if parent is selected OR any sub-option is selected)
            if (hasSubOptions && (isParentSelected || hasSubOptionSelected)) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: option.subOptions!.map((subOption) {
                    final isSubSelected = selectedAnswers.contains(subOption.id);
                    return GestureDetector(
                      onTap: () {
                        if (isMultiSelect) {
                          final updated = List<String>.from(selectedAnswers);
                          if (isSubSelected) {
                            updated.remove(subOption.id);
                          } else {
                            if (updated.length < question.maxSelections) {
                              updated.add(subOption.id);
                            }
                          }
                          onAnswerChanged(updated);
                        } else {
                          onAnswerChanged(subOption.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSubSelected ? AppColors.textDark : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subOption.displayText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSubSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTextInputQuestion(
    Question question,
    dynamic currentAnswer,
    ValueChanged<dynamic> onAnswerChanged,
  ) {
    return TextField(
      onChanged: onAnswerChanged,
      controller: TextEditingController(
        text: currentAnswer?.toString() ?? '',
      )..selection = TextSelection.fromPosition(
        TextPosition(offset: (currentAnswer?.toString() ?? '').length),
      ),
      decoration: InputDecoration(
        hintText: question.helpText ?? 'Enter text...',
        fillColor: Colors.white.withOpacity(0.85),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textDark.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textDark.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.textDark, width: 2),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, PreferencesLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.hasChanges
                  ? () {
                      unawaited(
                        context.read<AnalyticsFacade>().button(
                              AnalyticsButtonNames.savePreferences,
                              screenName: AnalyticsScreenNames.preferencesEdit,
                            ),
                      );
                      context.read<PreferencesBloc>().add(SubmitPreferences());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
