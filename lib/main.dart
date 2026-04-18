import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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
import 'firebase_options.dart';
import 'theme.dart';
import 'utils/seed_data.dart';

Future<void> _initializeFirebaseWithRetry({int maxAttempts = 3}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return;
    } catch (e) {
      final message = e.toString();
      final isChannelError = message.contains('channel-error') ||
          message.contains('Unable to establish connection on channel');

      if (!isChannelError || attempt == maxAttempts) {
        rethrow;
      }

      // Give desktop plugin channels a moment to settle before retrying.
      await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
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

  try {
    // Initialize Firebase — required for all services.
    await _initializeFirebaseWithRetry();
    firebaseReady = true;
    debugPrint('Firebase initialized successfully');

    // Seed data in the background so startup is never blocked by network/db issues.
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(seedFoodsDatabase().catchError((e, stack) {
        debugPrint('Background food seeding failed: $e');
        debugPrint(stack.toString());
      }));
    }
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
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.create(_authProvider);
  }

  @override
  void dispose() {
    // Note: Do not dispose _authProvider here if it's managed by ChangeNotifierProvider.value?
    // Actually ChangeNotifierProvider.value DOES NOT dispose. So we should dispose it.
    _authProvider.dispose();
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
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'CalorAI',
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

class _StartupErrorScreen extends StatelessWidget {
  final String message;
  const _StartupErrorScreen({required this.message});

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
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
