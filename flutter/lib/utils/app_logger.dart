import 'package:logger/logger.dart';

/// Get log level from environment or default to info
Level _getLogLevel() {
  const levelStr = String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
  switch (levelStr.toLowerCase()) {
    case 'all':
    case 'trace':
      return Level.all;
    case 'debug':
      return Level.debug;
    case 'info':
      return Level.info;
    case 'warning':
    case 'warn':
      return Level.warning;
    case 'error':
      return Level.error;
    case 'fatal':
      return Level.fatal;
    case 'off':
      return Level.off;
    default:
      return Level.info;
  }
}

/// Global logger instance for the application
///
/// Log level can be controlled via --dart-define:
/// ```
/// flutter run --dart-define=LOG_LEVEL=debug
/// flutter run --dart-define=LOG_LEVEL=info  (default)
/// flutter run --dart-define=LOG_LEVEL=error
/// ```
final appLogger = Logger(
  level: _getLogLevel(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 3,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
