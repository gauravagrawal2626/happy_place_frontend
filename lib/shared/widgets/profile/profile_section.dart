/// Reusable profile section: title + bullet list or single line.
/// Used for "Food & Smoking preference", "Top 3 priorities", "Weekend activities".
/// Edit icon is ignored for now per plan.

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  /// Bullet items; if non-null and non-empty, shown as bullet list.
  final List<String>? bullets;
  /// Single line; used when bullets is null or empty (e.g. weekend activities).
  final String? singleLine;

  const ProfileSection({
    super.key,
    required this.title,
    this.bullets,
    this.singleLine,
  });

  @override
  Widget build(BuildContext context) {
    final hasBullets = bullets != null && bullets!.isNotEmpty;
    if (!hasBullets && (singleLine == null || singleLine!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        if (hasBullets)
          ...bullets!.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.textDark)),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        if (!hasBullets && singleLine != null && singleLine!.isNotEmpty)
          Text(
            singleLine!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withOpacity(0.9),
            ),
          ),
      ],
    );
  }
}
