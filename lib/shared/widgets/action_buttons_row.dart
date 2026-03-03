/// Action Buttons Row
/// 
/// Shared widget for the two action buttons displayed horizontally.
/// Used in both SEEKER and LISTER screens with customizable text and callbacks.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActionButtonsRow extends StatelessWidget {
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;
  final bool leftButtonEnabled;
  final bool rightButtonEnabled;

  const ActionButtonsRow({
    super.key,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.onLeftPressed,
    required this.onRightPressed,
    this.leftButtonEnabled = true,
    this.rightButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left button (outline style)
        Expanded(
          child: ElevatedButton(
            onPressed: leftButtonEnabled ? onLeftPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textDark,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: leftButtonEnabled 
                      ? AppColors.textDark 
                      : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              elevation: 2,
            ),
            child: Text(
              leftButtonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right button (filled style)
        Expanded(
          child: ElevatedButton(
            onPressed: rightButtonEnabled ? onRightPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: Text(
              rightButtonText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
