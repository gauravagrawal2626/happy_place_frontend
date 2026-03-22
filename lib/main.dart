import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/analytics/analytics_facade.dart';
import 'core/analytics/analytics_bootstrap.dart';
import 'core/analytics/analytics_navigator_observer.dart';
import 'core/bloc/app_bloc.dart';
import 'core/bloc/app_event.dart';
import 'core/bloc/app_state.dart';
import 'features/auth/bloc/linkedin_auth_bloc.dart';
import 'features/auth/bloc/phone_verification_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/repository/phone_verification_repository.dart';
import 'features/flat_requirements/repository/flat_repository.dart';
import 'features/preferences/repository/preferences_repository.dart';
import 'features/matching/repository/matching_repository.dart';
import 'features/profile/repository/profile_repository.dart';
import 'features/profile/repository/requests_repository.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // App runs without .env (e.g. location autocomplete will use Nominatim)
  }
  final analyticsFacade = await bootstrapAnalytics();
  runApp(MyApp(analyticsFacade: analyticsFacade));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.analyticsFacade});

  final AnalyticsFacade analyticsFacade;

  @override
  Widget build(BuildContext context) {
    // Create a shared AuthRepository instance
    final authRepository = AuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnalyticsFacade>.value(value: analyticsFacade),
        // FlatRepository - handles flat requirements API calls
        RepositoryProvider<FlatRepository>(
          create: (context) => FlatRepository(apiClient: authRepository.apiClient),
        ),
        // PreferencesRepository - handles preference editing API calls
        RepositoryProvider<PreferencesRepository>(
          create: (context) => PreferencesRepository(apiClient: authRepository.apiClient),
        ),
        // MatchingRepository - handles matches API calls
        RepositoryProvider<MatchingRepository>(
          create: (context) => MatchingRepository(apiClient: authRepository.apiClient),
        ),
        // PhoneVerificationRepository - handles phone verification API calls
        RepositoryProvider<PhoneVerificationRepository>(
          create: (context) => PhoneVerificationRepository(apiClient: authRepository.apiClient),
        ),
        // ProfileRepository - public profile API
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(apiClient: authRepository.apiClient),
        ),
        // RequestsRepository - send request/invite API
        RepositoryProvider<RequestsRepository>(
          create: (context) => RequestsRepository(apiClient: authRepository.apiClient),
        ),
      ],
        child: Builder(
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                // AppBloc - manages app-level state (auth, onboarding status)
                BlocProvider<AppBloc>(
                  create: (context) {
                    final appBloc = AppBloc(authRepository: authRepository);
                    
                    // Set up token expiration handler to auto-logout on 401
                    // This callback will be triggered by ApiClient when any API returns 401
                    authRepository.apiClient.onTokenExpired = () {
                      // Clear auth data and trigger logout
                      authRepository.logout();
                      appBloc.add(const AppUserLoggedOut());
                    };
                    
                    appBloc.add(const AppInitialized());
                    return appBloc;
                  },
                ),
                // LinkedInAuthBloc - manages LinkedIn login flow
                BlocProvider<LinkedInAuthBloc>(
                  create: (context) => LinkedInAuthBloc(authRepository: authRepository),
                ),
                // PhoneVerificationBloc - manages phone verification flow
                BlocProvider<PhoneVerificationBloc>(
                  create: (context) => PhoneVerificationBloc(
                    repository: context.read<PhoneVerificationRepository>(),
                  ),
                ),
              ],
              child: BlocListener<AppBloc, AppState>(
                listenWhen: (previous, current) {
                  if (current is AppAuthenticated) return true;
                  // Reset only when leaving an authenticated session (not on cold start).
                  if (current is AppUnauthenticated &&
                      previous is AppAuthenticated) {
                    return true;
                  }
                  return false;
                },
                listener: (context, state) {
                  final analytics = context.read<AnalyticsFacade>();
                  if (state is AppAuthenticated) {
                    unawaited(
                      analytics.identifyUser(
                        state.authResponse.userId,
                        email: state.authResponse.email,
                        role: state.authResponse.role,
                      ),
                    );
                  } else if (state is AppUnauthenticated) {
                    unawaited(analytics.resetSession());
                  }
                },
                child: BlocBuilder<AppBloc, AppState>(
                  builder: (context, appState) {
                    return MaterialApp.router(
                      title: 'Happy Place',
                      debugShowCheckedModeBanner: false,
                      theme: ThemeData(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: AppColors.background,
                        ),
                        useMaterial3: true,
                        scaffoldBackgroundColor: AppColors.background,
                      ),
                      routerConfig: createRouter(
                        appState,
                        observers: [
                          AnalyticsNavigatorObserver(analyticsFacade),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
    );
  }
}
