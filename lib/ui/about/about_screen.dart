import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webfly_updater/webfly_updater.dart';

import '../../store/update_checker.dart';

const _repoUrl = 'https://github.com/vidlg/webfly';

class AboutScreen extends HookWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );
    // Shared update state from global store
    final hasUpdate = hasUpdateSignal.watch(context);
    final latestVersionValue = latestVersionSignal.watch(context);
    final release = releaseInfoSignal.watch(context);
    final releaseNotes = releaseNotesSignal.watch(context);
    final checkError = checkErrorSignal.watch(context);

    // Track if user has manually checked (to show latest version even if up-to-date)
    final hasManuallyChecked = useState(false);

    // Local UI state for checking
    final isChecking = useState(false);

    // Stream subscription for download/install
    final updateState = useState<UpdateState>(const UpdateIdle());
    final subscription = useRef<StreamSubscription<UpdateState>?>(null);

    // Dispose subscription on unmount
    useEffect(() {
      return () => subscription.value?.cancel();
    }, const []);

    final info = packageInfo.data;
    final currentVersion = info != null ? 'v${info.version}' : '...';
    final buildNumber = info?.buildNumber ?? '';

    Future<void> checkForUpdates() async {
      isChecking.value = true;
      await updateChecker.check(force: true);
      hasManuallyChecked.value = true;
      isChecking.value = false;
    }

    void startDownloadAndInstall() {
      if (release == null) return;

      subscription.value?.cancel();
      subscription.value = downloadAndInstall(release).listen(
        (state) => updateState.value = state,
        onError: (e) {
          updateState.value = UpdateFailed(DownloadError(e.toString()));
        },
        onDone: () {
          // If stream completes without UpdateReady/UpdateFailed,
          // the install UI was shown by the system.
          final current = updateState.value;
          if (current is! UpdateFailed && current is! UpdateReady) {
            updateState.value = const UpdateReady();
          }
        },
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = updateState.value;
    final isBusy =
        isChecking.value ||
        state is UpdateDownloading ||
        state is UpdateInstalling;

    // Extract progress and error from current state.
    final double? downloadProgress = state is UpdateDownloading
        ? state.progress
        : null;
    final String? errorMessage = state is UpdateFailed
        ? _errorMessage(state.error)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                theme.brightness == Brightness.dark
                    ? 'assets/gen/logo/webfly_logo_dark.png'
                    : 'assets/gen/logo/webfly_logo_light.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WebFly',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              buildNumber.isNotEmpty
                  ? '$currentVersion (build $buildNumber)'
                  : currentVersion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Description
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Project',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'WebFly is like webf go / expo go, focused on '
                      'rendering target web pages natively using the '
                      'WebF engine.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Links & info
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.code,
                    title: 'Source Code',
                    subtitle: _repoUrl,
                    trailing: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.policy_outlined,
                    title: 'License',
                    subtitle: 'See repository for license details',
                  ),
                  if (info != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.android,
                      title: 'Package',
                      subtitle: info.packageName,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Check for updates
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: isBusy ? null : checkForUpdates,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: isChecking.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : hasUpdate
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.new_releases,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New version available: ${latestVersionValue ?? ""}',
                            ),
                          ],
                        )
                      : checkError != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Check failed',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : hasManuallyChecked.value
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('Latest: $latestVersionValue'),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text('Check for Updates'),
                          ],
                        ),
                ),
              ),
            ),
            // Release notes
            if (hasUpdate &&
                releaseNotes != null &&
                releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Release Notes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        releaseNotes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Download & install
            if (hasUpdate &&
                release != null &&
                state is! UpdateDownloading &&
                state is! UpdateInstalling) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: startDownloadAndInstall,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Download & Install'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // Progress
            if (state is UpdateDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: downloadProgress != null && downloadProgress > 0
                      ? downloadProgress
                      : null,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                downloadProgress != null && downloadProgress > 0
                    ? 'Downloading... ${(downloadProgress * 100).toStringAsFixed(0)}%'
                    : 'Downloading...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (state is UpdateInstalling) ...[
              const SizedBox(height: 16),
              Text(
                'Opening installer...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(UpdateError error) {
  return switch (error) {
    NetworkError(:final message) => 'Network error: $message',
    HashVerificationError() => 'File corrupted, please retry',
    SignatureMismatchError() => 'APK signature mismatch, may be unsafe',
    DownloadError(:final message) => 'Download failed: $message',
    InstallError(:final message) => 'Install failed: $message',
  };
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: trailing,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
