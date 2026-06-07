import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/analytics/analytics_facade.dart';
import 'core/analytics/analytics_bootstrap.dart';
import 'core/analytics/analytics_navigator_observer.dart';
import 'core/bloc/app_bloc.dart';
import 'core/bloc/app_event.dart';
import 'core/bloc/app_state.dart';
import 'core/notifications/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/bloc/linkedin_auth_bloc.dart';
import 'features/auth/bloc/phone_verification_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/repository/phone_verification_repository.dart';
import 'features/flat_requirements/repository/flat_repository.dart';
import 'features/preferences/repository/preferences_repository.dart';
import 'features/matching/repository/matching_repository.dart';
import 'features/profile/repository/profile_repository.dart';
import 'features/profile/repository/requests_repository.dart';
import 'features/chat/repository/chat_repository.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // App runs without .env (e.g. location autocomplete will use Nominatim)
  }
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final analyticsFacade = await bootstrapAnalytics();
  runApp(MyApp(analyticsFacade: analyticsFacade));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.analyticsFacade});

  final AnalyticsFacade analyticsFacade;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AuthRepository _authRepository;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
  }

  /// Initialise NotificationService once per auth session.
  Future<void> _initNotifications(GoRouter router) async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    final ns = NotificationService.instance;
    await ns.init(
      apiClient: _authRepository.apiClient,
      router: router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ns.handleInitialMessage();
    });
  }

  Future<void> _cleanupNotifications() async {
    _notificationsInitialized = false;
    await NotificationService.instance.unregisterAndCleanup();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnalyticsFacade>.value(value: widget.analyticsFacade),
        RepositoryProvider<FlatRepository>(
          create: (context) => FlatRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<PreferencesRepository>(
          create: (context) => PreferencesRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<MatchingRepository>(
          create: (context) => MatchingRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<PhoneVerificationRepository>(
          create: (context) => PhoneVerificationRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<RequestsRepository>(
          create: (context) => RequestsRepository(apiClient: _authRepository.apiClient),
        ),
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepository(apiClient: _authRepository.apiClient),
        ),
      ],
        child: Builder(
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AppBloc>(
                  create: (context) {
                    final appBloc = AppBloc(authRepository: _authRepository);
                    
                    _authRepository.apiClient.onTokenExpired = () {
                      _authRepository.logout();
                      appBloc.add(const AppUserLoggedOut());
                    };
                    
                    appBloc.add(const AppInitialized());
                    return appBloc;
                  },
                ),
                BlocProvider<LinkedInAuthBloc>(
                  create: (context) => LinkedInAuthBloc(authRepository: _authRepository),
                ),
                BlocProvider<PhoneVerificationBloc>(
                  create: (context) => PhoneVerificationBloc(
                    repository: context.read<PhoneVerificationRepository>(),
                  ),
                ),
              ],
              child: BlocListener<AppBloc, AppState>(
                listenWhen: (previous, current) {
                  if (current is AppAuthenticated) return true;
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
                    unawaited(_cleanupNotifications());
                  }
                },
                child: BlocBuilder<AppBloc, AppState>(
                  builder: (context, appState) {
                    final router = createRouter(
                      appState,
                      observers: [
                        AnalyticsNavigatorObserver(widget.analyticsFacade),
                      ],
                    );

                    if (appState is AppAuthenticated) {
                      unawaited(_initNotifications(router));
                    }

                    return MaterialApp.router(
                      title: 'Happy Place',
                      scaffoldMessengerKey: _scaffoldMessengerKey,
                      debugShowCheckedModeBanner: false,
                      theme: ThemeData(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: AppColors.background,
                        ),
                        useMaterial3: true,
                        scaffoldBackgroundColor: AppColors.background,
                      ),
                      routerConfig: router,
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
