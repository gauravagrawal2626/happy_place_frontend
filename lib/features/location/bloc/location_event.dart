import '../model/location_model.dart';

/// Location Events - Phase 4

abstract class LocationEvent {}

// =====================
// SEEKER Flow Events
// =====================

/// Load areas for a city
class LoadAreasForCity extends LocationEvent {
  final String city;

  LoadAreasForCity(this.city);
}

/// Toggle area selection (add/remove)
class ToggleAreaSelection extends LocationEvent {
  final Area area;

  ToggleAreaSelection(this.area);
}

/// Set search radius
class SetSearchRadius extends LocationEvent {
  final double radiusKm;

  SetSearchRadius(this.radiusKm);
}

/// Submit preferred locations
class SubmitPreferredLocations extends LocationEvent {}

/// Skip location selection
class SkipLocationSelection extends LocationEvent {}

// =====================
// LISTER Flow Events
// =====================

/// Set flat location from Google Places
class SetFlatLocation extends LocationEvent {
  final GeoLocation location;
  final String locality;
  final String city;
  final String pincode;
  final String? formattedAddress;

  SetFlatLocation({
    required this.location,
    required this.locality,
    required this.city,
    required this.pincode,
    this.formattedAddress,
  });
}

/// Submit draft flat location
class SubmitDraftFlat extends LocationEvent {}

/// Clear flat location (reset to input state)
class ClearFlatLocation extends LocationEvent {}

/// Skip flat location
class SkipFlatLocation extends LocationEvent {}
