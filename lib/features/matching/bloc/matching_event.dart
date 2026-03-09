/// Matching Events
/// 
/// Events for fetching and managing matches

import '../model/filter_model.dart';

abstract class MatchingEvent {}

/// Load matches
class LoadMatches extends MatchingEvent {
  final double radiusKm; // Required: 0.5-20
  final String? flatId; // Optional: For LISTER
  final double? latitude; // Optional: For SEEKER
  final double? longitude; // Optional: For SEEKER
  final int skip; // Pagination offset
  final int limit; // Results per page
  final String? listingType; // Filter
  final double? minRent; // Filter
  final double? maxRent; // Filter

  LoadMatches({
    required this.radiusKm,
    this.flatId,
    this.latitude,
    this.longitude,
    this.skip = 0,
    this.limit = 20,
    this.listingType,
    this.minRent,
    this.maxRent,
  });
}

/// Refresh matches (reload with same parameters)
class RefreshMatches extends MatchingEvent {}

/// Apply filters to existing matches
class ApplyFilters extends MatchingEvent {
  final String? listingType;
  final double? minRent;
  final double? maxRent;

  ApplyFilters({
    this.listingType,
    this.minRent,
    this.maxRent,
  });
}

/// Reset matching state
class ResetMatches extends MatchingEvent {}

/// Load available question-based filters from GET /api/flats/match-filters
class LoadMatchFilters extends MatchingEvent {}

/// Post filtered matches via POST /api/flats/matches
class PostFilteredMatches extends MatchingEvent {
  final double radiusKm;
  final String? flatId;
  final List<FilterItem> filters;
  final List<LocationOverride>? locationOverrides;
  final int skip;
  final int limit;

  PostFilteredMatches({
    required this.radiusKm,
    this.flatId,
    required this.filters,
    this.locationOverrides,
    this.skip = 0,
    this.limit = 20,
  });
}
