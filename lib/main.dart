import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/chatbot_provider.dart';
import 'providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/notification_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

Future<void> _initializeFirebaseWithRetry({int maxAttempts = 5}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 1. Crashlytics - Fatal error reporting
      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // 2. Performance Monitoring
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

      // 4. Analytics - Engagement tracking
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseAnalytics.instance.logAppOpen();

      // 5. Messaging - Notification permissions & background handling
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      // 6. Remote Config - OTA updates
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(const {
        'ai_confidence_threshold': 0.5,
        'maintenance_mode': false,
      });
      await remoteConfig.fetchAndActivate();

      return;
    } catch (e) {
      final message = e.toString();
      final isChannelError = message.contains('channel-error') ||
          message.contains('Unable to establish connection on channel');

      if (!isChannelError || attempt == maxAttempts) {
        rethrow;
      }

      debugPrint(
          'Firebase init attempt $attempt failed (channel-error), retrying in ${500 * attempt}ms...');
      // Give plugin channels time to settle — emulators can be very slow.
      await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  String? startupError;

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('WARNING: .env could not be loaded: $e');
  }

  // Notifications are nice-to-have: never let their init block Firebase.
  // (init/requestPermissions are internally no-ops on web and desktop.)
  try {
    await NotificationService().init();
    await NotificationService().requestPermissions();
  } catch (e) {
    debugPrint('Notification setup failed (non-fatal): $e');
  }

  try {
    // Initialize Firebase — required for all services.
    await _initializeFirebaseWithRetry();
    firebaseReady = true;
    debugPrint('Firebase initialized successfully');
  } catch (e, stack) {
    startupError = e.toString();
    debugPrint('Startup initialization failed: $e');
    debugPrint(stack.toString());
  }

  runApp(CalorAIApp(
    firebaseReady: firebaseReady,
    startupError: startupError,
  ));
}

class CalorAIApp extends StatefulWidget {
  final bool firebaseReady;
  final String? startupError;

  const CalorAIApp({
    super.key,
    required this.firebaseReady,
    this.startupError,
  });

  @override
  State<CalorAIApp> createState() => _CalorAIAppState();
}

class _CalorAIAppState extends State<CalorAIApp> {
  AuthProvider? _authProvider;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseReady) {
      _initializeProviders();
    }
  }

  @override
  void didUpdateWidget(CalorAIApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firebaseReady && !oldWidget.firebaseReady) {
      _initializeProviders();
    }
  }

  void _initializeProviders() {
    _authProvider = AuthProvider();
    _router = AppRouter.create(_authProvider!);
  }

  @override
  void dispose() {
    _authProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return MaterialApp(
        title: 'CalorAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _StartupErrorScreen(
          message: widget.startupError ?? 'Firebase initialization failed.',
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider!),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'CalorAI',
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

class _StartupErrorScreen extends StatefulWidget {
  final String message;
  const _StartupErrorScreen({required this.message});

  @override
  State<_StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<_StartupErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await _initializeFirebaseWithRetry();
      if (mounted) {
        // Restart the entire app with a fresh widget tree
        runApp(const CalorAIApp(firebaseReady: true));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _retrying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Retry failed: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Startup Failed',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retrying ? null : _retry,
                child: _retrying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
