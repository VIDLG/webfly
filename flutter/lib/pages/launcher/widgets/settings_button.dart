import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/app_settings_service.dart';

/// Settings button with dialog
class LauncherSettingsButton extends ConsumerWidget {
  const LauncherSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => _showSettingsDialog(context, ref),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(appSettingsProvider).value;
          if (settings == null) {
            return const AlertDialog(
              title: Text('Settings'),
              content: Center(child: CircularProgressIndicator()),
            );
          }

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: const Text('Settings', style: TextStyle(fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: settings.showWebfInspector,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setShowWebfInspector(value);
                  },
                  title: const Text(
                    'Show Inspector',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Display WebF element inspector overlay',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  value: settings.cacheControllers,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setCacheControllers(value);
                  },
                  title: const Text(
                    'Cache Controllers',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Keep WebF controllers alive when returning to launcher',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(60, 32),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
