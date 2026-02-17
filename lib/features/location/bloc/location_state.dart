import '../model/location_model.dart';

/// Location States - Phase 4

abstract class LocationState {}

// =====================
// SEEKER Flow States
// =====================

/// Initial state
class LocationInitial extends LocationState {}

/// Loading areas
class LoadingAreas extends LocationState {}

/// Areas loaded, ready for selection
class AreasLoaded extends LocationState {
  final String city;
  final List<Area> areas;
  final List<Area> selectedAreas;
  final double searchRadiusKm;

  AreasLoaded({
    required this.city,
    required this.areas,
    List<Area>? selectedAreas,
    this.searchRadiusKm = 3.0,
  }) : selectedAreas = selectedAreas ?? [];

  AreasLoaded copyWith({
    String? city,
    List<Area>? areas,
    List<Area>? selectedAreas,
    double? searchRadiusKm,
  }) {
    return AreasLoaded(
      city: city ?? this.city,
      areas: areas ?? this.areas,
      selectedAreas: selectedAreas ?? this.selectedAreas,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    );
  }

  bool get hasSelections => selectedAreas.isNotEmpty;
}

/// Submitting preferred locations
class SubmittingPreferredLocations extends LocationState {}

/// Preferred locations saved successfully
class PreferredLocationsSaved extends LocationState {}

/// Finding matches (Frame 10 - "Finding your happy place" loading screen)
class FindingMatches extends LocationState {}

// =====================
// LISTER Flow States
// =====================

/// Ready for location input
class FlatLocationInput extends LocationState {
  final FlatLocation? location;

  FlatLocationInput({this.location});

  FlatLocationInput copyWith({FlatLocation? location}) {
    return FlatLocationInput(location: location ?? this.location);
  }

  bool get hasLocation => location != null;
}

/// Submitting draft flat
class SubmittingDraftFlat extends LocationState {}

/// Draft flat created successfully
class DraftFlatCreated extends LocationState {
  final DraftFlatResponse response;

  DraftFlatCreated(this.response);
}

// =====================
// Common Error State
// =====================

/// Error occurred
class LocationError extends LocationState {
  final String message;

  LocationError(this.message);
}
