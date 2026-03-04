import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webfly_updater/webfly_updater.dart' hide installApk;
import 'package:webfly_updater/webfly_updater.dart' as updater show installApk;

import '../utils/app_logger.dart';
import 'app_settings.dart';

const _releaseUrl = 'https://api.github.com/repos/vidlg/webfly/releases/latest';

class AppUpdateChecker {
  final latestVersion = signal<String?>(null);
  final currentVersion = signal<String?>(null);
  final releaseInfo = signal<ReleaseInfo?>(null);
  final releaseNotes = signal<String?>(null);
  final updateState = signal<UpdateState>(const UpdateIdle());
  final lastCheckedAt = signal<DateTime?>(null);

  final hasUpdate = signal<bool>(false);

  bool get isChecking => updateState.value is UpdateChecking;

  String? _currentVersion;
  bool _checked = false;
  StreamSubscription<UpdateState>? _downloadSub;

  AppUpdateChecker._() {
    // Sync hasUpdate whenever its dependencies change.
    effect(() {
      final current = currentVersion.value;
      final latest = latestVersion.value;
      final testMode = updateTestModeSignal.value;
      hasUpdate.value =
          (current != null &&
              latest != null &&
              current.replaceFirst('v', '') != latest.replaceFirst('v', '')) ||
          (testMode && releaseInfo.value != null);
    });
  }

  Future<void> check({bool force = false}) async {
    if (_checked && !force) return;
    _checked = true;

    try {
      updateState.value = const UpdateChecking();
      _currentVersion ??= 'v${(await PackageInfo.fromPlatform()).version}';
      currentVersion.value = _currentVersion;
      talker.updateInfo('Checking for updates...');
      talker.updateInfo('Current version: $_currentVersion');

      final currentSignature = await getInstalledSignature();
      talker.updateInfo('Current signature: ${currentSignature ?? "unknown"}');

      talker.updateDebug('Release URL: $_releaseUrl');

      final testMode = updateTestModeSignal.value;
      talker.updateDebug('Test mode: $testMode');

      final release = await checkForUpdates(
        releaseUrl: _releaseUrl,
        currentVersion: _currentVersion!,
        testMode: testMode,
        networkConfig: networkConfig,
      );

      if (release != null) {
        talker.updateInfo('New version available: ${release.version}');
        talker.updateInfo('Download URL: ${release.downloadUrl}');
        talker.updateDebug('SHA256 URL: ${release.sha256Url}');
        latestVersion.value = release.version;
        releaseInfo.value = release;
        releaseNotes.value = release.releaseNotes;
      } else {
        talker.updateInfo('Already up to date');
        latestVersion.value = _currentVersion;
      }
      lastCheckedAt.value = DateTime.now();
      updateState.value = const UpdateIdle();
    } catch (e) {
      talker.updateError('Check failed: $e');
      _checked = false;
      updateState.value = UpdateFailed(
        e is UpdateError ? e : NetworkError(e.toString()),
      );
    }
  }

  int _lastLoggedPercent = -1;

  void startDownloadAndInstall() {
    final release = releaseInfo.value;
    if (release == null) {
      talker.updateWarning('No release info, cannot start download');
      return;
    }

    talker.updateInfo('Starting download...');
    talker.updateInfo('Download URL: ${release.downloadUrl}');

    _downloadSub?.cancel();
    _lastLoggedPercent = -1;

    _downloadSub = downloadAndInstall(release.downloadUrl).listen(
      (state) {
        updateState.value = state;
        if (state case UpdateDownloading(:final progress)) {
          final percent = (progress * 100).round();
          if (percent > 0 && percent >= _lastLoggedPercent + 10) {
            _lastLoggedPercent = (percent ~/ 10) * 10;
            talker.updateInfo('Downloading: $_lastLoggedPercent%');
          }
        } else {
          talker.updateInfo('State: $state');
        }
      },
      onError: (e, s) {
        talker.updateError('Download error: $e');
        updateState.value = UpdateFailed(DownloadError(e.toString()));
      },
    );
  }

  void reset() {
    _downloadSub?.cancel();
    updateState.value = const UpdateIdle();
  }

  void installApk() {
    final state = updateState.value;
    if (state is UpdateReady) {
      talker.updateInfo('Re-opening installer...');
      updater.installApk(state.apkPath);
    }
  }

  void dispose() {
    _downloadSub?.cancel();
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

Signal<String?> get latestVersionSignal => updateChecker.latestVersion;
Signal<String?> get currentVersionSignal => updateChecker.currentVersion;
Signal<ReleaseInfo?> get releaseInfoSignal => updateChecker.releaseInfo;
Signal<String?> get releaseNotesSignal => updateChecker.releaseNotes;
Signal<UpdateState> get updateStateSignal => updateChecker.updateState;
Signal<DateTime?> get lastCheckedAtSignal => updateChecker.lastCheckedAt;
Signal<bool> get hasUpdateSignal => updateChecker.hasUpdate;

/// Fire-and-forget: kick off the first update check in the background.
void initializeUpdateChecker() {
  updateChecker.check();
}
