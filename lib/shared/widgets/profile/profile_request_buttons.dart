/// Reusable request status buttons (Send Request, PENDING, Accept, etc.).
/// Used only in ProfileModal (other user), not in own profile tab.

import 'package:flutter/material.dart';
import '../../../features/profile/model/public_profile_model.dart';
import '../../theme/app_colors.dart';

class ProfileRequestButtons extends StatelessWidget {
  final List<RequestStatusButton> buttons;
  final String? sendingAction;
  final ValueChanged<RequestStatusButton> onPressed;

  const ProfileRequestButtons({
    super.key,
    required this.buttons,
    this.sendingAction,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons.map((button) {
        final isThisButtonSending =
            button.action != null && sendingAction == button.action;
        final enabled = button.isClickable && !isThisButtonSending;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? () => onPressed(button) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? AppColors.textDark
                    : AppColors.textDark.withOpacity(0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isThisButtonSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(button.text),
            ),
          ),
        );
      }).toList(),
    );
  }
}
