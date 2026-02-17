import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../model/location_model.dart';
import '../repository/location_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

/// Location BLoC - Phase 4
/// 
/// Manages location selection state for both SEEKER and LISTER flows
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _repository;
  final String userRole; // "SEEKER" or "LISTER"

  LocationBloc({
    required ApiClient apiClient,
    required this.userRole,
  })  : _repository = LocationRepository(apiClient: apiClient),
        super(LocationInitial()) {
    // SEEKER flow events
    on<LoadAreasForCity>(_onLoadAreasForCity);
    on<ToggleAreaSelection>(_onToggleAreaSelection);
    on<SetSearchRadius>(_onSetSearchRadius);
    on<SubmitPreferredLocations>(_onSubmitPreferredLocations);
    on<SkipLocationSelection>(_onSkipLocationSelection);

    // LISTER flow events
    on<SetFlatLocation>(_onSetFlatLocation);
    on<ClearFlatLocation>(_onClearFlatLocation);
    on<SubmitDraftFlat>(_onSubmitDraftFlat);
    on<SkipFlatLocation>(_onSkipFlatLocation);

    _log('LocationBloc initialized for role: $userRole');
    
    // Initialize state based on role
    if (userRole == 'LISTER') {
      emit(FlatLocationInput());
    }
  }

  void _log(String message) {
    debugPrint('[LocationBloc] $message');
  }

  // =====================
  // SEEKER Flow Handlers
  // =====================

  Future<void> _onLoadAreasForCity(
    LoadAreasForCity event,
    Emitter<LocationState> emit,
  ) async {
    _log('Loading areas for city: ${event.city}');
    emit(LoadingAreas());

    try {
      final result = await _repository.getAreasForCity(event.city);

      if (result.isSuccess && result.data != null) {
        _log('✅ Loaded ${result.data!.areas.length} areas');
        emit(AreasLoaded(
          city: result.data!.city,
          areas: result.data!.areas,
        ));
      } else {
        _log('❌ Failed to load: ${result.errorMessage}');
        emit(LocationError(result.errorMessage ?? 'Failed to load areas'));
      }
    } catch (e) {
      _log('❌ Exception: $e');
      emit(LocationError('Failed to load areas: $e'));
    }
  }

  void _onToggleAreaSelection(
    ToggleAreaSelection event,
    Emitter<LocationState> emit,
  ) {
    if (state is AreasLoaded) {
      final currentState = state as AreasLoaded;
      final selectedAreas = List<Area>.from(currentState.selectedAreas);

      if (selectedAreas.any((a) => a.id == event.area.id)) {
        // Remove if already selected
        selectedAreas.removeWhere((a) => a.id == event.area.id);
      } else {
        // Add if not selected
        selectedAreas.add(event.area);
      }

      emit(currentState.copyWith(selectedAreas: selectedAreas));
    }
  }

  void _onSetSearchRadius(
    SetSearchRadius event,
    Emitter<LocationState> emit,
  ) {
    if (state is AreasLoaded) {
      final currentState = state as AreasLoaded;
      emit(currentState.copyWith(searchRadiusKm: event.radiusKm));
    }
  }

  Future<void> _onSubmitPreferredLocations(
    SubmitPreferredLocations event,
    Emitter<LocationState> emit,
  ) async {
    if (state is AreasLoaded) {
      final currentState = state as AreasLoaded;

      if (currentState.selectedAreas.isEmpty) {
        emit(LocationError('Please select at least one area'));
        emit(currentState);
        return;
      }

      _log('Submitting ${currentState.selectedAreas.length} preferred locations...');
      emit(SubmittingPreferredLocations());

      try {
        // Convert areas to preferred locations
        final preferredLocations = currentState.selectedAreas
            .map((area) {
              try {
                return PreferredLocation.fromArea(area);
              } catch (e) {
                _log('⚠️ Area ${area.name} missing coordinates, skipping');
                return null;
              }
            })
            .whereType<PreferredLocation>()
            .toList();

        if (preferredLocations.isEmpty) {
          emit(LocationError('Selected areas must have coordinates'));
          emit(currentState);
          return;
        }

        final request = PreferredLocationsRequest(
          locations: preferredLocations,
          searchRadiusKm: currentState.searchRadiusKm,
        );

        final result = await _repository.savePreferredLocations(request);

        if (result.isSuccess) {
          _log('✅ Preferred locations saved successfully');
          emit(PreferredLocationsSaved());
          // Transition to finding matches screen (Frame 10)
          // TODO: Replace with actual match finding API call
          // When API is ready, dispatch FindMatches event here instead of emitting FindingMatches directly
          // The FindMatches handler will call the API and emit MatchesFound or MatchesError states
          emit(FindingMatches());
        } else {
          _log('❌ Submit failed: ${result.errorMessage}');
          emit(LocationError(result.errorMessage ?? 'Failed to save locations'));
          emit(currentState);
        }
      } catch (e) {
        _log('❌ Exception during submit: $e');
        emit(LocationError('Failed to save: $e'));
        emit(currentState);
      }
    }
  }

  void _onSkipLocationSelection(
    SkipLocationSelection event,
    Emitter<LocationState> emit,
  ) {
    _log('User skipped location selection');
    emit(PreferredLocationsSaved()); // Treat skip as success for navigation
    // Transition to finding matches screen (Frame 10)
    emit(FindingMatches());
  }

  // =====================
  // LISTER Flow Handlers
  // =====================

  void _onSetFlatLocation(
    SetFlatLocation event,
    Emitter<LocationState> emit,
  ) {
    _log('Flat location set: ${event.locality}, ${event.city}');
    _log('Formatted address: ${event.formattedAddress}');

    final flatLocation = FlatLocation(
      location: event.location,
      locality: event.locality,
      city: event.city,
      pincode: event.pincode,
      formattedAddress: event.formattedAddress, // Store the full formatted address (sent as formatted_address to API)
    );

    emit(FlatLocationInput(location: flatLocation));
  }

  void _onClearFlatLocation(
    ClearFlatLocation event,
    Emitter<LocationState> emit,
  ) {
    _log('Clearing flat location');
    emit(FlatLocationInput());
  }

  Future<void> _onSubmitDraftFlat(
    SubmitDraftFlat event,
    Emitter<LocationState> emit,
  ) async {
    if (state is FlatLocationInput) {
      final currentState = state as FlatLocationInput;

      if (currentState.location == null) {
        emit(LocationError('Please select a location'));
        emit(currentState);
        return;
      }

      _log('Creating draft flat...');
      emit(SubmittingDraftFlat());

      try {
        final request = CreateDraftFlatRequest(
          location: currentState.location!,
        );

        final result = await _repository.createDraftFlat(request);

        if (result.isSuccess && result.data != null) {
          _log('✅ Draft flat created: ${result.data!.flatId}');
          emit(DraftFlatCreated(result.data!));
        } else {
          _log('❌ Create failed: ${result.errorMessage}');
          emit(LocationError(result.errorMessage ?? 'Failed to create draft flat'));
          emit(currentState);
        }
      } catch (e) {
        _log('❌ Exception during create: $e');
        emit(LocationError('Failed to create: $e'));
        emit(currentState);
      }
    }
  }

  void _onSkipFlatLocation(
    SkipFlatLocation event,
    Emitter<LocationState> emit,
  ) {
    _log('User skipped flat location');
    emit(DraftFlatCreated(DraftFlatResponse(
      message: 'Skipped',
      flatId: '',
      status: 'DRAFT',
      isActive: false,
    ))); // Treat skip as success for navigation
  }
}
