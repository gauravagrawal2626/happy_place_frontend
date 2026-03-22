import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_facade.dart';
import '../../../core/bloc/app_bloc.dart';
import '../../../core/bloc/app_event.dart';
import '../../../core/bloc/app_state.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/theme/app_colors.dart';
import '../../auth/bloc/linkedin_auth_bloc.dart';
import '../../auth/bloc/linkedin_auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AnalyticsFacade>().logOutButtonTap();
              if (!context.mounted) return;
              context.read<AppBloc>().add(const AppUserLoggedOut());
              context.read<LinkedInAuthBloc>().add(LinkedInLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // Wait for app to finish initializing
          if (state is AppLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textDark,
              ),
            );
          }
          
          // Only proceed if user is authenticated
          if (state is! AppAuthenticated) {
            // If not authenticated, router will redirect to login
            // Show loading while waiting for redirect
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.textDark,
              ),
            );
          }
          
          // App is authenticated - show home content
          final authResponse = state.authResponse;
          final nameParts = authResponse.fullName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  authResponse.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (authResponse.userId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${authResponse.userId}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildFindFlatmatesCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFindFlatmatesCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/matching'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Flatmates',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover compatible roommates nearby based on your preferences',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Map',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Color(0xFF667eea),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 36,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
