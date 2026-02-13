import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _repoOwner = 'vidlg';
const _repoName = 'webfly';
const _repoUrl = 'https://github.com/$_repoOwner/$_repoName';

class AboutScreen extends HookWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(
      useMemoized(() => PackageInfo.fromPlatform()),
    );
    final updateState = useState<_UpdateCheckState>(_UpdateCheckState.idle);
    final latestVersion = useState<String?>(null);

    final info = packageInfo.data;
    final currentVersion = info != null ? 'v${info.version}' : '...';
    final buildNumber = info?.buildNumber ?? '';

    Future<void> checkForUpdates() async {
      updateState.value = _UpdateCheckState.loading;
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client.getUrl(
          Uri.parse(
            'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
          ),
        );
        request.headers.set('Accept', 'application/vnd.github.v3+json');
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final tagName = data['tag_name'] as String?;
          latestVersion.value = tagName;

          if (tagName != null && tagName != currentVersion) {
            updateState.value = _UpdateCheckState.available;
          } else {
            updateState.value = _UpdateCheckState.upToDate;
          }
        } else {
          updateState.value = _UpdateCheckState.error;
        }
        client.close();
      } catch (_) {
        updateState.value = _UpdateCheckState.error;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Check for updates
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: updateState.value == _UpdateCheckState.loading
                    ? null
                    : checkForUpdates,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildUpdateContent(
                    updateState.value,
                    latestVersion.value,
                    colorScheme,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateContent(
    _UpdateCheckState state,
    String? latest,
    ColorScheme colorScheme,
  ) {
    switch (state) {
      case _UpdateCheckState.idle:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 18),
            SizedBox(width: 8),
            Text('Check for Updates'),
          ],
        );
      case _UpdateCheckState.loading:
        return const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _UpdateCheckState.upToDate:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Already up to date'),
          ],
        );
      case _UpdateCheckState.available:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.new_releases, size: 18, color: colorScheme.error),
            const SizedBox(width: 8),
            Text('New version available: ${latest ?? ""}'),
          ],
        );
      case _UpdateCheckState.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 18, color: colorScheme.error),
            const SizedBox(width: 8),
            const Text('Failed to check, tap to retry'),
          ],
        );
    }
  }
}

enum _UpdateCheckState { idle, loading, upToDate, available, error }

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
