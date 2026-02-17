import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Question Header - Phase 2
/// 
/// Displays 3 types of text matching Figma design:
/// - tertiary_text: Greeting at top (e.g., "Hey, Muskan", "Okay, cutie.")
/// - primary_text: Main question (e.g., "What's your gender?")
/// - secondary_text: Help description below question
class QuestionHeader extends StatelessWidget {
  final String? tertiaryText;   // Greeting: "Hey, {name}", "Okay, cutie."
  final String primaryText;     // Main question: "What's your gender?"
  final String? secondaryText;  // Help text: "Pick what suits you..."
  final String? userName;       // For {name} placeholder replacement

  const QuestionHeader({
    super.key,
    this.tertiaryText,
    required this.primaryText,
    this.secondaryText,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tertiary text (greeting) - larger as per Figma
        if (tertiaryText != null && tertiaryText!.isNotEmpty) ...[
          Text(
            _processGreeting(tertiaryText!),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Primary text (main question) - bold, should fit on one line
        Text(
          primaryText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            height: 1.2,
          ),
        ),
        
        // Secondary text (help/description) - darker as per Figma
        if (secondaryText != null && secondaryText!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            secondaryText!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  /// Replace {name} placeholder with actual user name
  String _processGreeting(String greeting) {
    if (userName != null && greeting.contains('{name}')) {
      return greeting.replaceAll('{name}', userName!);
    }
    return greeting;
  }
}
