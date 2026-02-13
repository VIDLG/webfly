import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webfly_theme/webfly_theme.dart';

import '../../../store/app_settings.dart';
import '../../router/config.dart' show aboutPath;

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showInspector = useSignalValue(showWebfInspectorSignal);
    final cacheControllers = useSignalValue(cacheControllersSignal);
    final themeSignal = useStreamSignal<ThemeState>(
      () => themeStream,
      initialValue: getTheme(),
    );
    final themeValue = themeSignal.value;
    final themeState = themeValue is AsyncData<ThemeState>
        ? themeValue.value
        : getTheme();
    final themeMode = themeState.themePreference;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // WebF section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'WebF',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            value: showInspector,
            onChanged: (value) {
              showWebfInspectorSignal.value = value;
            },
            title: const Text('Show Inspector'),
            subtitle: const Text('Display WebF element inspector overlay'),
          ),
          SwitchListTile(
            value: cacheControllers,
            onChanged: (value) {
              cacheControllersSignal.value = value;
            },
            title: const Text('Cache Controllers'),
            subtitle: const Text(
              'Keep WebF controllers alive when returning to launcher',
            ),
          ),
          const Divider(),
          // Theme section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Theme',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          _ThemeModeSelector(themeMode: themeMode),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(aboutPath),
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
      onChanged: (value) async {
        if (value != null) {
          await setTheme(value);
        }
      },
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            title: const Text('Follow System'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            title: const Text('Light'),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            title: const Text('Dark'),
          ),
        ],
      ),
    );
  }
}
