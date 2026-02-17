import 'package:flutter/material.dart';
import '../../../shared/widgets/question_header.dart';
import '../../../shared/widgets/text_input_field.dart';
import '../model/question_model.dart';

/// Text Input Question Widget - Phase 2
/// 
/// Displays TEXT_INPUT question type
/// Simple text input with customizable placeholder
class TextInputQuestion extends StatelessWidget {
  final Question question;
  final String? currentAnswer;
  final ValueChanged<String> onAnswerChanged;
  final String? userName;

  const TextInputQuestion({
    super.key,
    required this.question,
    this.currentAnswer,
    required this.onAnswerChanged,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionHeader(
          tertiaryText: question.tertiaryText,
          primaryText: question.primaryText,
          secondaryText: question.secondaryText,
          userName: userName,
        ),
        const SizedBox(height: 32),
        TextInputField(
          initialValue: currentAnswer,
          hintText: question.helpText ?? 'Type here...',
          onChanged: onAnswerChanged,
          keyboardType: _getKeyboardType(),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    final fieldName = question.fieldName.toUpperCase();
    if (fieldName.contains('AGE') || fieldName.contains('NUMBER')) {
      return TextInputType.number;
    }
    if (fieldName.contains('EMAIL')) {
      return TextInputType.emailAddress;
    }
    if (fieldName.contains('PHONE')) {
      return TextInputType.phone;
    }
    return TextInputType.text;
  }
}
