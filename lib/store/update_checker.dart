import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webfly_updater/webfly_updater.dart' hide installApk;
import 'package:webfly_updater/webfly_updater.dart' as updater show installApk;

import '../utils/app_logger.dart';
import 'app_settings.dart';

const _releaseUrl = 'https://api.github.com/repos/vidlg/webfly/releases/latest';

class AppUpdateChecker {
  final hasUpdate = signal<bool>(false);
  final latestVersion = signal<String?>(null);
  final releaseInfo = signal<ReleaseInfo?>(null);
  final releaseNotes = signal<String?>(null);
  final updateState = signal<UpdateState>(const UpdateIdle());

  String? _currentVersion;
  bool _checked = false;
  StreamSubscription<UpdateState>? _downloadSub;

  AppUpdateChecker._();

  Future<void> check({bool force = false}) async {
    if (_checked && !force) return;
    _checked = true;

    try {
      _currentVersion ??= 'v${(await PackageInfo.fromPlatform()).version}';
      talker.info('[UpdateChecker] Checking for updates...');
      talker.info('[UpdateChecker] Current version: $_currentVersion');

      final currentSignature = await getInstalledSignature();
      talker.info(
        '[UpdateChecker] Current signature: ${currentSignature ?? "unknown"}',
      );

      talker.debug('[UpdateChecker] Release URL: $_releaseUrl');

      final testMode = updateTestModeSignal.value;
      talker.debug('[UpdateChecker] Test mode: $testMode');

      final release = await checkForUpdates(
        releaseUrl: _releaseUrl,
        currentVersion: _currentVersion!,
        testMode: testMode,
        networkConfig: networkConfig,
      );

      if (release != null) {
        talker.info(
          '[UpdateChecker] New version available: ${release.version}',
        );
        talker.info('[UpdateChecker] Download URL: ${release.downloadUrl}');
        talker.debug('[UpdateChecker] SHA256 URL: ${release.sha256Url}');
        hasUpdate.value = true;
        latestVersion.value = release.version;
        releaseInfo.value = release;
        releaseNotes.value = release.releaseNotes;
      } else {
        talker.info('[UpdateChecker] Already up to date');
        hasUpdate.value = false;
        latestVersion.value = _currentVersion;
      }
    } catch (e, s) {
      talker.error('[UpdateChecker] Check failed', e, s);
    }
  }

  int _lastLoggedPercent = -1;

  void startDownloadAndInstall() {
    final release = releaseInfo.value;
    if (release == null) {
      talker.warning('[UpdateChecker] No release info, cannot start download');
      return;
    }

    talker.info('[UpdateChecker] Starting download...');
    talker.info('[UpdateChecker] Download URL: ${release.downloadUrl}');

    _downloadSub?.cancel();
    _lastLoggedPercent = -1;

    _downloadSub = downloadAndInstall(release.downloadUrl).listen(
      (state) {
        updateState.value = state;
        if (state case UpdateDownloading(:final progress)) {
          final percent = (progress * 100).round();
          if (percent > 0 && percent >= _lastLoggedPercent + 10) {
            _lastLoggedPercent = (percent ~/ 10) * 10;
            talker.info('[UpdateChecker] Downloading: $_lastLoggedPercent%');
          }
        } else {
          talker.info('[UpdateChecker] State: $state');
        }
      },
      onError: (e, s) {
        talker.error('[UpdateChecker] Download error', e, s);
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
      talker.info('[UpdateChecker] Re-opening installer...');
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

Signal<bool> get hasUpdateSignal => updateChecker.hasUpdate;
Signal<String?> get latestVersionSignal => updateChecker.latestVersion;
Signal<ReleaseInfo?> get releaseInfoSignal => updateChecker.releaseInfo;
Signal<String?> get releaseNotesSignal => updateChecker.releaseNotes;
Signal<UpdateState> get updateStateSignal => updateChecker.updateState;

/// Fire-and-forget: kick off the first update check in the background.
void initializeUpdateChecker() {
  updateChecker.check();
}
