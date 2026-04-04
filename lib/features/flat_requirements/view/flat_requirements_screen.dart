/// Flat Requirements Screen
/// 
/// Single screen that adapts based on user role:
/// - SEEKER: Modify flat preferences (budget, amenities, etc.)
/// - LISTER: Add/edit flat details (rent, photos, description)
/// 
/// Features:
/// - Dynamic question rendering
/// - Form field inputs (sliders, selectors)
/// - Photo upload (LISTER only)
/// - Pre-population from existing data

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/analytics/analytics_button_names.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/analytics/analytics_screen_names.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../bloc/flat_bloc.dart';
import '../bloc/flat_event.dart';
import '../bloc/flat_state.dart';
import '../model/flat_question_model.dart';

class FlatRequirementsScreen extends StatelessWidget {
  /// Optional override for isLister flag
  /// If null, uses user role from AppBloc
  /// If true, shows LISTER flow (Add Flat Details)
  /// If false, shows SEEKER flow (Modify Flatmate Preferences)
  final bool? isListerOverride;

  const FlatRequirementsScreen({
    super.key,
    this.isListerOverride,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        if (appState is! AppAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = appState.authResponse.role;
        // Determine if user is actually a LISTER (for UI widgets like photos/description)
        final isUserLister = userRole == 'LISTER';
        
        // Always fetch questions based on user's actual role, not which button was clicked
        // This ensures SEEKERs always get SEEKER questions, LISTERs always get LISTER questions
        final isListerForQuestions = isUserLister;
        
        // Debug logging
        print('[FlatRequirementsScreen] Constructor - isListerOverride: $isListerOverride');
        print('[FlatRequirementsScreen] Constructor - userRole: $userRole');
        print('[FlatRequirementsScreen] Constructor - isUserLister (for UI): $isUserLister');
        print('[FlatRequirementsScreen] Constructor - isListerForQuestions (for API): $isListerForQuestions');

        return BlocProvider(
          create: (context) {
            final flatBloc = FlatBloc(
              repository: context.read(),
            );
            // Always fetch questions based on user's actual role
            flatBloc.add(LoadFlatQuestions(isLister: isListerForQuestions));
            return flatBloc;
          },
          child: _FlatRequirementsContent(
            userRole: userRole,
            isLister: isUserLister, // Use actual user role for UI widgets (photos/description)
          ),
        );
      },
    );
  }
}

class _FlatRequirementsContent extends StatefulWidget {
  final String userRole;
  final bool isLister;

  const _FlatRequirementsContent({
    required this.userRole,
    required this.isLister,
  });

  @override
  State<_FlatRequirementsContent> createState() => _FlatRequirementsContentState();
}

class _FlatRequirementsContentState extends State<_FlatRequirementsContent> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatSubmitSuccess) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to finding matches screen
          final source = widget.isLister ? 'flat-lister' : 'flat-seeker';
          context.go('/finding-matches/$source');
        } else if (state is FlatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is FlatLoaded && state.uploadError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.uploadError!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<FlatBloc>().add(ClearUploadError());
        }
      },
      builder: (context, state) {
        if (state is FlatLoading || state is FlatInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is FlatSubmitting) {
          return AppScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    widget.isLister 
                        ? 'Saving flat details...' 
                        : 'Saving preferences...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // FlatSubmitSuccess navigates to /finding-matches in listener
        // Show loading while navigating
        if (state is FlatSubmitSuccess || state is FlatFindingMatches) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is FlatError && state.previousState == null) {
          return AppScaffold(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<FlatBloc>().add(LoadFlatQuestions(isLister: widget.isLister)),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get the current state (either FlatLoaded or error with previousState)
        final loadedState = state is FlatLoaded 
            ? state 
            : (state as FlatError).previousState!;

        return _buildMainContent(context, loadedState);
      },
    );
  }

  Widget _buildMainContent(BuildContext context, FlatLoaded state) {
    return AppScaffold(
      useSafeArea: false,
      child: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(state),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Flat requirements',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormFields(context, state),
                    ..._buildQuestions(context, state),
                    if (state.showImageUpload) ...[
                      const SizedBox(height: 24),
                      _buildPhotoSection(context, state),
                    ],
                    if (state.showDescription) ...[
                      const SizedBox(height: 24),
                      _buildDescriptionField(context, state),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(context, state),
          ],
        ),
      ),
    );
  }

  bool _isFieldAnswered(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is int) return value != 0;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  Widget _buildProgressIndicator(FlatLoaded state) {
    final formFieldKeys = widget.isLister
        ? ['flat_size', 'rent', 'security_deposit', 'bedroom_type', 'washroom_type', 'listing_type', 'facilities']
        : ['preferred_flat_size', 'max_rent', 'max_deposit', 'bedroom_type', 'washroom_type', 'preferred_listing_type', 'required_facilities'];

    final answeredFormFields = formFieldKeys.where((key) => _isFieldAnswered(state.formFields[key])).length;
    final totalItems = formFieldKeys.length + state.questions.length;
    final answeredItems = answeredFormFields + state.questionAnswers.length;
    final progress = totalItems > 0 ? answeredItems / totalItems : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$answeredItems of $totalItems answered',
                style: TextStyle(
                  color: AppColors.textDark.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textDark),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(FlatLoaded state) {
    final locality = state.formFields['locality'] ?? '';
    final city = state.formFields['city'] ?? '';
    
    if (locality.isEmpty && city.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.background.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.background),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flat Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withOpacity(0.6),
                  ),
                ),
                Text(
                  '$locality${city.isNotEmpty ? ', $city' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, FlatLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipSelector(
          context: context,
          label: 'You have/need',
          fieldName: widget.isLister ? 'flat_size' : 'preferred_flat_size',
          value: state.formFields[widget.isLister ? 'flat_size' : 'preferred_flat_size'] as String?,
          options: ['2BHK', '3BHK', '4BHK+', 'Villa'],
          displayLabels: {'2BHK': '2 BHK', '3BHK': '3 BHK', '4BHK+': '4 BHK+', 'Villa': 'Villa'},
        ),
        const SizedBox(height: 20),
        _buildSliderField(
          context: context,
          label: 'Rent/Room',
          subtitle: 'Inclusive of maintenance etc',
          fieldName: widget.isLister ? 'rent' : 'max_rent',
          value: (state.formFields[widget.isLister ? 'rent' : 'max_rent'] as int?) ?? 0,
          min: 5000,
          max: 100000,
          divisions: 19,
          prefix: '₹',
        ),
        const SizedBox(height: 20),
        _buildChipSelector(
          context: context,
          label: 'Type of bedroom',
          fieldName: 'bedroom_type',
          value: state.formFields['bedroom_type'] as String?,
          options: ['master', 'balcony', 'other'],
          displayLabels: {'master': 'Master Bedroom', 'balcony': 'With Balcony', 'other': 'Other ones'},
        ),
        const SizedBox(height: 20),
        _buildSliderField(
          context: context,
          label: 'Deposit/person',
          fieldName: widget.isLister ? 'security_deposit' : 'max_deposit',
          value: (state.formFields[widget.isLister ? 'security_deposit' : 'max_deposit'] as int?) ?? 0,
          min: 0,
          max: 500000,
          divisions: 50,
          prefix: '₹',
        ),
        const SizedBox(height: 20),
        _buildChipSelector(
          context: context,
          label: 'Type of washroom',
          fieldName: 'washroom_type',
          value: state.formFields['washroom_type'] as String?,
          options: ['attached', 'shared'],
          displayLabels: {'attached': 'Attached', 'shared': 'Shared'},
        ),
        const SizedBox(height: 20),
        _buildDropdownField(
          context: context,
          label: 'Listing Type',
          fieldName: widget.isLister ? 'listing_type' : 'preferred_listing_type',
          value: state.formFields[widget.isLister ? 'listing_type' : 'preferred_listing_type'] as String?,
          options: ['SHARED_FLAT', 'ENTIRE_FLAT'],
          displayLabels: {'SHARED_FLAT': 'Shared Flat', 'ENTIRE_FLAT': 'Entire Flat'},
        ),
        const SizedBox(height: 20),
        _buildFacilitiesField(context, state),
      ],
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String fieldName,
    required String? value,
    required List<String> options,
    Map<String, String>? displayLabels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border.all(color: AppColors.textDark.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select $label'),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(displayLabels?[option] ?? option),
                );
              }).toList(),
              onChanged: (newValue) {
                context.read<FlatBloc>().add(
                  UpdateFormField(fieldName: fieldName, value: newValue),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelector({
    required BuildContext context,
    required String label,
    required String fieldName,
    required String? value,
    required List<String> options,
    Map<String, String>? displayLabels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = value == option;
            return GestureDetector(
              onTap: () {
                context.read<FlatBloc>().add(
                  UpdateFormField(fieldName: fieldName, value: option),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textDark : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayLabels?[option] ?? option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatNumber(int n, {String? prefix}) {
    final formatted = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '${prefix ?? ''}$formatted';
  }

  Widget _buildSliderField({
    required BuildContext context,
    required String label,
    required String fieldName,
    required int value,
    required int min,
    required int max,
    required int divisions,
    String? prefix,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
            if (value > 0)
              Text(
                _formatNumber(value, prefix: prefix),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: AppColors.textDark,
          inactiveColor: Colors.white.withOpacity(0.5),
          onChanged: (newValue) {
            context.read<FlatBloc>().add(
              UpdateFormField(fieldName: fieldName, value: newValue.toInt()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFacilitiesField(BuildContext context, FlatLoaded state) {
    final fieldName = widget.isLister ? 'facilities' : 'required_facilities';
    final selectedFacilities = (state.formFields[fieldName] as List<dynamic>?)?.cast<String>() ?? [];
    
    final allFacilities = [
      {'id': 'ac', 'label': 'AC', 'icon': Icons.ac_unit},
      {'id': 'wifi', 'label': 'WiFi', 'icon': Icons.wifi},
      {'id': 'parking', 'label': 'Parking', 'icon': Icons.local_parking},
      {'id': 'gym', 'label': 'Gym', 'icon': Icons.fitness_center},
      {'id': 'washing_machine', 'label': 'Washing Machine', 'icon': Icons.local_laundry_service},
      {'id': 'attached_washroom', 'label': 'Attached Washroom', 'icon': Icons.bathroom},
      {'id': 'balcony', 'label': 'Balcony', 'icon': Icons.balcony},
      {'id': 'power_backup', 'label': 'Power Backup', 'icon': Icons.battery_charging_full},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isLister ? 'Facilities Available' : 'Required Facilities',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allFacilities.map((facility) {
            final isSelected = selectedFacilities.contains(facility['id']);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(selectedFacilities);
                if (isSelected) {
                  updated.remove(facility['id']);
                } else {
                  updated.add(facility['id'] as String);
                }
                context.read<FlatBloc>().add(
                  UpdateFormField(fieldName: fieldName, value: updated),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textDark : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      facility['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      facility['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildQuestions(BuildContext context, FlatLoaded state) {
    return state.questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: _buildQuestion(context, question, state, index),
      );
    }).toList();
  }

  Widget _buildQuestion(
    BuildContext context,
    FlatQuestion question,
    FlatLoaded state,
    int index,
  ) {
    final answer = state.questionAnswers[question.id];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          question.primaryText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        if (question.secondaryText != null) ...[
          const SizedBox(height: 4),
          Text(
            question.secondaryText!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark.withOpacity(0.6),
            ),
          ),
        ],
        const SizedBox(height: 12),
        
        // Options
        _buildQuestionOptions(context, question, answer),
      ],
    );
  }

  Widget _buildQuestionOptions(
    BuildContext context,
    FlatQuestion question,
    dynamic currentAnswer,
  ) {
    final isMultiSelect = question.isMultiSelect;
    final selectedAnswers = currentAnswer is List 
        ? currentAnswer.cast<String>() 
        : (currentAnswer != null ? [currentAnswer.toString()] : <String>[]);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: question.options.map((option) {
        final isSelected = selectedAnswers.contains(option.id);
        
        return GestureDetector(
          onTap: () {
            dynamic newAnswer;
            if (isMultiSelect) {
              final updated = List<String>.from(selectedAnswers);
              if (isSelected) {
                updated.remove(option.id);
              } else if (updated.length < question.maxSelections) {
                updated.add(option.id);
              }
              newAnswer = updated;
            } else {
              newAnswer = option.id;
            }
            
            context.read<FlatBloc>().add(
              UpdateQuestionAnswer(questionId: question.id, answer: newAnswer),
            );
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textDark : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.imageUrl != null) ...[
                  Image.network(
                    option.imageUrl!,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoSection(BuildContext context, FlatLoaded state) {
    print('[FlatRequirementsScreen] _buildPhotoSection called - showImageUpload: ${state.showImageUpload}');
    assert(state.showImageUpload == true, 'Photo section should only be shown when showImageUpload is true');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Upload Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.cloud_upload_outlined, size: 22, color: AppColors.textDark),
          ],
        ),
        const SizedBox(height: 12),
        
        // Photo grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Uploaded photos
            ...state.uploadedImages.asMap().entries.map((entry) {
              return _buildPhotoTile(
                imageUrl: entry.value,
                index: entry.key,
                onRemove: () {
                  context.read<FlatBloc>().add(RemovePhoto(index: entry.key));
                },
              );
            }),
            
            // Uploading photos (with loader)
            ...state.uploadingImages.map((fileName) {
              return _buildUploadingTile(fileName);
            }),
            
            // Add photo button
            if (state.uploadedImages.length + state.uploadingImages.length < 10)
              _buildAddPhotoButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoTile({
    required String imageUrl,
    required VoidCallback onRemove,
    required int index,
  }) {
    final isMockUrl = imageUrl.contains('placeholder-s3.com');

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textDark, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.5),
            child: Container(
              width: 100,
              height: 100,
              color: isMockUrl ? Colors.white.withOpacity(0.85) : Colors.grey[200],
              child: isMockUrl
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, size: 32, color: AppColors.textDark),
                          const SizedBox(height: 4),
                          Text(
                            'Photo ${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        final is403 = error.toString().contains('403');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.textDark),
                              const SizedBox(height: 4),
                              Text(
                                'Photo ${index + 1}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                              if (is403)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Uploaded',
                                    style: TextStyle(fontSize: 10, color: AppColors.textDark),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingTile(String fileName) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDark, width: 1.5),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textDark, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: AppColors.textDark, size: 28),
            const SizedBox(height: 4),
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        final bytes = await File(image.path).readAsBytes();
        final contentType = image.mimeType ?? 'image/jpeg';
        
        context.read<FlatBloc>().add(AddPhoto(
          fileName: image.name,
          contentType: contentType,
          fileBytes: bytes,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Widget _buildDescriptionField(BuildContext context, FlatLoaded state) {
    print('[FlatRequirementsScreen] _buildDescriptionField called - showDescription: ${state.showDescription}');
    assert(state.showDescription == true, 'Description field should only be shown when showDescription is true');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell potential flatmates about your flat',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textDark.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'Describe your flat, amenities, neighborhood...',
            filled: true,
            fillColor: Colors.white.withOpacity(0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textDark.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textDark, width: 2),
            ),
          ),
          onChanged: (value) {
            context.read<FlatBloc>().add(
              UpdateFormField(fieldName: 'description', value: value),
            );
          },
          controller: TextEditingController(
            text: state.formFields['description'] as String? ?? '',
          )..selection = TextSelection.fromPosition(
            TextPosition(offset: (state.formFields['description'] as String? ?? '').length),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, FlatLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  context.read<AnalyticsFacade>().button(
                        AnalyticsButtonNames.saveFlatDetails,
                        screenName: AnalyticsScreenNames.flatRequirements,
                      ),
                );
                context.read<FlatBloc>().add(
                  SubmitFlatData(userRole: widget.userRole),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Save Changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.pop(false),
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
    );
  }

}
