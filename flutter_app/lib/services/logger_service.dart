import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  static const String _tag = 'KalorienTracker';
  static LogLevel _minLevel = LogLevel.debug;

  /// Set minimum log level (e.g., LogLevel.warning for production)
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Only log if level meets minimum threshold
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$timestamp [$_tag:${level.name.toUpperCase()}] $message';

    // Use developer.log for better IDE integration and filtering
    developer.log(
      logMessage,
      level: _levelToSysLogLevel(level),
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );

    // In debug mode, also print (for quick debugging)
    if (level == LogLevel.error || level == LogLevel.critical) {
      print('❌ $logMessage');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   $stackTrace');
    }
  }

  static int _levelToSysLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 0; // Debug
      case LogLevel.info:
        return 1; // Info
      case LogLevel.warning:
        return 2; // Warning
      case LogLevel.error:
        return 3; // Error
      case LogLevel.critical:
        return 4; // Critical
    }
  }
}
