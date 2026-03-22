/// Finding Matches Screen
/// 
/// Generic loading screen shown after:
/// - Location selection (SEEKER/LISTER)
/// - Flat details update (SEEKER/LISTER)
/// 
/// Shows "Finding your happy place" with spinner
/// After delay (or API call), navigates to appropriate destination

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../bloc/matching_bloc.dart';
import '../bloc/matching_event.dart';
import '../bloc/matching_state.dart';

/// Source of navigation to this screen
enum FindingMatchesSource {
  locationSeeker,   // After SEEKER selects preferred areas
  locationLister,   // After LISTER adds flat location
  flatDetailsSeeker, // After SEEKER updates flat preferences
  flatDetailsLister, // After LISTER updates flat details
}

class FindingMatchesScreen extends StatelessWidget {
  final FindingMatchesSource source;

  const FindingMatchesScreen({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = MatchingBloc(
          repository: context.read(),
        );
        // Don't load matches here - let _FindingMatchesContent handle it
        // This ensures we wait for any save operations to complete first
        return bloc;
      },
      child: _FindingMatchesContent(source: source),
    );
  }
}

class _FindingMatchesContent extends StatefulWidget {
  final FindingMatchesSource source;

  const _FindingMatchesContent({required this.source});

  @override
  State<_FindingMatchesContent> createState() => _FindingMatchesScreenState();
}

/// How navigation from [FindingMatchesScreen] was triggered (for analytics).
enum _FindingMatchesNavTrigger { auto, userSkip, userContinueAnyway }

class _FindingMatchesScreenState extends State<_FindingMatchesContent> {
  bool _isNavigating = false;
  bool _waitingForOnboardingUpdate = false;

  @override
  void initState() {
    super.initState();
    _startMatchFinding();
  }

  void _startMatchFinding() {
    // Small delay to ensure backend has processed the saved preferences/flat details
    // This ensures the matches API uses the latest saved data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // Determine if SEEKER or LISTER based on source
      final isLister = widget.source == FindingMatchesSource.locationLister ||
          widget.source == FindingMatchesSource.flatDetailsLister;

      // Load matches via BLoC
      // For SEEKER: Uses preferred locations (no lat/lng needed)
      // For LISTER: Auto-selects latest flat (no flat_id needed)
      context.read<MatchingBloc>().add(LoadMatches(
        radiusKm: 5.0, // Default radius
        // flatId: null for LISTER (auto-selects)
        // latitude/longitude: null for SEEKER (uses preferred locations)
      ));
    });
  }

  /// [trigger] is `auto` when matches loaded successfully (no button event).
  /// Use `userSkip` / `userContinueAnyway` only for explicit taps.
  void _navigateToDestination(
      [_FindingMatchesNavTrigger trigger = _FindingMatchesNavTrigger.auto]) {
    if (_isNavigating) return;

    switch (trigger) {
      case _FindingMatchesNavTrigger.userSkip:
        unawaited(
          context.read<AnalyticsFacade>().button(
                AnalyticsButtonNames.findingMatchesSkip,
                screenName: AnalyticsScreenNames.findingMatches,
              ),
        );
        break;
      case _FindingMatchesNavTrigger.userContinueAnyway:
        unawaited(
          context.read<AnalyticsFacade>().button(
                AnalyticsButtonNames.findingMatchesContinueAnyway,
                screenName: AnalyticsScreenNames.findingMatches,
              ),
        );
        break;
      case _FindingMatchesNavTrigger.auto:
        break;
    }

    // If coming from location flow, mark onboarding as complete
    // Then wait for state update before navigating to avoid router redirect race condition
    if (widget.source == FindingMatchesSource.locationSeeker ||
        widget.source == FindingMatchesSource.locationLister) {
      _waitingForOnboardingUpdate = true;
      context.read<AppBloc>().add(const AppOnboardingCompleted());
      // Navigation will happen in BlocListener when state updates
    } else {
      // Not from location flow, navigate immediately
      _performNavigation();
    }
  }

  void _performNavigation() {
    if (_isNavigating) return;
    _isNavigating = true;

    // Navigate based on source action, not user's stored role
    // This handles cases where a SEEKER adds flat details (acting as LISTER)
    // or a LISTER modifies preferences (acting as SEEKER)
    switch (widget.source) {
      case FindingMatchesSource.locationLister:
      case FindingMatchesSource.flatDetailsLister:
        // LISTER actions → go to list screen (shows potential flatmates)
        context.go('/list/lister');
        break;
      case FindingMatchesSource.locationSeeker:
      case FindingMatchesSource.flatDetailsSeeker:
        // SEEKER actions → go to map screen (shows flats on map)
        context.go('/map/seeker');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listener: (context, appState) {
        // Wait for onboarding completion state update before navigating
        if (_waitingForOnboardingUpdate && appState is AppAuthenticated) {
          if (appState.onboardingCompleted) {
            _waitingForOnboardingUpdate = false;
            // State updated, now safe to navigate
            if (!_isNavigating) {
              _performNavigation();
            }
          }
        }
      },
      child: BlocListener<MatchingBloc, MatchingState>(
        listener: (context, state) {
          if (state is MatchingLoaded) {
            // Matches loaded successfully, navigate to destination
            if (!_isNavigating && !_waitingForOnboardingUpdate) {
              _navigateToDestination();
            }
          } else if (state is MatchingError) {
            // Show error but still allow navigation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load matches: ${state.message}'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Continue Anyway',
                  textColor: Colors.white,
                  onPressed: () => _navigateToDestination(
                        _FindingMatchesNavTrigger.userContinueAnyway,
                      ),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<MatchingBloc, MatchingState>(
        builder: (context, state) {
          return AppScaffold(
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading spinner with text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: state is MatchingLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _getLoadingText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (state is MatchingError) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.message}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 80),
                    
                    // Skip button
                    TextButton(
                      onPressed: () =>
                          _navigateToDestination(_FindingMatchesNavTrigger.userSkip),
                      child: const Text(
                        'Not now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  String _getLoadingText() {
    switch (widget.source) {
      case FindingMatchesSource.locationSeeker:
      case FindingMatchesSource.flatDetailsSeeker:
        return 'Finding your happy place';
      case FindingMatchesSource.locationLister:
      case FindingMatchesSource.flatDetailsLister:
        return 'Finding flatmates for you';
    }
  }
}
