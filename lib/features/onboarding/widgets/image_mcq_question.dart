import 'package:flutter/material.dart';
import '../../../shared/widgets/question_header.dart';
import '../../../shared/widgets/image_option_card.dart';
import '../../../shared/theme/app_colors.dart';
import '../model/question_model.dart';

/// Image MCQ Question Widget - Enhanced with Inline Sub-Options
/// 
/// Displays IMAGE_MCQ question type with images from S3
/// Supports inline sub-options for DIETARY and SMOKING questions (Frame 6, 7, 30)
/// 
/// Sub-option flow:
/// 1. User taps parent option (e.g., Vegetarian)
/// 2. Sub-options appear inline below the parent
/// 3. User selects a sub-option
/// 4. Final answer = sub-option ID
class ImageMcqQuestion extends StatefulWidget {
  final Question question;
  final dynamic currentAnswer; // List<String> for multi-select, String for single
  final ValueChanged<dynamic> onAnswerChanged;
  final String? userName;

  const ImageMcqQuestion({
    super.key,
    required this.question,
    this.currentAnswer,
    required this.onAnswerChanged,
    this.userName,
  });

  @override
  State<ImageMcqQuestion> createState() => _ImageMcqQuestionState();
}

class _ImageMcqQuestionState extends State<ImageMcqQuestion> {
  String? _selectedParentId; // Track which parent is selected for sub-options

  @override
  void initState() {
    super.initState();
    _initializeSelectedParent();
  }

  @override
  void didUpdateWidget(ImageMcqQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      final previousParentId = _selectedParentId;
      _initializeSelectedParent();
      // Update state if parent changed
      if (_selectedParentId != previousParentId) {
        setState(() {});
      }
    }
  }

  void _initializeSelectedParent() {
    if (widget.currentAnswer != null && widget.question.hasSubOptions) {
      // Find which parent the current answer belongs to
      for (final option in widget.question.options) {
        if (option.isParent && option.subOptions != null) {
          // Check if current answer is one of this parent's sub-options
          final isSubOption = option.subOptions!.any(
            (sub) => sub.id == widget.currentAnswer,
          );
          if (isSubOption) {
            _selectedParentId = option.id;
            return;
          }
        }
        // Check if the answer is a parent option itself (shouldn't be final answer)
        if (option.id == widget.currentAnswer && option.isParent) {
          _selectedParentId = option.id;
          return;
        }
      }
      // If we couldn't find a parent, clear _selectedParentId
      _selectedParentId = null;
    } else if (widget.currentAnswer == null) {
      // If answer is cleared, also clear selected parent
      _selectedParentId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = (widget.question.uiConfig.columns ?? 3).clamp(2, 3);
    final isLargeCard = columns == 2;
    final cardSize = isLargeCard ? 100.0 : 80.0;
    final fontSize = isLargeCard ? 14.0 : 13.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionHeader(
          tertiaryText: widget.question.tertiaryText,
          primaryText: widget.question.primaryText,
          secondaryText: widget.question.secondaryText,
          userName: widget.userName,
        ),
        const SizedBox(height: 40),
        
        // Grid of image options
        _buildOptionsGrid(columns, cardSize, fontSize),
        
        // Inline sub-options (shown when a parent with sub-options is selected)
        if (_shouldShowSubOptions())
          _buildInlineSubOptions(),
      ],
    );
  }

  bool _shouldShowSubOptions() {
    if (_selectedParentId == null) return false;
    if (!widget.question.uiConfig.showSubOptionsInline) return false;
    
    try {
      final selectedOption = widget.question.options.firstWhere(
        (opt) => opt.id == _selectedParentId,
      );
      return selectedOption.isParent && selectedOption.subOptions != null;
    } catch (e) {
      // Parent not found - clear selection and return false
      _selectedParentId = null;
      return false;
    }
  }

  Widget _buildOptionsGrid(int columns, double cardSize, double fontSize) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: columns == 2 ? 0.9 : 0.75,
      ),
      itemCount: widget.question.options.length,
      itemBuilder: (context, index) {
        final option = widget.question.options[index];
        final isSelected = _isOptionSelected(option);

        return ImageOptionCard(
          text: option.text,
          imageUrl: option.imageUrl,
          fallbackIcon: _getIconForOption(option.text),
          isSelected: isSelected,
          onTap: () => _handleOptionTap(option),
          size: cardSize,
          fontSize: fontSize,
        );
      },
    );
  }

  Widget _buildInlineSubOptions() {
    // Safely find the selected option
    QuestionOption selectedOption;
    try {
      selectedOption = widget.question.options.firstWhere(
        (opt) => opt.id == _selectedParentId,
      );
    } catch (e) {
      // Parent not found - clear selection and return empty widget
      _selectedParentId = null;
      return const SizedBox.shrink();
    }

    // Double-check that we have sub-options
    if (!selectedOption.isParent || 
        selectedOption.subOptions == null || 
        selectedOption.subOptions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedOption.subOptions!.map((subOption) {
          final isSelected = widget.currentAnswer == subOption.id;

          return GestureDetector(
            onTap: () => _handleSubOptionTap(subOption.id),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textDark : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subOption.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isOptionSelected(QuestionOption option) {
    // For multi-select without sub-options
    if (widget.question.isMultiSelect && !option.isParent) {
      if (widget.currentAnswer is List) {
        return (widget.currentAnswer as List).contains(option.id);
      }
      return false;
    }
    
    // For single select with sub-options
    if (option.isParent && option.subOptions != null) {
      // Check if any sub-option of this parent is selected
      if (widget.currentAnswer != null) {
        return option.subOptions!.any((sub) => sub.id == widget.currentAnswer);
      }
      // If no answer yet, check if this parent is selected for showing sub-options
      return _selectedParentId == option.id;
    }
    
    // Simple single select (no sub-options)
    return widget.currentAnswer == option.id;
  }

  void _handleOptionTap(QuestionOption option) {
    if (option.isParent && option.subOptions != null) {
      // Has sub-options - show them inline
      setState(() {
        if (_selectedParentId == option.id) {
          // Tapping same parent again - keep it selected, don't collapse
          // User must select a sub-option
        } else {
          // Switching to a different parent - clear previous answer if it was a sub-option
          // from a different parent
          if (widget.currentAnswer != null) {
            bool isSubOptionOfCurrentParent = false;
            for (final opt in widget.question.options) {
              if (opt.id == option.id && opt.subOptions != null) {
                isSubOptionOfCurrentParent = opt.subOptions!.any(
                  (sub) => sub.id == widget.currentAnswer,
                );
                break;
              }
            }
            // If current answer is a sub-option of a different parent, clear it
            if (!isSubOptionOfCurrentParent) {
              widget.onAnswerChanged(null);
            }
          }
          _selectedParentId = option.id;
          // Don't set answer yet - wait for sub-option selection
        }
      });
    } else {
      // No sub-options - handle normally
      if (widget.question.isMultiSelect) {
        _handleMultiSelectTap(option.id);
      } else {
        widget.onAnswerChanged(option.id);
      }
    }
  }

  void _handleSubOptionTap(String subOptionId) {
    // Find which parent this sub-option belongs to and set it immediately
    String? parentId;
    for (final option in widget.question.options) {
      if (option.isParent && option.subOptions != null) {
        if (option.subOptions!.any((sub) => sub.id == subOptionId)) {
          parentId = option.id;
          break;
        }
      }
    }
    
    // Update state and answer
    setState(() {
      if (parentId != null) {
        _selectedParentId = parentId;
      }
    });
    
    widget.onAnswerChanged(subOptionId);
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

  IconData _getIconForOption(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('travel')) return Icons.flight_takeoff;
    if (lower.contains('binge') || lower.contains('watch')) return Icons.tv;
    if (lower.contains('exercise') || lower.contains('gym')) return Icons.fitness_center;
    if (lower.contains('pet')) return Icons.pets;
    if (lower.contains('idea') || lower.contains('work')) return Icons.lightbulb_outline;
    if (lower.contains('dance')) return Icons.music_note;
    if (lower.contains('sport')) return Icons.sports_soccer;
    if (lower.contains('date')) return Icons.favorite_border;
    if (lower.contains('vegetarian') || lower.contains('veg')) return Icons.eco;
    if (lower.contains('non-veg')) return Icons.restaurant;
    if (lower.contains('smoker') && !lower.contains('non')) return Icons.smoking_rooms;
    if (lower.contains('non-smoker')) return Icons.smoke_free;
    
    return Icons.more_horiz;
  }
}
