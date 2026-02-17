/// Tabbed bottom sheet: Profile | Invites (Frames 52 & 53).
/// Opened from account modal: "View your profile" → Profile tab, "Invite sent/accept details" → Invites tab.
/// Uses reusable profile components for Profile tab; Invites tab shows Invite Sent / Invite Received.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/app_bloc.dart';
import '../../core/bloc/app_state.dart';
import '../../features/profile/model/public_profile_model.dart';
import '../../features/profile/model/request_model.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/profile/repository/requests_repository.dart';
import 'profile/profile_header.dart';
import 'profile/profile_lifestyle_tags.dart';
import 'profile/profile_section.dart';
import 'profile/profile_skip_button.dart';
import 'profile/invites_tab_content.dart';
import 'profile_modal.dart';
import '../theme/app_colors.dart';

enum ProfileInvitesTab { profile, invites }

class ProfileInvitesSheet extends StatefulWidget {
  final ProfileInvitesTab initialTab;

  const ProfileInvitesSheet({
    super.key,
    this.initialTab = ProfileInvitesTab.profile,
  });

  @override
  State<ProfileInvitesSheet> createState() => _ProfileInvitesSheetState();
}

class _ProfileInvitesSheetState extends State<ProfileInvitesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PublicProfile? _profile;
  GetRequestsResponse? _requests;
  String? _profileError;
  String? _requestsError;
  bool _profileLoading = true;
  bool _requestsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == ProfileInvitesTab.profile ? 0 : 1,
    );
    _loadProfile();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final state = context.read<AppBloc>().state;
    if (state is! AppAuthenticated) return;
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final repo = context.read<ProfileRepository>();
      final profile = await repo.getPublicProfile(
        state.authResponse.userId,
        flatId: null,
        includeRequestStatus: false,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _profileLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = e.toString().replaceFirst('Exception: ', '');
          _profileLoading = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _requestsLoading = true;
      _requestsError = null;
    });
    try {
      final repo = context.read<RequestsRepository>();
      final data = await repo.getRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _requestsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _requestsError = e.toString().replaceFirst('Exception: ', '');
          _requestsLoading = false;
        });
      }
    }
  }

  void _onInviteItemTap(RequestListItem item) {
    final state = context.read<AppBloc>().state;
    if (state is! AppAuthenticated) return;
    final role = state.authResponse.role == 'LISTER'
        ? ProfileModalRole.lister
        : ProfileModalRole.seeker;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black26),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, _) => ProfileModal(
              args: ProfileModalArgs(
                userId: item.personDetails.userId,
                flatId: item.flatId.isNotEmpty ? item.flatId : null,
                role: role,
                showBackButton: true,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) _loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppBloc>().state;
    final auth = state is AppAuthenticated ? state.authResponse : null;
    final userName = auth?.fullName ?? 'User';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _profile != null
                  ? ProfileHeader(
                      profilePictureUrl: _profile!.profilePicture,
                      fullName: _profile!.fullName,
                      age: _profile!.age,
                      gender: _profile!.gender,
                      avatarRadius: 30,
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.textDark.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.textDark.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.textDark,
              indicatorColor: AppColors.info,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Invites'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildInvitesTab(),
                ],
              ),
            ),
            ProfileSkipButton(onPressed: () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_profileLoading) {
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
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      );
    }
    if (_profileError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _profileError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final p = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileLifestyleTags(tags: p.lifestyleTags),
          if (p.lifestyleTags.isNotEmpty) const SizedBox(height: 20),
          if (p.topPriorities.isNotEmpty) ...[
            ProfileSection(title: 'Top 3 priorities', bullets: p.topPriorities),
            const SizedBox(height: 16),
          ],
          if (p.weekendActivities != null &&
              p.weekendActivities!.isNotEmpty) ...[
            ProfileSection(
                title: 'Weekend activities', singleLine: p.weekendActivities),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInvitesTab() {
    if (_requestsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.textDark),
              SizedBox(height: 16),
              Text(
                'Loading invites...',
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      );
    }
    if (_requestsError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _requestsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final data = _requests ?? const GetRequestsResponse(sent: [], received: [], sentTotal: 0, receivedTotal: 0, total: 0);
    return InvitesTabContent(
      sent: data.sent,
      received: data.received,
      onItemTap: _onInviteItemTap,
    );
  }
}

/// Wraps ProfileInvitesSheet in blurred background (Frame 52/53).
class ProfileInvitesSheetWithBlur extends StatelessWidget {
  final ProfileInvitesTab initialTab;

  const ProfileInvitesSheetWithBlur({
    super.key,
    this.initialTab = ProfileInvitesTab.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.black26),
              ),
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) =>
              ProfileInvitesSheet(initialTab: initialTab),
        ),
      ],
    );
  }
}
