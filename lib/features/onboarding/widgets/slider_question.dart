import 'package:flutter/material.dart';
import '../../../shared/widgets/question_header.dart';
import '../../../shared/theme/app_colors.dart';
import '../model/question_model.dart';

/// Slider Question Widget - Phase 2
/// 
/// Displays SLIDER question type (Frame 3 - Age)
/// Features:
/// - Horizontal slider with min/max values
/// - Current value displayed prominently
/// - Matches Figma design
class SliderQuestion extends StatefulWidget {
  final Question question;
  final int? currentAnswer;
  final ValueChanged<int> onAnswerChanged;

  const SliderQuestion({
    super.key,
    required this.question,
    this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  State<SliderQuestion> createState() => _SliderQuestionState();
}

class _SliderQuestionState extends State<SliderQuestion> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = (widget.currentAnswer ?? 
        widget.question.uiConfig.defaultValue ?? 
        25).toDouble();
  }

  @override
  void didUpdateWidget(SliderQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnswer != null && 
        widget.currentAnswer != oldWidget.currentAnswer) {
      _currentValue = widget.currentAnswer!.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = widget.question.uiConfig;
    final min = (uiConfig.min ?? 18).toDouble();
    final max = (uiConfig.max ?? 60).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionHeader(
          tertiaryText: widget.question.tertiaryText,
          primaryText: widget.question.primaryText,
          secondaryText: widget.question.secondaryText,
        ),
        const SizedBox(height: 48),
        
        // Slider with value display
        Column(
          children: [
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.textDark,
                inactiveTrackColor: AppColors.textDark.withOpacity(0.2),
                thumbColor: AppColors.textDark,
                overlayColor: AppColors.textDark.withOpacity(0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                ),
              ),
              child: Slider(
                value: _currentValue,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                onChanged: (value) {
                  setState(() {
                    _currentValue = value;
                  });
                  widget.onAnswerChanged(value.toInt());
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Value display
            Text(
              '${_currentValue.toInt()}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            
            // Min/Max labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${min.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '${max.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

