import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/action_buttons_row.dart';
import '../../../shared/widgets/account_modal.dart';
import '../../../shared/widgets/profile_modal.dart';
import '../bloc/matching_bloc.dart';
import '../bloc/matching_event.dart';
import '../bloc/matching_state.dart';
import '../model/filter_model.dart';
import '../model/match_model.dart';
import '../widgets/match_filter_chips.dart';
import '../widgets/question_filter_sheet.dart';

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
        // Parallel: load matches + load filter config
        bloc.add(LoadMatches(radiusKm: 5.0));
        bloc.add(LoadMatchFilters());
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
  List<QuestionFilter> _questionFilters = [];
  Map<String, String> _activeFilters = {};

  /// Re-dispatch both LoadMatches and LoadMatchFilters, reset active filters.
  void _reloadAll(BuildContext context) {
    setState(() {
      _questionFilters = [];
      _activeFilters = {};
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

        // Build filter items only for values that differ from defaults
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
              ));
        } else {
          // All filters back to default — use normal GET
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
            // Initialize active filters from currentValue defaults
            _activeFilters = {};
            for (final f in _questionFilters) {
              if (f.currentValue != null) {
                _activeFilters[f.id] = f.currentValue!;
              }
            }
          });
        }
      },
      buildWhen: (prev, curr) => curr is! MatchFiltersLoaded,
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
                      
                      // Dynamic question filter chips
                      MatchFilterChips(
                        filters: _questionFilters,
                        activeValues: _activeFilters,
                        onFilterTap: _onFilterChipTapped,
                      ),
                      
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
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                    child: ActionButtonsRow(
                      leftButtonText: 'Flatmate Preference',
                      rightButtonText: 'Add Flat Details',
                      onLeftPressed: () async {
                        unawaited(
                          context.read<AnalyticsFacade>().button(
                                AnalyticsButtonNames.mapFlatmatePreference,
                                screenName: AnalyticsScreenNames.listerList,
                              ),
                        );
                        await context.push('/preferences/edit');
                        if (mounted) _reloadAll(context);
                      },
                      onRightPressed: () async {
                        unawaited(
                          context.read<AnalyticsFacade>().button(
                                AnalyticsButtonNames.mapAddFlatDetails,
                                screenName: AnalyticsScreenNames.listerList,
                              ),
                        );
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
                    onResultsTap: () {
                      unawaited(
                        context.read<AnalyticsFacade>().button(
                              AnalyticsButtonNames.bottomNavSearchResults,
                              screenName: AnalyticsScreenNames.listerList,
                            ),
                      );
                    },
                    onAccountTap: () {
                      unawaited(
                        context.read<AnalyticsFacade>().button(
                              AnalyticsButtonNames.bottomNavAccount,
                              screenName: AnalyticsScreenNames.listerList,
                            ),
                      );
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
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
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
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: flatmate.matchScore / 100,
                          strokeWidth: 3.5,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: flatmate.imageUrl != null
                            ? NetworkImage(flatmate.imageUrl!)
                            : null,
                        child: flatmate.imageUrl == null
                            ? Icon(Icons.person, size: 36, color: Colors.white.withOpacity(0.5))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${flatmate.matchScore.round()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  flatmate.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (flatmate.tagline != null && flatmate.tagline!.isNotEmpty)
                  Text(
                    flatmate.tagline!,
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
    ),
    );
  }
}
