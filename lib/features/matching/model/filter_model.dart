/// Match Filter Models
///
/// Data models for GET /api/flats/match-filters response
/// and POST /api/flats/matches filter request body.
///
/// Reuses QuestionOption, SubOption, UiConfig from onboarding models.

import '../../onboarding/model/question_model.dart';

/// A single question-based filter from the match-filters API.
class QuestionFilter {
  final String id;
  final String fieldName;
  final String primaryText;
  final String? text;
  final String type;
  final String? questionSet;
  final List<QuestionOption> options;
  final UiConfig uiConfig;
  final String? currentValue;

  QuestionFilter({
    required this.id,
    required this.fieldName,
    required this.primaryText,
    this.text,
    required this.type,
    this.questionSet,
    required this.options,
    required this.uiConfig,
    this.currentValue,
  });

  factory QuestionFilter.fromJson(Map<String, dynamic> json) {
    return QuestionFilter(
      id: json['_id'] as String,
      fieldName: json['field_name'] as String? ?? '',
      primaryText: json['primary_text'] as String? ?? json['text'] as String? ?? '',
      text: json['text'] as String?,
      type: json['type'] as String? ?? '',
      questionSet: json['question_set'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => QuestionOption.fromJson(opt as Map<String, dynamic>))
              .toList() ??
          [],
      uiConfig: UiConfig.fromJson(json['ui_config'] as Map<String, dynamic>?),
      currentValue: json['current_value'] as String?,
    );
  }

  /// Find the display label for a given option/sub-option id.
  String? labelForValue(String? value) {
    if (value == null) return null;
    for (final opt in options) {
      if (opt.id == value) return opt.text;
      if (opt.subOptions != null) {
        for (final sub in opt.subOptions!) {
          if (sub.id == value) return sub.text;
        }
      }
    }
    return null;
  }

  /// Label for the filter chip — shows the parent option text even when
  /// a sub-option is selected (e.g. "Vegetarian" instead of "I eat eggs only").
  String? chipLabelForValue(String? value) {
    if (value == null) return null;
    for (final opt in options) {
      if (opt.id == value) return opt.text;
      if (opt.subOptions != null) {
        for (final sub in opt.subOptions!) {
          if (sub.id == value) return opt.text;
        }
      }
    }
    return null;
  }

  /// Find the parent option id for a given sub-option id.
  String? parentIdForValue(String? value) {
    if (value == null) return null;
    for (final opt in options) {
      if (opt.id == value) return null;
      if (opt.subOptions != null) {
        for (final sub in opt.subOptions!) {
          if (sub.id == value) return opt.id;
        }
      }
    }
    return null;
  }
}

/// A saved preferred location from the match-filters API.
class SavedLocation {
  final String locationId;
  final String name;
  final String city;
  final double lat;
  final double lng;
  final double radiusKm;

  SavedLocation({
    required this.locationId,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      locationId: json['location_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

/// Wraps the location_filter section of the match-filters response (seeker-only).
class LocationFilter {
  final List<SavedLocation> savedLocations;

  LocationFilter({required this.savedLocations});

  factory LocationFilter.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LocationFilter(savedLocations: []);
    return LocationFilter(
      savedLocations: (json['saved_locations'] as List<dynamic>?)
              ?.map((l) => SavedLocation.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A location override for the POST /api/flats/matches request body.
/// Either references a saved location by id, or specifies new coordinates.
class LocationOverride {
  final String? locationId;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? name;

  LocationOverride._({
    this.locationId,
    this.lat,
    this.lng,
    required this.radiusKm,
    this.name,
  });

  /// From a saved preferred location (uses location_id).
  factory LocationOverride.fromSaved(SavedLocation loc) {
    return LocationOverride._(
      locationId: loc.locationId,
      radiusKm: loc.radiusKm,
    );
  }

  /// From a new ephemeral area (uses lat/lng).
  factory LocationOverride.fromNew({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    String? name,
  }) {
    return LocationOverride._(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    if (locationId != null) {
      return {'location_id': locationId, 'radius_km': radiusKm};
    }
    return {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
      if (name != null) 'name': name,
    };
  }
}

/// Response from GET /api/flats/match-filters.
class MatchFiltersResponse {
  final List<QuestionFilter> questionFilters;
  final LocationFilter? locationFilter;

  MatchFiltersResponse({
    required this.questionFilters,
    this.locationFilter,
  });

  factory MatchFiltersResponse.fromJson(Map<String, dynamic> json) {
    final locFilterJson = json['location_filter'] as Map<String, dynamic>?;
    return MatchFiltersResponse(
      questionFilters: (json['question_filters'] as List<dynamic>?)
              ?.map((q) => QuestionFilter.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      locationFilter:
          locFilterJson != null ? LocationFilter.fromJson(locFilterJson) : null,
    );
  }
}

/// A single filter item for the POST /api/flats/matches request body.
class FilterItem {
  final String id;
  final dynamic value;

  FilterItem({required this.id, required this.value});

  Map<String, dynamic> toJson() => {'id': id, 'value': value};
}
