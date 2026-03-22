import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/bloc/app_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

/// Seeker Location Screen - Phase 4
/// 
/// Flow:
/// 1. Select city (default: Bangalore)
/// 2. Load and display popular areas for that city
/// 3. Multi-select areas
/// 4. Submit or skip
class SeekerLocationScreen extends StatelessWidget {
  const SeekerLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appBloc = context.read<AppBloc>();
    final appState = appBloc.state;
    final authRepository = appBloc.authRepository;
    final apiClient = authRepository.apiClient;

    return BlocProvider(
      create: (context) => LocationBloc(
        apiClient: apiClient,
        userRole: 'SEEKER',
      )..add(LoadAreasForCity('Bangalore')), // Default city
      child: const _SeekerLocationContent(),
    );
  }
}

class _SeekerLocationContent extends StatelessWidget {
  const _SeekerLocationContent();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is PreferredLocationsSaved || state is FindingMatches) {
            // Navigate to shared finding matches screen
            context.go('/finding-matches/location-seeker');
          } else if (state is LocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoadingAreas) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.textDark),
            );
          }

          if (state is AreasLoaded) {
            return _buildAreasSelection(context, state);
          }

          if (state is SubmittingPreferredLocations) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.textDark),
                  SizedBox(height: 16),
                  Text(
                    'Saving locations...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          // FindingMatches navigates to /finding-matches in listener
          // Show loading while navigating
          if (state is FindingMatches || state is PreferredLocationsSaved) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  Widget _buildAreasSelection(BuildContext context, AreasLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Let\u2019s see if there are people like you within your proximity",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Card containing city + all area chips
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.textDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // City selector
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.city,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 22, color: AppColors.textDark),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Unified area chips (sorted alphabetically)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: (List.of(state.areas)..sort((a, b) => a.name.compareTo(b.name))).map((area) {
                            final isSelected = state.selectedAreas.any((a) => a.id == area.id);
                            return GestureDetector(
                              onTap: () {
                                context.read<LocationBloc>().add(ToggleAreaSelection(area));
                              },
                              child: isSelected
                                  ? _buildSelectedChip(area.name, onRemove: () {
                                      context.read<LocationBloc>().add(ToggleAreaSelection(area));
                                    })
                                  : _buildUnselectedChip(area.name),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom CTAs
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: state.hasSelections
                        ? () {
                            unawaited(
                              context.read<AnalyticsFacade>().button(
                                    AnalyticsButtonNames.locationSeekerNext,
                                    screenName: AnalyticsScreenNames.seekerLocation,
                                  ),
                            );
                            context.read<LocationBloc>().add(SubmitPreferredLocations());
                          }
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: state.hasSelections
                                ? AppColors.textDark
                                : AppColors.textDark.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: state.hasSelections
                              ? AppColors.textDark
                              : AppColors.textDark.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    unawaited(
                      context.read<AnalyticsFacade>().button(
                            AnalyticsButtonNames.locationSeekerSkip,
                            screenName: AnalyticsScreenNames.seekerLocation,
                          ),
                    );
                    context.read<LocationBloc>().add(SkipLocationSelection());
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChip(String text, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.cancel, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUnselectedChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.textDark.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }

}
