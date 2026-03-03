import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/action_buttons_row.dart';
import '../../../shared/widgets/account_modal.dart';
import '../../../shared/widgets/profile_modal.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/storage/secure_storage.dart';
import '../bloc/matching_bloc.dart';
import '../bloc/matching_event.dart';
import '../bloc/matching_state.dart';
import '../model/match_model.dart';

/// Lister List Screen - Frame 48
/// 
/// Shows list of people looking for flats (for LISTER users)
/// - Header with count and action icons
/// - Filter chips (Vegetarian, Non-smoker, More)
/// - Grid of potential flatmate cards
/// - Floating action buttons at bottom
class ListerListScreen extends StatelessWidget {
  const ListerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = MatchingBloc(
          repository: context.read(),
        );
        // Load matches for LISTER (auto-selects latest flat)
        bloc.add(LoadMatches(
          radiusKm: 5.0, // Default radius
          // flatId: null (auto-selects latest active flat)
        ));
        return bloc;
      },
      child: const _ListerListContent(),
    );
  }
}

class _ListerListContent extends StatefulWidget {
  const _ListerListContent();

  @override
  State<_ListerListContent> createState() => _ListerListScreenState();
}

class _ListerListScreenState extends State<_ListerListContent> {
  // Filter states
  final List<String> _selectedFilters = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchingBloc, MatchingState>(
      builder: (context, state) {
        // Get flatmates from state or use empty list
        final flatmates = state is MatchingLoaded && state.type == 'seekers'
            ? state.flatmates
            : <FlatmateMatch>[];
        
        final totalMatches = state is MatchingLoaded ? state.total : 0;
        final isLoading = state is MatchingLoading;
        final hasError = state is MatchingError;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
              children: [
                // Loading overlay
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                
                // Error overlay
                if (hasError && flatmates.isEmpty)
                  Container(
                    color: AppColors.background,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            (state as MatchingError).message,
                            style: const TextStyle(color: Colors.white),
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
                
                // Main content - scrollable grid
                if (!isLoading && !hasError)
                  Column(
                    children: [
                      // Header
                      _buildHeader(context, totalMatches),
                      
                      // Filter chips
                      _buildFilterChips(),
                      
                      // Grid of flatmates
                      Expanded(
                        child: _buildFlatmatesGrid(flatmates),
                      ),
                    ],
                  ),
                
                // Action buttons row (above bottom nav)
                if (!isLoading && !hasError)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 110,
                    child: ActionButtonsRow(
                      leftButtonText: 'Flatmate Preference',
                      rightButtonText: 'Add Flat Details',
                      onLeftPressed: () {
                        context.push('/preferences/edit');
                      },
                      onRightPressed: () {
                        context.push('/flat-requirements', extra: true);
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

  Widget _buildHeader(BuildContext context, int totalMatches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              '$totalMatches potential flatmates found within 5 kms',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'icon': Icons.eco_outlined, 'label': 'Vegetarian'},
      {'icon': Icons.smoke_free, 'label': 'Non-smoker'},
      {'icon': Icons.tune, 'label': 'More'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilters.contains(filter['label']);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: AppColors.textDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter['label'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                selectedColor: AppColors.background,
                side: const BorderSide(color: AppColors.textDark, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilters.add(filter['label'] as String);
                    } else {
                      _selectedFilters.remove(filter['label']);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFlatmatesGrid(List<FlatmateMatch> flatmates) {
    if (flatmates.isEmpty) {
      return const Center(
        child: Text(
          'No flatmates found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100), // Bottom padding for buttons
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: flatmates.length,
      itemBuilder: (context, index) {
        final flatmate = flatmates[index];
        return _buildFlatmateCard(flatmate);
      },
    );
  }

  Widget _buildFlatmateCard(FlatmateMatch flatmate) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProfileModal(
            args: ProfileModalArgs(
              userId: flatmate.userId,
              flatId: flatmate.flatId,
              role: ProfileModalRole.lister,
              matchScore: flatmate.matchScore,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Image placeholder with icon
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColors.background.withOpacity(0.3),
                child: Stack(
                  children: [
                    // Center icon
                    Center(
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    // Bottom section
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                    // Info section at bottom
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flatmate.age != null ? '${flatmate.age},' : flatmate.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            flatmate.tagline ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Match percentage badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${flatmate.matchScore.round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
