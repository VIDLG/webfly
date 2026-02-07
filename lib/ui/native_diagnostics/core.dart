// Core infrastructure for native tests (registry, logging, models)
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../router/config.dart';
import '../../utils/app_logger.dart';

// ============================================================================
// Models
// ============================================================================

class NativeTestEntry {
  const NativeTestEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.routePath,
    required this.icon,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String subtitle;
  final String routePath;
  final IconData icon;
  final List<String> tags;
}

// ============================================================================
// Registry
// ============================================================================

class NativeTestRegistry {
  static const List<NativeTestEntry> tests = <NativeTestEntry>[
    NativeTestEntry(
      id: 'ble',
      title: 'Bluetooth (BLE) test',
      subtitle: 'Scan for nearby BLE advertisers',
      routePath: kBleDiagnosticsPath,
      icon: Icons.bluetooth_searching,
      tags: <String>['Android', 'iOS', 'Permissions'],
    ),
  ];
}

// ============================================================================
// Logging Infrastructure
// ============================================================================

enum TestLogLevel { trace, debug, info, warning, error }

extension TestLogLevelX on TestLogLevel {
  Color? color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (this) {
      TestLogLevel.trace => colors.onSurfaceVariant,
      TestLogLevel.debug => colors.primary,
      TestLogLevel.info => colors.secondary,
      TestLogLevel.warning => colors.tertiary,
      TestLogLevel.error => colors.error,
    };
  }
}

@immutable
class TestLogEntry {
  const TestLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  final DateTime timestamp;
  final TestLogLevel level;
  final String tag;
  final String message;
}

class TestLogBuffer {
  TestLogBuffer._();

  static final TestLogBuffer instance = TestLogBuffer._();

  static const int _capacity = 500;
  final _entries = listSignal<TestLogEntry>([]);

  ListSignal<TestLogEntry> get entries => _entries;

  void clear() {
    _entries.clear();
  }

  void add(TestLogEntry entry) {
    if (_entries.length >= _capacity) {
      _entries.removeAt(0);
    }
    _entries.add(entry);
  }
}

class TestLogger {
  TestLogger(this.tag);

  final String tag;

  void d(String message) {
    TestLogBuffer.instance.add(
      TestLogEntry(
        timestamp: DateTime.now(),
        level: TestLogLevel.debug,
        tag: tag,
        message: message,
      ),
    );
    appLogger.d('[$tag] $message');
  }

  void i(String message) {
    TestLogBuffer.instance.add(
      TestLogEntry(
        timestamp: DateTime.now(),
        level: TestLogLevel.info,
        tag: tag,
        message: message,
      ),
    );
    appLogger.i('[$tag] $message');
  }

  void w(String message) {
    TestLogBuffer.instance.add(
      TestLogEntry(
        timestamp: DateTime.now(),
        level: TestLogLevel.warning,
        tag: tag,
        message: message,
      ),
    );
    appLogger.w('[$tag] $message');
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    TestLogBuffer.instance.add(
      TestLogEntry(
        timestamp: DateTime.now(),
        level: TestLogLevel.error,
        tag: tag,
        message: error == null ? message : '$message ($error)',
      ),
    );
    appLogger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }
}
