import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/action_buttons_row.dart';
import '../../../shared/widgets/account_modal.dart';
import '../../../shared/widgets/profile_modal.dart';
import '../../home/widgets/real_map_widget.dart';
import '../../profile/repository/profile_repository.dart';
import '../../profile/repository/requests_repository.dart';
import '../bloc/matching_bloc.dart';
import '../bloc/matching_event.dart';
import '../bloc/matching_state.dart';
import '../model/filter_model.dart';
import '../repository/matching_repository.dart';
import '../widgets/location_filter_sheet.dart';
import '../widgets/match_filter_chips.dart';
import '../widgets/question_filter_sheet.dart';

/// Seeker Map Screen - Frame 11
/// 
/// Shows map with nearby flats for SEEKER users
/// - Map with flat markers showing match percentages
/// - Filter chips (Vegetarian, Non-Smoker, More)
/// - Header with match count
/// - Action buttons at bottom
class SeekerMapScreen extends StatelessWidget {
  const SeekerMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = MatchingBloc(
          repository: context.read(),
        );
        // Parallel: load matches + load filter config
        bloc.add(LoadMatches(radiusKm: 5.0));
        bloc.add(LoadMatchFilters());
        return bloc;
      },
      child: const _SeekerMapContent(),
    );
  }
}

class _SeekerMapContent extends StatefulWidget {
  const _SeekerMapContent();

  @override
  State<_SeekerMapContent> createState() => _SeekerMapScreenState();
}

class _SeekerMapScreenState extends State<_SeekerMapContent> {
  final double _radiusKm = 5.0;
  
  VoidCallback? _recenterMap;
  bool _tokenPrinted = false;

  List<QuestionFilter> _questionFilters = [];
  Map<String, String> _activeFilters = {};

  LocationFilter? _locationFilter;
  List<LocationOverride>? _activeLocationOverrides;
  bool _locationChanged = false;

  final latlong2.LatLng _userLocation = latlong2.LatLng(12.9352, 77.6245);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tokenPrinted) {
      _tokenPrinted = true;
      _printAuthToken();
    }
  }

  Future<void> _printAuthToken() async {
    final secureStorage = SecureStorage.instance;
    final token = await secureStorage.getAccessToken();
    print('═══════════════════════════════════════════════════════════');
    print('🔑 AUTH TOKEN:');
    print('═══════════════════════════════════════════════════════════');
    print(token ?? 'No token found');
    print('═══════════════════════════════════════════════════════════');
  }

  void _reloadAll(BuildContext context) {
    setState(() {
      _questionFilters = [];
      _activeFilters = {};
      _locationFilter = null;
      _activeLocationOverrides = null;
      _locationChanged = false;
    });
    final bloc = context.read<MatchingBloc>();
    bloc.add(LoadMatches(radiusKm: 5.0));
    bloc.add(LoadMatchFilters());
  }

  void _onFilterChipTapped(QuestionFilter filter) {
    showQuestionFilterSheet(
      context: context,
      filter: filter,
      currentSelection: _activeFilters[filter.id],
      onSelected: (value) {
        setState(() {
          if (value == null) {
            _activeFilters.remove(filter.id);
          } else {
            _activeFilters[filter.id] = value;
          }
        });

        final changedFilters = <FilterItem>[];
        for (final entry in _activeFilters.entries) {
          final q = _questionFilters.firstWhere((f) => f.id == entry.key,
              orElse: () => filter);
          if (entry.value != q.currentValue) {
            changedFilters.add(FilterItem(id: entry.key, value: entry.value));
          }
        }

        if (changedFilters.isNotEmpty) {
          context.read<MatchingBloc>().add(PostFilteredMatches(
                radiusKm: 5.0,
                filters: changedFilters,
                locationOverrides: _activeLocationOverrides,
              ));
        } else if (_locationChanged && _activeLocationOverrides != null) {
          context.read<MatchingBloc>().add(PostFilteredMatches(
                radiusKm: 5.0,
                filters: [],
                locationOverrides: _activeLocationOverrides,
              ));
        } else {
          context.read<MatchingBloc>().add(LoadMatches(radiusKm: 5.0));
        }
      },
    );
  }

  void _onLocationChipTapped() {
    if (_locationFilter == null) return;
    final repo = context.read<MatchingRepository>();
    showLocationFilterSheet(
      context: context,
      savedLocations: _locationFilter!.savedLocations,
      currentOverrides: _activeLocationOverrides,
      repository: repo,
      onApply: (overrides) {
        setState(() {
          _activeLocationOverrides = overrides;
          _locationChanged = overrides != null;
        });

        // Build question filter items for this request
        final changedFilters = <FilterItem>[];
        for (final entry in _activeFilters.entries) {
          final q = _questionFilters.firstWhere((f) => f.id == entry.key,
              orElse: () => _questionFilters.first);
          if (entry.value != q.currentValue) {
            changedFilters.add(FilterItem(id: entry.key, value: entry.value));
          }
        }

        if (overrides != null || changedFilters.isNotEmpty) {
          context.read<MatchingBloc>().add(PostFilteredMatches(
                radiusKm: 5.0,
                filters: changedFilters,
                locationOverrides: overrides,
              ));
        } else {
          context.read<MatchingBloc>().add(LoadMatches(radiusKm: 5.0));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchingBloc, MatchingState>(
      listener: (context, state) {
        if (state is MatchFiltersLoaded) {
          setState(() {
            _questionFilters = state.filtersResponse.questionFilters;
            _activeFilters = {};
            for (final f in _questionFilters) {
              if (f.currentValue != null) {
                _activeFilters[f.id] = f.currentValue!;
              }
            }
            _locationFilter = state.filtersResponse.locationFilter;
            _activeLocationOverrides = null;
            _locationChanged = false;
          });
        }
      },
      buildWhen: (prev, curr) => curr is! MatchFiltersLoaded,
      builder: (context, state) {
        // Get flats from state or use empty list
        final flats = state is MatchingLoaded && state.type == 'flats'
            ? state.flats.map((f) => f.toFlatListing()).toList()
            : <FlatListing>[];
        
        // Debug logging
        if (state is MatchingLoaded && state.type == 'flats') {
          print('═══════════════════════════════════════════════════════════');
          print('🗺️ SEEKER MAP - Flats loaded:');
          print('Total flats: ${flats.length}');
          for (var i = 0; i < flats.length; i++) {
            final flat = flats[i];
            print('Flat $i: ${flat.name}');
            print('  Location: ${flat.location.latitude}, ${flat.location.longitude}');
            print('  Address: ${flat.address}');
            print('  Match: ${flat.matchPercentage}%');
          }
          print('═══════════════════════════════════════════════════════════');
        }
        
        final totalMatches = state is MatchingLoaded ? state.total : 0;
        final isLoading = state is MatchingLoading;
        final hasError = state is MatchingError;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          // Full screen map - takes entire screen
          SizedBox.expand(
            child: RealMapWidget(
              city: 'Bangalore',
              preference: 'Vegetarian',
                  userLocation: null, // No current location for seeker (based on preferred locations)
                  flats: flats,
              radiusKm: _radiusKm,
                  showRadiusCircle: false, // No radius circle for seeker
              onModifyPreferences: null,
              onAddFlatDetails: null,
                  onRecenterReady: (recenterFn) {
                    setState(() {
                      _recenterMap = recenterFn;
                    });
                  },
                  onFlatTapped: (flat) {
                    debugPrint('[SeekerMap] onFlatTapped: flat.id=${flat.id} flat.ownerId=${flat.ownerId}');
                    if (flat.ownerId == null || flat.ownerId!.isEmpty) {
                      debugPrint('[SeekerMap] Skipping ProfileModal - no ownerId');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile not available for this flat'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    debugPrint('[SeekerMap] Showing ProfileModal userId=${flat.ownerId} flatId=${flat.id}');
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ProfileModal(
                        args: ProfileModalArgs(
                          userId: flat.ownerId!,
                          flatId: flat.id,
                          role: ProfileModalRole.seeker,
                          matchScore: flat.matchPercentage.toDouble(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              
              // Error overlay
              if (hasError && flats.isEmpty)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          (state as MatchingError).message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MatchingBloc>().add(RefreshMatches());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Overlay header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
                child: _buildTopBar(totalMatches),
          ),
          
          // Overlay filter chips
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: MatchFilterChips(
              filters: _questionFilters,
              activeValues: _activeFilters,
              onFilterTap: _onFilterChipTapped,
              locationFilter: _locationFilter,
              locationChanged: _locationChanged,
              onLocationTap: _onLocationChipTapped,
            ),
          ),
          
          if (_recenterMap != null)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 180,
              child: GestureDetector(
                onTap: () {
                  _recenterMap?.call();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.textDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: ActionButtonsRow(
              leftButtonText: 'Flatmate Preference',
              rightButtonText: 'Add Flat Details',
              onLeftPressed: () async {
                await context.push('/preferences/edit');
                if (mounted) _reloadAll(context);
              },
              onRightPressed: () async {
                await context.push('/flat-requirements', extra: true);
                if (mounted) _reloadAll(context);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              currentIndex: 0,
              onResultsTap: () {},
              onAccountTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AccountModalWithBlur(),
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTopBar(int totalMatches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background, // Light blue/teal header
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$totalMatches potential flatmates found within 5 kms',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // X close button
            GestureDetector(
              onTap: () {
                // Close/dismiss - could navigate back or show options
                context.pop();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
