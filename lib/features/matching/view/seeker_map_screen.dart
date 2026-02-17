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
        // Load matches for SEEKER (uses preferred locations)
        bloc.add(LoadMatches(
          radiusKm: 5.0, // Default radius
          // latitude/longitude: null (uses preferred locations from backend)
        ));
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
  
  // Callback function to recenter the map
  VoidCallback? _recenterMap;
  
  // Filter states
  bool _vegetarianFilter = false;
  bool _nonSmokerFilter = false;
  bool _tokenPrinted = false;

  // User location (mock - will use actual location later)
  final latlong2.LatLng _userLocation = latlong2.LatLng(12.9352, 77.6245); // Koramangala center

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchingBloc, MatchingState>(
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
            top: 110, // Below header with gap (accounting for SafeArea)
            left: 0,
            right: 0,
            child: _buildFilterChips(),
          ),
          
          // Recenter button (above action buttons)
          if (_recenterMap != null)
            Positioned(
              right: 20,
              bottom: 100, // Position above the action buttons row
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    // Recenter map to initial position and zoom
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
            ),
          
          // Action buttons row (above bottom nav)
          Positioned(
            left: 20,
            right: 20,
            bottom: 0, // Positioned at bottom, SafeArea will handle spacing
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12), // Small gap above bottom nav
                child: ActionButtonsRow(
                leftButtonText: 'Flatmate Preference',
                rightButtonText: 'Add Flat Details',
                onLeftPressed: () {
                  context.push('/preferences/edit');
                },
                onRightPressed: () {
                  context.push('/flat-requirements', extra: true); // isLister: true
                },
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom navigation bar
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0, // Search results selected (seeker is on map view)
        onResultsTap: () {
          // Already on search results (map view) - no action needed
        },
        onAccountTap: () {
          // Show account modal
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AccountModalWithBlur(),
          );
        },
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 12, right: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Vegetarian',
              icon: Icons.eco,
              isSelected: _vegetarianFilter,
              onTap: () {
                setState(() {
                  _vegetarianFilter = !_vegetarianFilter;
                });
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Non-Smoker',
              icon: Icons.smoking_rooms,
              isSelected: _nonSmokerFilter,
              onTap: () {
                setState(() {
                  _nonSmokerFilter = !_nonSmokerFilter;
                });
              },
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'More',
              icon: Icons.tune,
              isSelected: false,
              onTap: () {
                // TODO: Show more filters (Phase 5)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More filters - Coming in Phase 5')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.background : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textDark,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
