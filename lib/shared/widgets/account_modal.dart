import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/analytics/analytics_button_names.dart';
import '../../core/analytics/analytics_facade.dart';
import '../../core/analytics/analytics_screen_names.dart';
import '../../core/bloc/app_bloc.dart';
import '../../core/bloc/app_event.dart';
import '../../core/bloc/app_state.dart';
import '../../core/storage/secure_storage.dart';
import '../theme/app_colors.dart';
import 'profile_invites_sheet.dart';

class AccountModal extends StatelessWidget {
  const AccountModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        // Get user info from app state
        String userName = 'User';
        String userInfo = '';
        
        if (state is AppAuthenticated) {
          userName = state.authResponse.fullName.isNotEmpty 
              ? state.authResponse.fullName 
              : 'User';
          // Could add age/gender here if available in authResponse
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // User info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Avatar placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (userInfo.isNotEmpty)
                              Text(
                                userInfo,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // View your profile
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'View your profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Your personal traits, flat details and more',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _openMyProfile(context, state),
                ),
                // Invite sent/accept details
                ListTile(
                  leading: const Icon(
                    Icons.mail_outline,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'Invite sent/accept details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Analyse and find best flatmate for you',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openProfileInvitesSheet(context, ProfileInvitesTab.invites);
                  },
                ),
                // Support
                ListTile(
                  leading: const Icon(
                    Icons.headset_mic_outlined,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Raise your concerns, we hear you',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: navigate to support or show support dialog
                  },
                ),
                // Logout button
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.textDark,
                  ),
                  title: const Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  onTap: () => _handleLogout(context),
                ),
                
                // Skip button at bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMyProfile(BuildContext context, AppState state) {
    unawaited(
      context.read<AnalyticsFacade>().button(
            AnalyticsButtonNames.openProfile,
            screenName: AnalyticsScreenNames.accountModal,
          ),
    );
    Navigator.of(context).pop();
    _openProfileInvitesSheet(context, ProfileInvitesTab.profile);
  }

  void _openProfileInvitesSheet(BuildContext context, ProfileInvitesTab initialTab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileInvitesSheetWithBlur(initialTab: initialTab),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AnalyticsFacade>().logOutButtonTap();
    // Clear stored data
    await SecureStorage.instance.clearAuthData();
    
    // Reset app state
    if (context.mounted) {
      context.read<AppBloc>().add(const AppUserLoggedOut());
      context.go('/login');
    }
  }
}

/// Wraps AccountModal in blurred background + DraggableScrollableSheet (Frame 51).
/// Use as: showModalBottomSheet(..., builder: (context) => const AccountModalWithBlur()).
class AccountModalWithBlur extends StatelessWidget {
  const AccountModalWithBlur({super.key});

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
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => const AccountModal(),
        ),
      ],
    );
  }
}
