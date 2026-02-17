import 'package:flutter/material.dart';
import '../../../shared/widgets/question_header.dart';
import '../../../shared/widgets/chip_button.dart';
import '../../../shared/theme/app_colors.dart';
import '../model/question_model.dart';

/// Text MCQ Question Widget - Enhanced with Sub-Options
/// 
/// Displays TEXT_MCQ question type with various layouts:
/// - Gender: Circular buttons (Frame 2)
/// - User Type: Expandable accordion with sub-options (Frame 9 & 21)
/// - Priorities: Chip buttons (Frame 4)
class TextMcqQuestion extends StatefulWidget {
  final Question question;
  final dynamic currentAnswer; // String or List<String>
  final ValueChanged<dynamic> onAnswerChanged;
  final String? userName;

  const TextMcqQuestion({
    super.key,
    required this.question,
    this.currentAnswer,
    required this.onAnswerChanged,
    this.userName,
  });

  @override
  State<TextMcqQuestion> createState() => _TextMcqQuestionState();
}

class _TextMcqQuestionState extends State<TextMcqQuestion> {
  String? _expandedParentId; // Track which parent option is expanded

  @override
  void initState() {
    super.initState();
    // If there's a current answer, find and expand its parent
    _initializeExpandedState();
  }

  @override
  void didUpdateWidget(TextMcqQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      _initializeExpandedState();
    }
  }

  void _initializeExpandedState() {
    if (widget.currentAnswer != null && widget.question.hasSubOptions) {
      // Find which parent the current answer belongs to
      for (final option in widget.question.options) {
        if (option.isParent && option.subOptions != null) {
          for (final subOption in option.subOptions!) {
            if (subOption.id == widget.currentAnswer) {
              _expandedParentId = option.id;
              return;
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine header text - use expanded_title if a parent is selected
    String headerPrimaryText = widget.question.primaryText;
    if (_expandedParentId != null && widget.question.uiConfig.expandedTitle != null) {
      headerPrimaryText = widget.question.uiConfig.expandedTitle!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionHeader(
          tertiaryText: widget.question.tertiaryText,
          primaryText: headerPrimaryText,
          secondaryText: widget.question.secondaryText,
          userName: widget.userName,
        ),
        const SizedBox(height: 32),
        _buildOptionsLayout(),
      ],
    );
  }

  Widget _buildOptionsLayout() {
    final fieldName = widget.question.fieldName.toUpperCase();
    
    // Gender question - circular buttons
    if (fieldName == 'GENDER') {
      return _buildGenderLayout();
    }
    
    // User type with expandable sub-options
    if (fieldName == 'USER_TYPE' || widget.question.uiConfig.expandable) {
      return _buildExpandableLayout();
    }
    
    // Priorities or chip_style - use chips
    if (widget.question.uiConfig.chipStyle || fieldName == 'PRIORITIES') {
      return _buildChipLayout();
    }

    // Default - simple button layout
    return _buildSimpleButtonLayout();
  }

  /// Gender layout - circular buttons (Frame 2)
  Widget _buildGenderLayout() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.question.options.map((option) {
          final isSelected = _isOptionSelected(option.id);

          return GestureDetector(
            onTap: () => _handleSimpleOptionTap(option.id),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textDark : const Color(0xFFD4F1F4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Expandable layout with sub-options (Frame 9 & 21 - USER_TYPE)
  Widget _buildExpandableLayout() {
    return Column(
      children: widget.question.options.map((option) {
        final isExpanded = _expandedParentId == option.id;
        final hasSelectedSubOption = _hasSelectedSubOption(option);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Parent option
              GestureDetector(
                onTap: () => _handleParentTap(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: (isExpanded || hasSelectedSubOption) 
                        ? AppColors.textDark 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isExpanded || hasSelectedSubOption) 
                          ? AppColors.textDark 
                          : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox icon
                      Icon(
                        hasSelectedSubOption 
                            ? Icons.check_box 
                            : Icons.check_box_outline_blank,
                        color: (isExpanded || hasSelectedSubOption) 
                            ? Colors.white 
                            : AppColors.textDark,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: (isExpanded || hasSelectedSubOption) 
                                ? Colors.white 
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      // Arrow icon
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                        color: (isExpanded || hasSelectedSubOption) 
                            ? Colors.white 
                            : AppColors.textDark,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sub-options (shown when expanded)
              if (isExpanded && option.subOptions != null)
                _buildSubOptions(option),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build sub-options for an expanded parent
  Widget _buildSubOptions(QuestionOption parent) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: parent.subOptions!.map((subOption) {
          final isSelected = widget.currentAnswer == subOption.id;

          return GestureDetector(
            onTap: () => _handleSubOptionTap(subOption.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.textDark : Colors.black38,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.textDark : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subOption.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Chip layout - horizontal wrap (Frame 4 - Priorities)
  Widget _buildChipLayout() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.question.options.map((option) {
        final isSelected = _isOptionSelected(option.id);

        return ChipButton(
          text: option.text,
          isSelected: isSelected,
          onTap: () => _handleMultiSelectTap(option.id),
        );
      }).toList(),
    );
  }

  /// Simple button layout - horizontal wrap
  Widget _buildSimpleButtonLayout() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: widget.question.options.map((option) {
        final isSelected = _isOptionSelected(option.id);

        return GestureDetector(
          onTap: () => _handleSimpleOptionTap(option.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textDark : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.textDark : Colors.black12,
                width: 1.5,
              ),
            ),
            child: Text(
              option.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isOptionSelected(String optionId) {
    if (widget.currentAnswer == null) return false;
    
    if (widget.question.isMultiSelect) {
      if (widget.currentAnswer is List) {
        return (widget.currentAnswer as List).contains(optionId);
      }
      return false;
    } else {
      return widget.currentAnswer == optionId;
    }
  }

  bool _hasSelectedSubOption(QuestionOption option) {
    if (!option.isParent || option.subOptions == null) return false;
    if (widget.currentAnswer == null) return false;
    
    return option.subOptions!.any((sub) => sub.id == widget.currentAnswer);
  }

  void _handleParentTap(QuestionOption option) {
    if (option.isParent && option.subOptions != null) {
      // Toggle expansion
      setState(() {
        if (_expandedParentId == option.id) {
          _expandedParentId = null;
        } else {
          _expandedParentId = option.id;
        }
      });
    } else {
      // No sub-options, treat as regular option
      _handleSimpleOptionTap(option.id);
    }
  }

  void _handleSubOptionTap(String subOptionId) {
    widget.onAnswerChanged(subOptionId);
  }

  void _handleSimpleOptionTap(String optionId) {
    widget.onAnswerChanged(optionId);
  }

  void _handleMultiSelectTap(String optionId) {
    final currentList = widget.currentAnswer is List 
        ? List<String>.from(widget.currentAnswer) 
        : <String>[];
    
    if (currentList.contains(optionId)) {
      currentList.remove(optionId);
    } else {
      // Check max selections
      if (widget.question.maxSelections > 1 && 
          currentList.length >= widget.question.maxSelections) {
        return; // Can't select more
      }
      currentList.add(optionId);
    }
    widget.onAnswerChanged(currentList);
  }
}
