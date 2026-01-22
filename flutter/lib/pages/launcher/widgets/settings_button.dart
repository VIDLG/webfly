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
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _ThemeModeSelector(themeMode: settings.themeMode),
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

class _ThemeModeSelector extends ConsumerWidget {
  final ThemeMode themeMode;

  const _ThemeModeSelector({required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).setThemeMode(value);
            }
          },
          title: const Text('Follow System', style: TextStyle(fontSize: 13)),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).setThemeMode(value);
            }
          },
          title: const Text('Light', style: TextStyle(fontSize: 13)),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).setThemeMode(value);
            }
          },
          title: const Text('Dark', style: TextStyle(fontSize: 13)),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
