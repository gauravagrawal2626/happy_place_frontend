import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Chip Button - Phase 2
/// 
/// Used for multi-select chip options (Frame 4 - Priorities)
class ChipButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPinkChip; // Special styling for "In a society"

  const ChipButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.isPinkChip = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    if (isPinkChip) {
      backgroundColor = isSelected ? AppColors.chipPink : AppColors.chipPink.withOpacity(0.3);
      textColor = AppColors.textDark;
    } else if (isSelected) {
      backgroundColor = AppColors.chipSelected;
      textColor = AppColors.textLight;
    } else {
      backgroundColor = AppColors.chipUnselected;
      textColor = AppColors.textDark;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: isSelected && !isPinkChip
              ? null
              : Border.all(
                  color: AppColors.textDark.withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

