/// Matching States
/// 
/// States for match fetching and display

import '../model/filter_model.dart';
import '../model/match_model.dart';

abstract class MatchingState {}

/// Initial state
class MatchingInitial extends MatchingState {}

/// Loading matches
class MatchingLoading extends MatchingState {}

/// Matches loaded successfully
class MatchingLoaded extends MatchingState {
  final MatchResponse response;
  final List<FlatMatch> flats; // For SEEKER
  final List<FlatmateMatch> flatmates; // For LISTER
  final String type; // "flats" or "seekers"
  final int total;
  final double radiusKm;
  final int? locationsSearched; // For SEEKER only

  MatchingLoaded({
    required this.response,
    required this.type,
    required this.total,
    required this.radiusKm,
    this.locationsSearched,
  })  : flats = type == 'flats' ? response.flats : [],
        flatmates = type == 'seekers' ? response.flatmates : [];

  /// Get match count
  int get matchCount => type == 'flats' ? flats.length : flatmates.length;
}

/// Error state
class MatchingError extends MatchingState {
  final String message;
  final MatchingLoaded? previousState;

  MatchingError({
    required this.message,
    this.previousState,
  });
}

/// Match filters loaded from GET /api/flats/match-filters
class MatchFiltersLoaded extends MatchingState {
  final MatchFiltersResponse filtersResponse;

  MatchFiltersLoaded({required this.filtersResponse});
}
