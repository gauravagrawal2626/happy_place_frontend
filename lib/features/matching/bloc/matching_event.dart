/// Matching Events
/// 
/// Events for fetching and managing matches

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
