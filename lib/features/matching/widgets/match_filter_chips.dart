import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../model/filter_model.dart';

/// Dynamic filter chip bar that renders question-based filters.
///
/// Replaces the hardcoded filter chips in both lister and seeker match screens.
/// Each chip shows the selected option label (or the question's primaryText as default).
/// Active (changed from default) chips are highlighted with the theme color.
/// Optionally shows a "Location" chip for seekers when locationFilter is provided.
class MatchFilterChips extends StatelessWidget {
  final List<QuestionFilter> filters;
  final Map<String, String> activeValues;
  final void Function(QuestionFilter filter) onFilterTap;
  final LocationFilter? locationFilter;
  final bool locationChanged;
  final VoidCallback? onLocationTap;

  const MatchFilterChips({
    super.key,
    required this.filters,
    required this.activeValues,
    required this.onFilterTap,
    this.locationFilter,
    this.locationChanged = false,
    this.onLocationTap,
  });

  IconData _iconForField(String fieldName) {
    final lower = fieldName.toLowerCase();
    if (lower.contains('diet') || lower.contains('food') || lower.contains('vegetarian')) {
      return Icons.eco_outlined;
    }
    if (lower.contains('smok')) return Icons.smoke_free;
    if (lower.contains('drink') || lower.contains('alcohol')) return Icons.local_bar_outlined;
    if (lower.contains('pet')) return Icons.pets_outlined;
    if (lower.contains('guest') || lower.contains('visitor')) return Icons.people_outline;
    if (lower.contains('clean') || lower.contains('hygiene')) return Icons.cleaning_services_outlined;
    if (lower.contains('sleep') || lower.contains('night')) return Icons.nightlight_outlined;
    if (lower.contains('music') || lower.contains('noise')) return Icons.music_note_outlined;
    if (lower.contains('work') || lower.contains('profession')) return Icons.work_outline;
    if (lower.contains('rent') || lower.contains('budget')) return Icons.currency_rupee;
    if (lower.contains('location') || lower.contains('area')) return Icons.location_on_outlined;
    return Icons.tune;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = filters.isNotEmpty;
    final hasLocation = locationFilter != null;
    if (!hasFilters && !hasLocation) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Location chip (seeker-only)
              if (hasLocation) _buildLocationChip(),
              // Question filter chips
              ...filters.map((filter) {
                final activeVal = activeValues[filter.id];
                final isChanged =
                    activeVal != null && activeVal != filter.currentValue;
                final chipLabel = filter.chipLabelForValue(activeVal) ??
                    filter.chipLabelForValue(filter.currentValue) ??
                    filter.primaryText;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isChanged,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForField(filter.fieldName),
                          size: 16,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chipLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.background,
                    side:
                        const BorderSide(color: AppColors.textDark, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) => onFilterTap(filter),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip() {
    final loc = locationFilter!;
    final label = loc.savedLocations.isNotEmpty
        ? loc.savedLocations.first.name
        : 'Location';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: locationChanged,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.background,
        side: const BorderSide(color: AppColors.textDark, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (_) => onLocationTap?.call(),
      ),
    );
  }
}
