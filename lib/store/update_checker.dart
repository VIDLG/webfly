import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webfly_updater/webfly_updater.dart';

import '../utils/app_logger.dart';
import 'app_settings.dart';

const _releaseUrl = 'https://api.github.com/repos/vidlg/webfly/releases/latest';

/// Reactive update check state, shared across the app.
///
/// Wraps the pure functions from `webfly_updater` and exposes signals for the
/// UI layer.  This class is justified because it genuinely owns mutable state
/// (signals, version cache, dedup flag).
class AppUpdateChecker {
  final hasUpdate = signal<bool>(false);
  final latestVersion = signal<String?>(null);
  final releaseInfo = signal<ReleaseInfo?>(null);
  final releaseNotes = signal<String?>(null);

  String? _currentVersion;
  bool _checked = false;

  AppUpdateChecker._();

  /// Check GitHub releases for a newer version. Safe to call multiple times;
  /// network is only hit once unless [force] is true.
  Future<void> check({bool force = false}) async {
    if (_checked && !force) return;
    _checked = true;

    try {
      _currentVersion ??= 'v${(await PackageInfo.fromPlatform()).version}';

      final testMode = updateTestModeSignal.value;
      final release = await checkForUpdates(
        releaseUrl: _releaseUrl,
        currentVersion: _currentVersion!,
        testMode: testMode,
      );

      if (release != null) {
        hasUpdate.value = true;
        latestVersion.value = release.version;
        releaseInfo.value = release;
        releaseNotes.value = release.releaseNotes;
      } else {
        hasUpdate.value = false;
        latestVersion.value = _currentVersion;
      }
    } catch (e) {
      appLogger.d('[UpdateChecker] check failed: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Singleton + public API
// ---------------------------------------------------------------------------

AppUpdateChecker? _instance;

AppUpdateChecker get updateChecker {
  _instance ??= AppUpdateChecker._();
  return _instance!;
}

Signal<bool> get hasUpdateSignal => updateChecker.hasUpdate;
Signal<String?> get latestVersionSignal => updateChecker.latestVersion;
Signal<ReleaseInfo?> get releaseInfoSignal => updateChecker.releaseInfo;
Signal<String?> get releaseNotesSignal => updateChecker.releaseNotes;

/// Fire-and-forget: kick off the first update check in the background.
void initializeUpdateChecker() {
  updateChecker.check();
}
