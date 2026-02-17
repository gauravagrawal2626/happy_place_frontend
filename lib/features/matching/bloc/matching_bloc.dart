/// Matching BLoC
/// 
/// Manages match fetching and filtering.
/// 
/// Features:
/// - Loads matches from API (role-based: SEEKER gets flats, LISTER gets seekers)
/// - Handles pagination
/// - Supports filtering
/// - Caches last request parameters for refresh

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/matching_repository.dart';
import 'matching_event.dart';
import 'matching_state.dart';

class MatchingBloc extends Bloc<MatchingEvent, MatchingState> {
  final MatchingRepository _repository;
  
  // Cache last request parameters for refresh
  LoadMatches? _lastRequest;

  MatchingBloc({required MatchingRepository repository})
      : _repository = repository,
        super(MatchingInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<RefreshMatches>(_onRefreshMatches);
    on<ApplyFilters>(_onApplyFilters);
    on<ResetMatches>(_onReset);
  }

  /// Load matches from API
  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchingState> emit,
  ) async {
    // Cache request for refresh
    _lastRequest = event;

    emit(MatchingLoading());

    try {
      final response = await _repository.getMatches(
        radiusKm: event.radiusKm,
        flatId: event.flatId,
        latitude: event.latitude,
        longitude: event.longitude,
        skip: event.skip,
        limit: event.limit,
        listingType: event.listingType,
        minRent: event.minRent,
        maxRent: event.maxRent,
      );

      emit(MatchingLoaded(
        response: response,
        type: response.type,
        total: response.total,
        radiusKm: event.radiusKm,
        locationsSearched: response.locationsSearched,
      ));
    } catch (e) {
      emit(MatchingError(
        message: e.toString(),
      ));
    }
  }

  /// Refresh matches with last request parameters
  Future<void> _onRefreshMatches(
    RefreshMatches event,
    Emitter<MatchingState> emit,
  ) async {
    if (_lastRequest == null) {
      emit(MatchingError(message: 'No previous request to refresh'));
      return;
    }

    // Reload with same parameters
    add(_lastRequest!);
  }

  /// Apply filters to existing matches
  void _onApplyFilters(
    ApplyFilters event,
    Emitter<MatchingState> emit,
  ) {
    final currentState = state;
    if (currentState is MatchingLoaded && _lastRequest != null) {
      // Reload with new filters
      add(LoadMatches(
        radiusKm: _lastRequest!.radiusKm,
        flatId: _lastRequest!.flatId,
        latitude: _lastRequest!.latitude,
        longitude: _lastRequest!.longitude,
        skip: _lastRequest!.skip,
        limit: _lastRequest!.limit,
        listingType: event.listingType ?? _lastRequest!.listingType,
        minRent: event.minRent ?? _lastRequest!.minRent,
        maxRent: event.maxRent ?? _lastRequest!.maxRent,
      ));
    }
  }

  /// Reset state
  void _onReset(
    ResetMatches event,
    Emitter<MatchingState> emit,
  ) {
    _lastRequest = null;
    emit(MatchingInitial());
  }
}
