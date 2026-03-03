/// Shared Q&A list widget for flat details and flat preferences sections.

import 'package:flutter/material.dart';
import '../../../features/profile/model/public_profile_model.dart';
import '../../theme/app_colors.dart';

class ProfileQuestionResponses extends StatelessWidget {
  final List<ResolvedQuestionResponse> responses;

  const ProfileQuestionResponses({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: responses.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.question,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r.answer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
