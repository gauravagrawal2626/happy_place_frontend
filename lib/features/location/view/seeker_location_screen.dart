import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/chip_button.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/bloc/app_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../model/location_model.dart';

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
                  // Title
                  const Text(
                    "Let's see if there are people like you within your proximity",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // City selector (simple for now - can enhance later)
                  _buildCitySelector(context, state.city),

                  const SizedBox(height: 32),

                  // Selected areas (chips with X)
                  if (state.selectedAreas.isNotEmpty) ...[
                    const Text(
                      'Selected Areas:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.selectedAreas.map((area) {
                        return _buildLocationChip(
                          area.name,
                          onRemove: () {
                            context.read<LocationBloc>().add(
                                  ToggleAreaSelection(area),
                                );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Available areas
                  const Text(
                    'Popular Areas:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Areas grid
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.areas.map((area) {
                      final isSelected = state.selectedAreas.any(
                        (a) => a.id == area.id,
                      );
                      return ChipButton(
                        text: area.name,
                        isSelected: isSelected,
                        onTap: () {
                          context.read<LocationBloc>().add(
                                ToggleAreaSelection(area),
                              );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    context.read<LocationBloc>().add(SkipLocationSelection());
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: state.hasSelections
                      ? () {
                          context.read<LocationBloc>().add(
                                SubmitPreferredLocations(),
                              );
                        }
                      : null,
                  child: Row(
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
                      const SizedBox(width: 8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector(BuildContext context, String currentCity) {
    // Simple dropdown for now - can enhance with search later
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_city, color: AppColors.textDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentCity,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textDark),
        ],
      ),
    );
  }

  Widget _buildLocationChip(String text, {required VoidCallback onRemove}) {
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
            child: const Icon(
              Icons.close,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}
