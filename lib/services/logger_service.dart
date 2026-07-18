import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../main.dart'; // To access globalKeys if needed

/// Centralized logging service for the application.
/// Routes errors to Crashlytics in production and console in development.
class LoggerService {
  // Singleton
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  /// Log an informational message.
  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Log an error with optional stack trace and context.
  /// Set [showToast] to true to display a SnackBar to the user.
  void error(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    bool showToast = false,
    String? toastMessage,
  }) {
    // 1. Console logging for developers
    if (kDebugMode) {
      debugPrint('🚨 [ERROR] ${reason ?? "An error occurred"}');
      debugPrint(error.toString());
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }

    // 2. Report to Crashlytics
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    }

    // 3. Optional UI Feedback (Edge Case: UI context unavailable but key is)
    if (showToast) {
      final message = toastMessage ?? 'An unexpected error occurred.';
      _showToast(message);
    }
  }

  void _showToast(String message) {
    // Uses the global scaffold messenger key defined in main.dart
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (kDebugMode) {
        debugPrint(
            '⚠️ [WARN] Tried to show toast, but ScaffoldMessenger is null.');
      }
    }
  }
}
