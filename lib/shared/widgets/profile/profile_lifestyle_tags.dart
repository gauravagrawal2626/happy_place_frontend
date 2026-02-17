/// Reusable lifestyle tags (icons + labels).
/// Used in ProfileModal and ProfileInvitesSheet Profile tab.

import 'package:flutter/material.dart';
import '../../../features/profile/model/public_profile_model.dart';
import '../../theme/app_colors.dart';

class ProfileLifestyleTags extends StatelessWidget {
  final List<LifestyleTag> tags;

  const ProfileLifestyleTags({super.key, required this.tags});

  static IconData _iconForTag(LifestyleTag tag) {
    final type = tag.type.toLowerCase();
    final label = tag.label.toLowerCase();
    if (type.contains('diet') || label.contains('veg')) return Icons.eco;
    if (type.contains('smok') || label.contains('smok')) return Icons.smoke_free;
    return Icons.label_outline;
  }

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final icon = _iconForTag(tag);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textDark.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textDark),
              const SizedBox(width: 6),
              Text(
                tag.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
