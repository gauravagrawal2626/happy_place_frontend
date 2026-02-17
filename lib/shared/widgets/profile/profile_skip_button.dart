/// Reusable Skip button (underlined text) at bottom of profile/invites sheets.

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileSkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileSkipButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: const Text(
          'Skip',
          style: TextStyle(
            fontSize: 14,
            decoration: TextDecoration.underline,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
