import 'dart:async';

import 'package:logging/logging.dart';
import 'package:talker/talker.dart';

// ---------------------------------------------------------------------------
// Custom log keys for module-level filtering in TalkerScreen
// ---------------------------------------------------------------------------

abstract class AppTalkerKey {
  AppTalkerKey._();

  static const updateChecker = 'update-checker';
  static const ble = 'ble';
  static const appRouter = 'app-router';
  static const assetServer = 'asset-server';
  static const launcher = 'launcher';
}

// ---------------------------------------------------------------------------
// Global talker instance
// ---------------------------------------------------------------------------

final talker = Talker(
  settings: TalkerSettings(
    enabled: true,
    useHistory: true,
    maxHistoryItems: 1000,
    titles: {
      AppTalkerKey.updateChecker: 'UpdateChecker',
      AppTalkerKey.ble: 'BLE',
      AppTalkerKey.appRouter: 'AppRouter',
      AppTalkerKey.assetServer: 'AssetServer',
      AppTalkerKey.launcher: 'Launcher',
    },
    colors: {
      AppTalkerKey.updateChecker: AnsiPen()..xterm(12),
      AppTalkerKey.ble: AnsiPen()..xterm(39),
      AppTalkerKey.appRouter: AnsiPen()..xterm(214),
      AppTalkerKey.assetServer: AnsiPen()..xterm(85),
      AppTalkerKey.launcher: AnsiPen()..xterm(183),
    },
  ),
);

// ---------------------------------------------------------------------------
// Talker extension – shorthand for module-tagged logs
// ---------------------------------------------------------------------------

extension AppTalkerX on Talker {
  void _tagged(String key, String msg, LogLevel level) =>
      logCustom(TalkerLog(msg, key: key, logLevel: level));

  // UpdateChecker
  void updateInfo(String msg) =>
      _tagged(AppTalkerKey.updateChecker, msg, LogLevel.info);
  void updateDebug(String msg) =>
      _tagged(AppTalkerKey.updateChecker, msg, LogLevel.debug);
  void updateWarning(String msg) =>
      _tagged(AppTalkerKey.updateChecker, msg, LogLevel.warning);
  void updateError(String msg) =>
      _tagged(AppTalkerKey.updateChecker, msg, LogLevel.error);

  // BLE
  void bleInfo(String msg) => _tagged(AppTalkerKey.ble, msg, LogLevel.info);
  void bleDebug(String msg) => _tagged(AppTalkerKey.ble, msg, LogLevel.debug);
  void bleWarning(String msg) =>
      _tagged(AppTalkerKey.ble, msg, LogLevel.warning);
  void bleError(String msg) => _tagged(AppTalkerKey.ble, msg, LogLevel.error);

  // AppRouter
  void routerInfo(String msg) =>
      _tagged(AppTalkerKey.appRouter, msg, LogLevel.info);
  void routerDebug(String msg) =>
      _tagged(AppTalkerKey.appRouter, msg, LogLevel.debug);
  void routerWarning(String msg) =>
      _tagged(AppTalkerKey.appRouter, msg, LogLevel.warning);
  void routerError(String msg) =>
      _tagged(AppTalkerKey.appRouter, msg, LogLevel.error);

  // AssetServer
  void assetInfo(String msg) =>
      _tagged(AppTalkerKey.assetServer, msg, LogLevel.info);
  void assetDebug(String msg) =>
      _tagged(AppTalkerKey.assetServer, msg, LogLevel.debug);
  void assetWarning(String msg) =>
      _tagged(AppTalkerKey.assetServer, msg, LogLevel.warning);
  void assetError(String msg) =>
      _tagged(AppTalkerKey.assetServer, msg, LogLevel.error);

  // Launcher
  void launcherInfo(String msg) =>
      _tagged(AppTalkerKey.launcher, msg, LogLevel.info);
  void launcherDebug(String msg) =>
      _tagged(AppTalkerKey.launcher, msg, LogLevel.debug);
  void launcherWarning(String msg) =>
      _tagged(AppTalkerKey.launcher, msg, LogLevel.warning);
  void launcherError(String msg) =>
      _tagged(AppTalkerKey.launcher, msg, LogLevel.error);
}

// ---------------------------------------------------------------------------
// Dart logging package bridge
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Noisy print filter – suppresses upstream debug prints (e.g. webf Canvas2D)
// ---------------------------------------------------------------------------

const _suppressedPrefixes = ['[Canvas2D]'];

/// Zone specification that silently drops print() lines matching known noisy
/// prefixes from upstream packages.
final noisyPrintFilter = ZoneSpecification(
  print: (self, parent, zone, line) {
    for (final prefix in _suppressedPrefixes) {
      if (line.startsWith(prefix)) return;
    }
    parent.print(zone, line);
  },
);

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
