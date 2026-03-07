/// Flat Preferences section for ProfileModal.
/// Shown when flat_info.role == "seeker".

import 'package:flutter/material.dart';
import '../../../features/profile/model/public_profile_model.dart';
import '../../theme/app_colors.dart';
import 'profile_question_responses.dart';

class ProfileFlatPreferences extends StatelessWidget {
  final FlatInfo preferences;

  const ProfileFlatPreferences({super.key, required this.preferences});

  static String _formatRent(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted/mo';
  }

  static const _facilityMap = <String, _FacilityDef>{
    'ac': _FacilityDef(Icons.ac_unit, 'AC'),
    'wifi': _FacilityDef(Icons.wifi, 'WiFi'),
    'parking': _FacilityDef(Icons.local_parking, 'Parking'),
    'gym': _FacilityDef(Icons.fitness_center, 'Gym'),
    'washing_machine': _FacilityDef(Icons.local_laundry_service, 'Washing Machine'),
    'attached_washroom': _FacilityDef(Icons.bathroom, 'Attached Washroom'),
    'balcony': _FacilityDef(Icons.balcony, 'Balcony'),
    'power_backup': _FacilityDef(Icons.battery_charging_full, 'Power Backup'),
    'swimming_pool': _FacilityDef(Icons.pool, 'Pool'),
    'security': _FacilityDef(Icons.security, 'Security'),
    'elevator': _FacilityDef(Icons.elevator, 'Elevator'),
    'furnished': _FacilityDef(Icons.chair, 'Furnished'),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Looking For',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (preferences.preferredListingType != null)
              _tagChip(_formatListingType(preferences.preferredListingType!)),
            if (preferences.preferredFlatSize != null)
              _tagChip(preferences.preferredFlatSize!),
          ],
        ),

        if (preferences.maxRent != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.currency_rupee, size: 16, color: AppColors.textDark.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                'Up to ${_formatRent(preferences.maxRent!)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],

        if (preferences.preferredLocations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Preferred Areas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferences.preferredLocations.map((loc) {
              return _facilityChip(Icons.location_on, '${loc.name}, ${loc.city}');
            }).toList(),
          ),
        ],

        if (preferences.requiredFacilities.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Required Facilities',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferences.requiredFacilities.map((f) {
              final def = _facilityMap[f];
              if (def != null) {
                return _facilityChip(def.icon, def.label);
              }
              return _tagChip(f);
            }).toList(),
          ),
        ],

        if (preferences.questionResponses.isNotEmpty) ...[
          const SizedBox(height: 16),
          ProfileQuestionResponses(responses: preferences.questionResponses),
        ],
      ],
    );
  }

  String _formatListingType(String type) {
    switch (type) {
      case 'SHARED_FLAT':
        return 'Shared Flat';
      case 'ENTIRE_FLAT':
        return 'Entire Flat';
      default:
        return type;
    }
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _facilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _FacilityDef {
  final IconData icon;
  final String label;
  const _FacilityDef(this.icon, this.label);
}
