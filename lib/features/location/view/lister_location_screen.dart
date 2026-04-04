import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_state.dart';
import '../../../services/google_places_autocomplete_service.dart';
import '../../../services/location_autocomplete_service.dart';
import '../model/location_model.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';

/// Lister Location Screen - Phase 4
/// 
/// Flow:
/// 1. Input exact flat location (Google Places autocomplete when API key set;
///    else Nominatim via [LocationAutocompleteService])
/// 2. Show selected location as chip
/// 3. Submit; Skip is shown only after onboarding (revisit), not during first lister onboarding
class ListerLocationScreen extends StatelessWidget {
  const ListerLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appBloc = context.read<AppBloc>();
    final authRepository = appBloc.authRepository;
    final apiClient = authRepository.apiClient;

    return BlocProvider(
      create: (context) => LocationBloc(
        apiClient: apiClient,
        userRole: 'LISTER',
      ),
      child: const _ListerLocationContent(),
    );
  }
}

class _ListerLocationContent extends StatefulWidget {
  const _ListerLocationContent();

  @override
  State<_ListerLocationContent> createState() => _ListerLocationContentState();
}

class _ListerLocationContentState extends State<_ListerLocationContent> {
  final LocationAutocompleteService _autocompleteService = LocationAutocompleteService();
  final GooglePlacesAutocompleteService _googlePlacesService = GooglePlacesAutocompleteService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<LocationSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final List<LocationSuggestion> results = _googlePlacesService.isAvailable
          ? await _googlePlacesService.search(query, limit: 10)
          : await _autocompleteService.search(
              query,
              countryCode: 'in',
              limit: 10,
            );

      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _selectSuggestion(LocationSuggestion suggestion) async {
    LocationSuggestion toApply = suggestion;
    if (suggestion.placeId != null) {
      final full = await _googlePlacesService.getPlaceDetails(suggestion.placeId!);
      if (full == null || !mounted) return;
      toApply = full;
    }

    final locality = toApply.locality ?? toApply.city ?? '';
    final city = toApply.city ?? toApply.state ?? 'Bangalore';
    final pincode = toApply.pincode ?? '';

    final geoLocation = GeoLocation.fromLatLng(
      toApply.location.latitude,
      toApply.location.longitude,
    );

    context.read<LocationBloc>().add(
          SetFlatLocation(
            location: geoLocation,
            locality: locality,
            city: city,
            pincode: pincode,
            formattedAddress: toApply.displayName,
          ),
        );

    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is DraftFlatCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Flat location saved!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Navigate to shared finding matches screen
            context.go('/finding-matches/location-lister');
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
          if (state is FlatLocationInput) {
            return _buildLocationInput(context, state);
          }

          if (state is SubmittingDraftFlat) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.textDark),
                  SizedBox(height: 16),
                  Text(
                    'Saving location...',
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

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  Widget _buildLocationInput(BuildContext context, FlatLocationInput state) {
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

                  // Location input field with autocomplete
                  if (state.location == null)
                    _buildLocationInputField(context)
                  else
                    _buildSelectedLocation(context, state.location!),
                  
                  // Autocomplete suggestions
                  if (state.location == null && _suggestions.isNotEmpty)
                    _buildSuggestionsList(context),
                ],
              ),
            ),
          ),

          // Bottom navigation — no Skip during onboarding; lister must set location first time
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: BlocBuilder<AppBloc, AppState>(
              builder: (context, appState) {
                final showSkip = appState is AppAuthenticated &&
                    appState.onboardingCompleted;
                return Row(
                  mainAxisAlignment: showSkip
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: [
                    if (showSkip)
                      TextButton(
                        onPressed: () {
                          unawaited(
                            context.read<AnalyticsFacade>().button(
                                  AnalyticsButtonNames.locationListerSkip,
                                  screenName: AnalyticsScreenNames.listerLocation,
                                ),
                          );
                          context.read<LocationBloc>().add(SkipFlatLocation());
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
                      onPressed: state.hasLocation
                          ? () {
                              unawaited(
                                context.read<AnalyticsFacade>().button(
                                      AnalyticsButtonNames.locationListerNext,
                                      screenName: AnalyticsScreenNames.listerLocation,
                                    ),
                              );
                              context.read<LocationBloc>().add(SubmitDraftFlat());
                            }
                          : null,
                      child: Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: state.hasLocation
                                  ? AppColors.textDark
                                  : AppColors.textDark.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: state.hasLocation
                                ? AppColors.textDark
                                : AppColors.textDark.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Add your flat location',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              prefixIcon: const Icon(Icons.location_on, color: AppColors.textDark),
              suffixIcon: _isLoadingSuggestions
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textDark),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _suggestions = [];
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.textDark, size: 20),
            title: Text(
              suggestion.displayName.split(',').take(2).join(','), // Show first 2 parts
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            subtitle: suggestion.displayName.contains(',')
                ? Text(
                    suggestion.displayName.split(',').skip(2).join(','),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildSelectedLocation(
    BuildContext context,
    dynamic location, // FlatLocation
  ) {
    final formatted = location.formattedAddress as String?;
    final fallback = '${location.locality}, ${location.city}'
        .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
        .replaceAll(RegExp(r',\s*,'), ',');
    final label = (formatted != null && formatted.trim().isNotEmpty)
        ? formatted.trim()
        : fallback;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Clear location and reset search
              _searchController.clear();
              setState(() {
                _suggestions = [];
              });
              context.read<LocationBloc>().add(ClearFlatLocation());
            },
            child: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}
