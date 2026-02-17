import 'package:logging/logging.dart';
import 'package:talker/talker.dart';

final talker = Talker(
  settings: TalkerSettings(
    enabled: true,
    useHistory: true,
    maxHistoryItems: 1000,
  ),
);

final appLogger = Logger('app');

Level _getLogLevel() {
  const levelStr = String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
  switch (levelStr.toLowerCase()) {
    case 'all':
    case 'finest':
      return Level.FINEST;
    case 'debug':
    case 'finer':
      return Level.FINER;
    case 'fine':
      return Level.FINE;
    case 'info':
      return Level.INFO;
    case 'warning':
    case 'warn':
      return Level.WARNING;
    case 'error':
    case 'severe':
      return Level.SEVERE;
    case 'fatal':
    case 'shout':
      return Level.SHOUT;
    case 'off':
      return Level.OFF;
    default:
      return Level.INFO;
  }
}

void initAppLogger() {
  final level = _getLogLevel();
  Logger.root.level = level;

  Logger.root.onRecord.listen((record) {
    final message = record.message;
    final error = record.error;
    final stackTrace = record.stackTrace;

    if (record.level >= Level.SEVERE) {
      talker.error(message, error, stackTrace);
    } else if (record.level >= Level.WARNING) {
      talker.warning(message, error, stackTrace);
    } else if (record.level >= Level.INFO) {
      talker.info(message, error, stackTrace);
    } else {
      talker.debug(message, error, stackTrace);
    }
  });
}
