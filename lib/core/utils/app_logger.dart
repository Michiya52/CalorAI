import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  void log(String message) {
    // Debug builds only: release builds must not dump AI responses and user
    // meal data into the device system log.
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }
}
