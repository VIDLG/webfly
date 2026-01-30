import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../services/app_settings_service.dart'
    show showWebfInspectorSignal, cacheControllersSignal, themeModeSignal;

/// Settings button with dialog
class LauncherSettingsButton extends StatelessWidget {
  const LauncherSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: () => _showSettingsDialog(context),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: const Text('Settings', style: TextStyle(fontSize: 18)),
        content: Watch((context) {
          final showInspector = showWebfInspectorSignal.watch(context);
          final cacheControllers = cacheControllersSignal.watch(context);
          final themeMode = themeModeSignal.watch(context);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: showInspector,
                onChanged: (value) {
                  showWebfInspectorSignal.value = value;
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
                value: cacheControllers,
                onChanged: (value) {
                  cacheControllersSignal.value = value;
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              _ThemeModeSelector(themeMode: themeMode),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 32),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeModeSelector({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ThemeMode>(
      groupValue: themeMode,
      onChanged: (value) {
        if (value != null) {
          themeModeSignal.value = value;
        }
      },
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            title: const Text('Follow System', style: TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            title: const Text('Light', style: TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            title: const Text('Dark', style: TextStyle(fontSize: 13)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
