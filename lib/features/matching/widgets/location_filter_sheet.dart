import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../location/model/location_model.dart';
import '../model/filter_model.dart';
import '../repository/matching_repository.dart';

/// Represents a selectable location — either a saved one or a newly added area.
class _SelectableLocation {
  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;
  final double radiusKm;
  final bool isSaved;

  _SelectableLocation({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    this.radiusKm = 5.0,
    required this.isSaved,
  });

  factory _SelectableLocation.fromSaved(SavedLocation loc) {
    return _SelectableLocation(
      id: loc.locationId,
      name: loc.name,
      city: loc.city,
      lat: loc.lat,
      lng: loc.lng,
      radiusKm: loc.radiusKm,
      isSaved: true,
    );
  }

  factory _SelectableLocation.fromArea(Area area) {
    return _SelectableLocation(
      id: area.id,
      name: area.name,
      city: area.city,
      lat: area.latitude ?? 0,
      lng: area.longitude ?? 0,
      radiusKm: 5.0,
      isSaved: false,
    );
  }

  LocationOverride toOverride() {
    if (isSaved) {
      return LocationOverride.fromSaved(SavedLocation(
        locationId: id,
        name: name,
        city: city,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      ));
    }
    return LocationOverride.fromNew(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      name: name,
    );
  }
}

/// Opens the location filter bottom sheet.
///
/// [savedLocations] — seeker's saved preferred areas from match-filters API.
/// [currentOverrides] — currently active overrides (if any), to restore selection state.
/// [repository] — for browsing areas.
/// [onApply] — called with the list of location overrides (or null to reset).
void showLocationFilterSheet({
  required BuildContext context,
  required List<SavedLocation> savedLocations,
  required List<LocationOverride>? currentOverrides,
  required MatchingRepository repository,
  required ValueChanged<List<LocationOverride>?> onApply,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _LocationFilterSheetContent(
      savedLocations: savedLocations,
      currentOverrides: currentOverrides,
      repository: repository,
      onApply: (overrides) {
        onApply(overrides);
        Navigator.pop(ctx);
      },
    ),
  );
}

class _LocationFilterSheetContent extends StatefulWidget {
  final List<SavedLocation> savedLocations;
  final List<LocationOverride>? currentOverrides;
  final MatchingRepository repository;
  final ValueChanged<List<LocationOverride>?> onApply;

  const _LocationFilterSheetContent({
    required this.savedLocations,
    required this.currentOverrides,
    required this.repository,
    required this.onApply,
  });

  @override
  State<_LocationFilterSheetContent> createState() =>
      _LocationFilterSheetContentState();
}

class _LocationFilterSheetContentState
    extends State<_LocationFilterSheetContent> {
  late List<_SelectableLocation> _allLocations;
  late Set<String> _selectedIds;

  List<Area> _popularAreas = [];
  bool _loadingPopular = true;

  @override
  void initState() {
    super.initState();
    _initLocations();
    _loadPopularAreas();
  }

  void _initLocations() {
    _allLocations = widget.savedLocations
        .map((l) => _SelectableLocation.fromSaved(l))
        .toList();

    if (widget.currentOverrides != null) {
      _selectedIds = {};
      for (final ov in widget.currentOverrides!) {
        if (ov.locationId != null) {
          _selectedIds.add(ov.locationId!);
        } else if (ov.name != null) {
          final existing =
              _allLocations.where((l) => l.name == ov.name).firstOrNull;
          if (existing != null) {
            _selectedIds.add(existing.id);
          } else {
            final ephemeral = _SelectableLocation(
              id: 'new_${ov.name}',
              name: ov.name!,
              city: '',
              lat: ov.lat ?? 0,
              lng: ov.lng ?? 0,
              radiusKm: ov.radiusKm,
              isSaved: false,
            );
            _allLocations.add(ephemeral);
            _selectedIds.add(ephemeral.id);
          }
        }
      }
    } else {
      _selectedIds = _allLocations.map((l) => l.id).toSet();
    }
  }

  String get _city {
    for (final loc in widget.savedLocations) {
      if (loc.city.isNotEmpty) return loc.city;
    }
    return 'Bangalore';
  }

  Future<void> _loadPopularAreas() async {
    final areas = await widget.repository.browseAreas(_city);
    if (!mounted) return;
    final existingIds = _allLocations.map((l) => l.id).toSet();
    setState(() {
      _popularAreas = (areas.where((a) => !existingIds.contains(a.id)).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));
      _loadingPopular = false;
    });
  }

  void _addArea(Area area) {
    final selectable = _SelectableLocation.fromArea(area);
    setState(() {
      _allLocations.add(selectable);
      _selectedIds.add(selectable.id);
      _popularAreas.removeWhere((a) => a.id == area.id);
    });
  }

  void _toggleLocation(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool get _isDefault {
    final savedIds = widget.savedLocations.map((l) => l.locationId).toSet();
    return _selectedIds.length == savedIds.length &&
        savedIds.every((id) => _selectedIds.contains(id)) &&
        _allLocations.every((l) => l.isSaved || !_selectedIds.contains(l.id));
  }

  void _applySelection() {
    if (_isDefault) {
      widget.onApply(null);
      return;
    }
    final overrides = _allLocations
        .where((l) => _selectedIds.contains(l.id))
        .map((l) => l.toOverride())
        .toList();
    widget.onApply(overrides);
  }

  void _resetToDefault() {
    widget.onApply(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected / saved locations
                  if (_allLocations.isNotEmpty) ...[
                    Text(
                      'Your locations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectedChips(),
                  ],
                  const SizedBox(height: 20),
                  // All popular areas
                  Text(
                    'Add more areas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPopularAreaChips(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 20, color: AppColors.textDark),
          const SizedBox(width: 8),
          const Text(
            'Preferred Locations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (!_isDefault)
            GestureDetector(
              onTap: _resetToDefault,
              child: Text(
                'Reset',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.background,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allLocations.map((loc) {
        final isSelected = _selectedIds.contains(loc.id);
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
              if (!loc.isSaved) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected
                      ? Colors.white70
                      : AppColors.textDark.withOpacity(0.5),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.white,
          selectedColor: AppColors.textDark,
          checkmarkColor: Colors.white,
          side: BorderSide(color: AppColors.textDark.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) {
            if (!loc.isSaved && isSelected) {
              setState(() {
                _allLocations.remove(loc);
                _selectedIds.remove(loc.id);
              });
            } else {
              _toggleLocation(loc.id);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildPopularAreaChips() {
    if (_loadingPopular) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_popularAreas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'No additional areas available',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _popularAreas.map((area) {
        return GestureDetector(
          onTap: () => _addArea(area),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textDark.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: AppColors.background),
                const SizedBox(width: 4),
                Text(
                  area.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applySelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isDefault ? 'Keep Default' : 'Apply',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
