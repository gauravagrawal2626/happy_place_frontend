/// Profile Modal
///
/// Shows public profile (name, age, gender, lifestyle tags, top priorities,
/// weekend activities) with Send Request and Skip. Used from Seeker map and Lister list.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/analytics/analytics_button_names.dart';
import '../../core/analytics/analytics_facade.dart';
import '../../core/analytics/analytics_screen_names.dart';
import '../../features/profile/model/public_profile_model.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/repository/requests_repository.dart';
import '../theme/app_colors.dart';
import 'profile/profile_flat_details.dart';
import 'profile/profile_flat_preferences.dart';
import 'profile/profile_header.dart';
import 'profile/profile_lifestyle_tags.dart';
import 'profile/profile_request_buttons.dart';
import 'profile/profile_section.dart';
import 'profile/profile_skip_button.dart';

/// Role when opening the modal: SEEKER (viewing flat owner) or LISTER (viewing seeker)
enum ProfileModalRole { seeker, lister }

class ProfileModalArgs {
  final String userId;
  final String? flatId;
  final ProfileModalRole role;
  final double? matchScore;
  final bool showBackButton;

  const ProfileModalArgs({
    required this.userId,
    this.flatId,
    required this.role,
    this.matchScore,
    this.showBackButton = false,
  });
}

class ProfileModal extends StatefulWidget {
  final ProfileModalArgs args;

  const ProfileModal({super.key, required this.args});

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  PublicProfile? _profile;
  String? _error;
  bool _loading = true;
  /// Action path currently being called (e.g. /api/requests) so we show loading on that button.
  String? _sendingAction;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final profile = await repo.getPublicProfile(
        widget.args.userId,
        flatId: widget.args.flatId,
        matchScore: widget.args.matchScore,
        includeRequestStatus: true,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  /// Build body for POST /api/requests (create request) when button action is /api/requests.
  Map<String, dynamic> _createRequestBody() {
    final flatId = widget.args.flatId ?? '';
    const message = 'Hi! I\'m interested in connecting.';
    final Map<String, dynamic> base = widget.args.role == ProfileModalRole.lister
        ? {
            'flat_id': flatId,
            'seeker_id': widget.args.userId,
            'message': message,
          }
        : {
            'flat_id': flatId,
            'message': message,
          };
    final matchScore = widget.args.matchScore ?? _profile?.matchScore;
    if (matchScore != null) {
      base['match_score'] = matchScore;
    }
    return base;
  }

  /// Build body for PUT accept/reject/cancel/complete. Pass match_score from args or from loaded profile (API returns it).
  Map<String, dynamic> _putRequestBody() {
    final score = widget.args.matchScore ?? _profile?.matchScore;
    if (score != null) {
      return {'match_score': score};
    }
    return {};
  }

  String _analyticsNameForRequestButton(RequestStatusButton b) {
    final lower = b.text.toLowerCase();
    if (lower.contains('send')) return AnalyticsButtonNames.sendRequest;
    if (lower.contains('accept')) return AnalyticsButtonNames.acceptRequest;
    if (lower.contains('reject')) return AnalyticsButtonNames.rejectRequest;
    if (lower.contains('complete')) return AnalyticsButtonNames.completeMatch;
    return AnalyticsButtonNames.profileRequestOther;
  }

  Future<void> _onButtonPressed(RequestStatusButton button) async {
    if (!button.isClickable || _sendingAction != null) return;
    final mapped = _analyticsNameForRequestButton(button);
    unawaited(
      context.read<AnalyticsFacade>().button(
            mapped,
            screenName: AnalyticsScreenNames.profileModal,
            extra: mapped == AnalyticsButtonNames.profileRequestOther
                ? {'button_label': button.text}
                : null,
          ),
    );
    final action = button.action!.trim();
    setState(() => _sendingAction = action);
    try {
      final repo = context.read<RequestsRepository>();
      final bool isCreate = action == '/api/requests' || action.endsWith('/api/requests');
      final body = isCreate ? _createRequestBody() : _putRequestBody();
      await repo.callAction(action, body: body);
      if (mounted) {
        setState(() => _sendingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${button.text} succeeded'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload profile so buttons update (e.g. Send Request → PENDING)
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Invites (showBackButton): Column → Expanded → sheet; 0.7 only fills bottom 70% of
    // Expanded → ~30% empty band under back arrow. Map/list: sheet is direct child — keep 0.7.
    final initialSheetExtent = widget.args.showBackButton ? 1.0 : 0.7;
    final maxSheetExtent = widget.args.showBackButton ? 1.0 : 0.7;

    final sheet = DraggableScrollableSheet(
        initialChildSize: initialSheetExtent,
        minChildSize: 0.4,
        maxChildSize: maxSheetExtent,
        expand: false,
        builder: (context, scrollController) {
          if (_loading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.textDark),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        context.read<AnalyticsFacade>().button(
                              AnalyticsButtonNames.profileModalRetry,
                              screenName: AnalyticsScreenNames.profileModal,
                            ),
                      );
                      _loadProfile();
                    },
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        context.read<AnalyticsFacade>().button(
                              AnalyticsButtonNames.profileModalSkip,
                              screenName: AnalyticsScreenNames.profileModal,
                            ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
            );
          }
          final p = _profile!;
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  profilePictureUrl: p.profilePicture,
                  fullName: p.fullName,
                  age: p.age,
                  gender: p.gender,
                ),
                const SizedBox(height: 20),
                ProfileLifestyleTags(tags: p.lifestyleTags),
                if (p.lifestyleTags.isNotEmpty) const SizedBox(height: 20),
                if (p.topPriorities.isNotEmpty) ...[
                  ProfileSection(title: 'Top 3 priorities', bullets: p.topPriorities),
                  const SizedBox(height: 16),
                ],
                if (p.weekendActivities != null && p.weekendActivities!.isNotEmpty) ...[
                  ProfileSection(title: 'Weekend activities', singleLine: p.weekendActivities),
                  const SizedBox(height: 24),
                ],
                if (p.flatInfo != null) ...[
                  if (p.flatInfo!.isLister)
                    ProfileFlatDetails(details: p.flatInfo!, location: p.location)
                  else
                    ProfileFlatPreferences(preferences: p.flatInfo!),
                  const SizedBox(height: 24),
                ],
                ProfileRequestButtons(
                  buttons: p.requestStatusButtons,
                  sendingAction: _sendingAction,
                  onPressed: _onButtonPressed,
                ),
                const SizedBox(height: 12),
                ProfileSkipButton(
                  onPressed: () {
                    unawaited(
                      context.read<AnalyticsFacade>().button(
                            AnalyticsButtonNames.profileModalSkip,
                            screenName: AnalyticsScreenNames.profileModal,
                          ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: widget.args.showBackButton
          ? Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8, left: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppColors.textDark,
                      ),
                    ],
                  ),
                ),
                Expanded(child: sheet),
              ],
            )
          : sheet,
    );
  }
}
