import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webfly_updater/webfly_updater.dart';

import '../../store/app_settings.dart';
import '../../store/update_checker.dart';
import '../widgets/webview_screen.dart';

const _repoUrl = 'https://github.com/vidlg/webfly';
const _releasesUrl = 'https://github.com/vidlg/webfly/releases';

class AboutScreen extends HookWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );
    final hasUpdate = hasUpdateSignal.watch(context);
    final latestVer = latestVersionSignal.watch(context);
    final release = releaseInfoSignal.watch(context);
    final releaseNotes = releaseNotesSignal.watch(context);
    // Derive hasManuallyChecked from lastCheckedAt
    final lastChecked = lastCheckedAtSignal.watch(context);
    final hasManuallyChecked = lastChecked != null;
    // Derive isChecking from updateState
    final state = updateStateSignal.watch(context);
    final isChecking = state is UpdateChecking;

    final info = packageInfo.data;
    final currentVersion = info != null ? 'v${info.version}' : '...';
    final buildNumber = info?.buildNumber ?? '';

    Future<void> checkForUpdates() async {
      await updateChecker.check(force: true);
    }

    void startDownloadAndInstall() {
      updateChecker.startDownloadAndInstall();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy =
        isChecking || state is UpdateDownloading || state is UpdateInstalling;

    final double? downloadProgress = state is UpdateDownloading
        ? state.progress
        : null;
    final ({String text, String? subtitle, String? url})? errorInfo =
        state is UpdateFailed ? _errorInfo(state.error) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/gen/logo/webfly_logo_dark.png'
                        : 'assets/gen/logo/webfly_logo_light.png',
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'WebFly',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: isBusy ? null : checkForUpdates,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: isChecking
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
                            Text('New version available: $latestVer'),
                          ],
                        )
                      : hasManuallyChecked
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('Latest: $latestVer'),
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
            if (hasUpdate &&
                release != null &&
                state is! UpdatePreparing &&
                state is! UpdateDownloading &&
                state is! UpdateInstalling &&
                state is! UpdateReady) ...[
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
            if (state is UpdatePreparing || state is UpdateDownloading) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (state is UpdateDownloading &&
                                downloadProgress != null &&
                                downloadProgress > 0)
                            ? downloadProgress
                            : null,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: updateChecker.reset,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (state is UpdateDownloading &&
                        downloadProgress != null &&
                        downloadProgress > 0)
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
            if (state is UpdateReady) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    updateChecker.installApk();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.install_mobile, size: 18),
                        SizedBox(width: 8),
                        Text('Install'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (errorInfo != null) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              errorInfo.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            if (errorInfo.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                errorInfo.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (errorInfo.url != null) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final url = errorInfo.url!;
                                  if (useExternalBrowserSignal.value) {
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  } else if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => WebViewScreen(
                                          url: url,
                                          title: 'Details',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  'Learn more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          if (useExternalBrowserSignal.value) {
                            final uri = Uri.parse(_releasesUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } else if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WebViewScreen(
                                  url: _releasesUrl,
                                  title: 'Releases',
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'View all releases',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.home_outlined,
                    title: 'Homepage',
                    subtitle: _repoUrl,
                    trailing: Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () async {
                      if (useExternalBrowserSignal.value) {
                        final uri = Uri.parse(_repoUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WebViewScreen(
                                url: _repoUrl,
                                title: 'Homepage',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.policy_outlined,
                    title: 'License',
                    subtitle: 'MIT',
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

({String text, String? subtitle, String? url}) _errorInfo(UpdateError error) {
  return switch (error) {
    NetworkError() => _parseNetworkError(error),
    HashVerificationError() => (
      text: 'File corrupted — please retry',
      subtitle: null,
      url: null,
    ),
    SignatureMismatchError() => (
      text: 'APK signature mismatch',
      subtitle: null,
      url: null,
    ),
    DownloadError(:final message) => (
      text: 'Download failed: $message',
      subtitle: null,
      url: null,
    ),
    InstallError(:final message) => (
      text: 'Install failed: $message',
      subtitle: null,
      url: null,
    ),
  };
}

({String text, String? subtitle, String? url}) _parseNetworkError(
  NetworkError error,
) {
  final message = error.message;
  final detail = error.detail;
  final documentationUrl = error.documentationUrl;

  // Extract HTTP status code from "HTTP 403" style message.
  final codeMatch = RegExp(r'HTTP (\d+)').firstMatch(message);
  final code = codeMatch?.group(1);

  // Prefer GitHub's documentation_url; fall back to MDN for HTTP errors.
  final url =
      documentationUrl ??
      (code != null
          ? 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/$code'
          : null);

  // Show GitHub's detail message if present, otherwise a concise fallback.
  final text = detail != null
      ? (code != null ? 'HTTP $code: $detail' : detail)
      : (code != null ? 'HTTP $code' : 'Network error');

  // Build subtitle from rate limit info when available.
  String? subtitle;
  final rlLimit = error.rateLimitLimit;
  final rlRemaining = error.rateLimitRemaining;
  final rlReset = error.rateLimitReset;
  if (rlLimit != null && rlRemaining != null) {
    final used = rlLimit - rlRemaining;
    final parts = <String>['$used / $rlLimit used'];
    if (rlReset != null) {
      final diff = rlReset.difference(DateTime.now());
      if (diff.isNegative) {
        parts.add('resets now');
      } else {
        final mins = diff.inMinutes;
        parts.add(
          mins > 0 ? 'resets in ${mins}m' : 'resets in ${diff.inSeconds}s',
        );
      }
    }
    subtitle = parts.join(' · ');
  }

  return (text: text, subtitle: subtitle, url: url);
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
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
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
