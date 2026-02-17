/// Reusable profile header: avatar, name, age/gender.
/// Used in ProfileModal and ProfileInvitesSheet (Profile tab).

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String? profilePictureUrl;
  final String fullName;
  final int? age;
  final String? gender;
  final double avatarRadius;

  const ProfileHeader({
    super.key,
    this.profilePictureUrl,
    required this.fullName,
    this.age,
    this.gender,
    this.avatarRadius = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppColors.background.withOpacity(0.5),
          backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
              ? NetworkImage(profilePictureUrl!)
              : null,
          child: profilePictureUrl == null || profilePictureUrl!.isEmpty
              ? Icon(Icons.person, size: avatarRadius * 1.1, color: AppColors.textDark)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              if (age != null)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textDark),
                    const SizedBox(width: 4),
                    Text(
                      '$age${gender != null && gender!.isNotEmpty ? ", $gender" : ""}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
