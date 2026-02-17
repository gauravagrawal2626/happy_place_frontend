import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linkedin_login/linkedin_login.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../utils/linkedin_auth_helper.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/theme/app_colors.dart';
import '../bloc/linkedin_auth_bloc.dart';
import '../bloc/linkedin_auth_event.dart';
import '../bloc/linkedin_auth_state.dart';

/// Login Screen - Phase 1
/// 
/// Simple login screen with LinkedIn authentication
/// - Uses AppScaffold for consistent turquoise background
/// - Uses reusable AppButton component
/// - LinkedIn OAuth integration
/// - Navigates to onboarding after successful login
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocListener<LinkedInAuthBloc, LinkedInAuthState>(
        listener: (context, state) {
          if (state is LinkedInAuthSuccess) {
            // Notify AppBloc that user is authenticated
            // The router will handle navigation based on onboarding status
            context.read<AppBloc>().add(
              AppUserAuthenticated(
                onboardingCompleted: state.authResponse.onboardingCompleted,
              ),
            );
          }
        },
        child: BlocBuilder<LinkedInAuthBloc, LinkedInAuthState>(
          builder: (context, state) {
            final isLoading = state is LinkedInAuthLoading;
            
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
            return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
              child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            // Top spacing - positions content ~28% from top
                            SizedBox(height: constraints.maxHeight * 0.28),
                            
                            // Title - left aligned
                            const Text(
                              'Find your next\nhappy place now.',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // LinkedIn Button - using reusable AppButton
                            AppButton.auth(
                              label: 'Continue with LinkedIn',
                              icon: _LinkedInIcon(),
                              isLoading: isLoading,
                              onTap: () => _handleLinkedInLogin(context),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Footer - center aligned
                            const Center(
                              child: Text(
                                'By continuing you agree to our\nTerms of service and privacy policy',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            
                            // Error message
                            if (state is LinkedInAuthFailure) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                        child: Text(
                          state.error,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 13,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleLinkedInLogin(BuildContext context) {
                          final bloc = context.read<LinkedInAuthBloc>();
                          bloc.add(LinkedInLoginRequested());

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: bloc,
                                child: LinkedInUserWidget(
                                  appBar: AppBar(
                                    title: const Text('LinkedIn Login'),
              backgroundColor: const Color(0xFF0077B5),
              foregroundColor: Colors.white,
                                  ),
                                  destroySession: true,
                                  redirectUrl: linkedInRedirectUri,
                                  clientId: linkedInClientId,
                                  clientSecret: linkedInClientSecret,
                                  onGetUserProfile: (UserSucceededAction userSucceededAction) {
                                    bloc.handleLoginSuccess(userSucceededAction);
                                    Navigator.pop(context);
                                  },
                                  onError: (UserFailedAction error) {
                                    bloc.handleLoginError(error);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
  }
}

/// LinkedIn "in" logo icon
class _LinkedInIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF0A66C2),
        borderRadius: BorderRadius.circular(3),
              ),
      child: const Center(
        child: Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
