/// Preferences Editing Screen
/// 
/// Allows users to edit their flatmate preferences after onboarding.
/// Shows all questions with show_in_preferences: true in a list view.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Flatmate Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(context, state),
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
                color: AppColors.background,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppColors.background,
          inactiveColor: AppColors.background.withOpacity(0.2),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.background : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.background : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.imageUrl != null) ...[
                      Image.network(
                        option.imageUrl!,
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 24),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      option.displayText, // Uses edit_display_text or text
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSubSelected ? AppColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSubSelected ? AppColors.background : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          subOption.displayText, // Uses edit_display_text or text
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.background, width: 2),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, PreferencesLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save & Search again button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.hasChanges
                    ? () {
                        context.read<PreferencesBloc>().add(SubmitPreferences());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Save & Search again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Skip button
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
