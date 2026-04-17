class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  void log(String message) {
    // Keep both outputs so logs appear reliably across different Flutter targets.
    // ignore: avoid_print
    print(message);
  }
}
