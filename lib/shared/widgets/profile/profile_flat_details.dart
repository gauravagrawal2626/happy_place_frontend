/// Flat Details section for ProfileModal.
/// Shown when flat_info.role == "lister".

import 'package:flutter/material.dart';
import '../../../features/profile/model/public_profile_model.dart';
import '../../theme/app_colors.dart';
import 'profile_question_responses.dart';

class ProfileFlatDetails extends StatefulWidget {
  final FlatInfo details;
  final String? location;

  const ProfileFlatDetails({super.key, required this.details, this.location});

  @override
  State<ProfileFlatDetails> createState() => _ProfileFlatDetailsState();
}

class _ProfileFlatDetailsState extends State<ProfileFlatDetails> {
  int _currentImageIndex = 0;

  FlatInfo get details => widget.details;

  static String _formatRent(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted/mo';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flat Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        if (details.images.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: PageView.builder(
                itemCount: details.images.length,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemBuilder: (context, i) => Image.network(
                  details.images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.background.withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(Icons.home, size: 48, color: AppColors.textDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (details.images.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(details.images.length, (i) {
                return Container(
                  width: _currentImageIndex == i ? 8 : 6,
                  height: _currentImageIndex == i ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == i
                        ? AppColors.textDark
                        : AppColors.textDark.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ],
        ] else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.background.withValues(alpha: 0.2),
              child: const Center(
                child: Icon(Icons.home, size: 48, color: AppColors.textDark),
              ),
            ),
          ),
        const SizedBox(height: 12),

        if (details.title != null)
          Text(
            details.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        if (widget.location != null || details.formattedAddress != null || details.locality != null || details.city != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textDark.withOpacity(0.6)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.location ??
                      details.formattedAddress ??
                      [details.locality, details.city].whereType<String>().join(', '),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (details.rent != null)
              _infoChip(Icons.currency_rupee, _formatRent(details.rent!)),
            if (details.bedrooms != null)
              _infoChip(Icons.bed, '${details.bedrooms} Bed'),
            if (details.bathrooms != null)
              _infoChip(Icons.bathtub_outlined, '${details.bathrooms} Bath'),
            if (details.areaSqft != null)
              _infoChip(Icons.square_foot, '${details.areaSqft} sqft'),
          ],
        ),

        if (_hasAmenities) ...[
          const SizedBox(height: 16),
          const Text(
            'Amenities',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildAmenityChips(),
          ),
        ],

        if (_hasRules) ...[
          const SizedBox(height: 16),
          const Text(
            'House Rules',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildRuleChips(),
          ),
        ],

        if (details.questionResponses.isNotEmpty) ...[
          const SizedBox(height: 16),
          ProfileQuestionResponses(responses: details.questionResponses),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textDark.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  bool get _hasAmenities =>
      details.amenities.values.any((v) => v == true);

  bool get _hasRules => details.rules.isNotEmpty;

  static const _amenityMap = <String, _AmenityDef>{
    'has_ac': _AmenityDef(Icons.ac_unit, 'AC'),
    'has_wifi': _AmenityDef(Icons.wifi, 'WiFi'),
    'has_parking': _AmenityDef(Icons.local_parking, 'Parking'),
    'has_gym': _AmenityDef(Icons.fitness_center, 'Gym'),
    'has_swimming_pool': _AmenityDef(Icons.pool, 'Pool'),
    'has_power_backup': _AmenityDef(Icons.battery_charging_full, 'Power Backup'),
    'has_security': _AmenityDef(Icons.security, 'Security'),
    'has_elevator': _AmenityDef(Icons.elevator, 'Elevator'),
    'is_furnished': _AmenityDef(Icons.chair, 'Furnished'),
    'has_attached_washroom': _AmenityDef(Icons.bathroom, 'Attached Washroom'),
    'has_attached_balcony': _AmenityDef(Icons.balcony, 'Balcony'),
    'has_washing_machine': _AmenityDef(Icons.local_laundry_service, 'Washing Machine'),
    'has_refrigerator': _AmenityDef(Icons.kitchen, 'Refrigerator'),
    'has_tv': _AmenityDef(Icons.tv, 'TV'),
    'has_geyser': _AmenityDef(Icons.water_drop, 'Geyser'),
  };

  List<Widget> _buildAmenityChips() {
    final chips = <Widget>[];
    for (final entry in _amenityMap.entries) {
      if (details.amenities[entry.key] == true) {
        chips.add(_styledChip(entry.value.icon, entry.value.label));
      }
    }
    return chips;
  }

  List<Widget> _buildRuleChips() {
    final chips = <Widget>[];
    final r = details.rules;
    if (r['smoking_allowed'] == true) {
      chips.add(_textChip('Smoking OK'));
    } else if (r.containsKey('smoking_allowed')) {
      chips.add(_textChip('No Smoking'));
    }
    if (r['pets_allowed'] == true) {
      chips.add(_textChip('Pets Allowed'));
    } else if (r.containsKey('pets_allowed')) {
      chips.add(_textChip('No Pets'));
    }
    if (r['guests_allowed'] == true) {
      chips.add(_textChip('Guests Welcome'));
    } else if (r.containsKey('guests_allowed')) {
      chips.add(_textChip('No Guests'));
    }
    if (r['preferred_gender'] != null && r['preferred_gender'] != 'ANY') {
      chips.add(_textChip('${r['preferred_gender']} only'));
    }
    if (r['preferred_occupation'] != null) {
      chips.add(_textChip(r['preferred_occupation'] as String));
    }
    return chips;
  }

  Widget _styledChip(IconData icon, String label) {
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

  Widget _textChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
      ),
    );
  }
}

class _AmenityDef {
  final IconData icon;
  final String label;
  const _AmenityDef(this.icon, this.label);
}
