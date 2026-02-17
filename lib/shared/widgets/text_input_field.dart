import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Text Input Field - Phase 2
/// 
/// Reusable text input for onboarding
class TextInputField extends StatelessWidget {
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;

  const TextInputField({
    super.key,
    this.initialValue,
    this.hintText,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark.withOpacity(0.4),
        ),
        filled: true,
        fillColor: AppColors.chipUnselected,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.chipSelected,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}

