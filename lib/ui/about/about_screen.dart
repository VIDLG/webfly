import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const _repoOwner = 'vidlg';
const _repoName = 'webfly';
const _repoUrl = 'https://github.com/$_repoOwner/$_repoName';
const _releaseApiUrl =
    'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

class AboutScreen extends HookWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );
    final updateState = useState<_UpdateState>(_UpdateState.idle);
    final latestVersion = useState<String?>(null);
    final apkDownloadUrl = useState<String?>(null);
    final downloadProgress = useState<double>(0);
    final errorMessage = useState<String?>(null);

    final info = packageInfo.data;
    final currentVersion = info != null ? 'v${info.version}' : '...';
    final buildNumber = info?.buildNumber ?? '';

    Future<void> checkForUpdates() async {
      updateState.value = _UpdateState.checking;
      errorMessage.value = null;
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client.getUrl(Uri.parse(_releaseApiUrl));
        request.headers.set('Accept', 'application/vnd.github.v3+json');
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final tagName = data['tag_name'] as String?;
          latestVersion.value = tagName;

          // Find APK asset
          final assets = data['assets'] as List<dynamic>? ?? [];
          String? apkUrl;
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
          apkDownloadUrl.value = apkUrl;

          if (tagName != null && tagName != currentVersion) {
            updateState.value = _UpdateState.available;
          } else {
            updateState.value = _UpdateState.upToDate;
          }
        } else {
          errorMessage.value = 'API returned ${response.statusCode}';
          updateState.value = _UpdateState.error;
        }
        client.close();
      } catch (e) {
        errorMessage.value = e.toString();
        updateState.value = _UpdateState.error;
      }
    }

    Future<void> downloadAndInstall() async {
      final url = apkDownloadUrl.value;
      if (url == null) {
        errorMessage.value = 'No APK found in release assets';
        updateState.value = _UpdateState.error;
        return;
      }

      updateState.value = _UpdateState.downloading;
      downloadProgress.value = 0;
      errorMessage.value = null;

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 15);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();

        if (response.statusCode == 200 || response.statusCode == 302) {
          final contentLength = response.contentLength;
          final cacheDir = await getTemporaryDirectory();
          final filePath =
              '${cacheDir.path}/webfly-${latestVersion.value ?? "update"}.apk';
          final file = File(filePath);
          final sink = file.openWrite();

          int received = 0;
          await for (final chunk in response) {
            sink.add(chunk);
            received += chunk.length;
            if (contentLength > 0) {
              downloadProgress.value = received / contentLength;
            }
          }
          await sink.close();
          client.close();

          updateState.value = _UpdateState.installing;
          final result = await OpenFilex.open(filePath);
          if (result.type != ResultType.done) {
            errorMessage.value = result.message;
            updateState.value = _UpdateState.error;
          } else {
            // Stay on installing state; the system installer takes over
            updateState.value = _UpdateState.available;
          }
        } else {
          client.close();
          errorMessage.value = 'Download failed: HTTP ${response.statusCode}';
          updateState.value = _UpdateState.error;
        }
      } catch (e) {
        errorMessage.value = e.toString();
        updateState.value = _UpdateState.error;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = updateState.value;

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
            // App name
            Text(
              'WebFly',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Version
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
            // Check for updates button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: switch (state) {
                  _UpdateState.checking ||
                  _UpdateState.downloading ||
                  _UpdateState.installing => null,
                  _ => checkForUpdates,
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildCheckContent(
                    state,
                    latestVersion.value,
                    colorScheme,
                  ),
                ),
              ),
            ),
            // Download & install button (visible when update available)
            if (state == _UpdateState.available &&
                apkDownloadUrl.value != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: downloadAndInstall,
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
            // Download progress
            if (state == _UpdateState.downloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: downloadProgress.value > 0
                      ? downloadProgress.value
                      : null,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                downloadProgress.value > 0
                    ? 'Downloading... ${(downloadProgress.value * 100).toStringAsFixed(0)}%'
                    : 'Downloading...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Installing indicator
            if (state == _UpdateState.installing) ...[
              const SizedBox(height: 16),
              Text(
                'Opening installer...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // Error detail
            if (state == _UpdateState.error && errorMessage.value != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage.value!,
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

  Widget _buildCheckContent(
    _UpdateState state,
    String? latest,
    ColorScheme colorScheme,
  ) {
    return switch (state) {
      _UpdateState.idle => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, size: 18),
          SizedBox(width: 8),
          Text('Check for Updates'),
        ],
      ),
      _UpdateState.checking => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      _UpdateState.upToDate => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Already up to date'),
        ],
      ),
      _UpdateState.available ||
      _UpdateState.downloading ||
      _UpdateState.installing => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.new_releases, size: 18, color: colorScheme.error),
          const SizedBox(width: 8),
          Text('New version available: ${latest ?? ""}'),
        ],
      ),
      _UpdateState.error => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 18, color: colorScheme.error),
          const SizedBox(width: 8),
          const Text('Failed, tap to retry'),
        ],
      ),
    };
  }
}

enum _UpdateState {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  error,
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
