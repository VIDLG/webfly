import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webfly_theme/webfly_theme.dart';

import '../../../store/app_settings.dart';

/// Show settings dialog
void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends HookWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final showInspector = useSignalValue(showWebfInspectorSignal);
    final cacheControllers = useSignalValue(cacheControllersSignal);
    final themeSignal = useStreamSignal<ThemeState>(
      () => themeStream,
      initialValue: getTheme(),
    );
    final themeState =
        (themeSignal.value as AsyncData<ThemeState>).value;
    final themeMode = themeState.themePreference;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: const Text('Settings', style: TextStyle(fontSize: 18)),
      content: Column(
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
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(60, 32),
            textStyle: const TextStyle(fontSize: 13),
          ),
          child: const Text('Close'),
        ),
      ],
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
      onChanged: (value) async {
        if (value != null) {
          await setTheme(value);
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
