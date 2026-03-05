import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webfly_theme/webfly_theme.dart';

import '../../../store/app_settings.dart';
import '../../../store/update_checker.dart';
import '../../widgets/webview_screen.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showInspector = useSignalValue(showWebfInspectorSignal);
    final cacheControllers = useSignalValue(cacheControllersSignal);
    final developerMode = useSignalValue(updateTestModeSignal);
    final useExternalBrowser = useSignalValue(useExternalBrowserSignal);
    final showLogsFab = useSignalValue(showLogsFabSignal);
    final connectTimeout = useSignalValue(connectTimeoutSignal);
    final receiveTimeout = useSignalValue(receiveTimeoutSignal);
    final githubToken = useSignalValue(githubTokenSignal);
    final showToken = useState(false);
    final learnMoreTap = useMemoized(() => TapGestureRecognizer());
    useEffect(() => learnMoreTap.dispose, const []);
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

    final smallTitle = theme.textTheme.bodyMedium;
    final smallSubtitle = theme.textTheme.bodySmall;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'WebF',
                style: theme.textTheme.labelMedium?.copyWith(
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
              title: Text('Show Inspector', style: smallTitle),
              subtitle: Text(
                'Display WebF element inspector overlay',
                style: smallSubtitle,
              ),
              dense: true,
            ),
            SwitchListTile(
              value: cacheControllers,
              onChanged: (value) {
                cacheControllersSignal.value = value;
              },
              title: Text('Cache Controllers', style: smallTitle),
              subtitle: Text(
                'Keep WebF controllers alive when returning to launcher',
                style: smallSubtitle,
              ),
              dense: true,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Network',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            ListTile(
              title: Text('Connection Timeout', style: smallTitle),
              subtitle: Text('Seconds', style: smallSubtitle),
              dense: true,
              trailing: SizedBox(
                width: 72,
                child: TextFormField(
                  initialValue: connectTimeout.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: smallSubtitle,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final v = int.tryParse(value);
                    if (v != null && v > 0) {
                      connectTimeoutSignal.value = v;
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: Text('Download Timeout', style: smallTitle),
              subtitle: Text('Seconds', style: smallSubtitle),
              dense: true,
              trailing: SizedBox(
                width: 72,
                child: TextFormField(
                  initialValue: receiveTimeout.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: smallSubtitle,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final v = int.tryParse(value);
                    if (v != null && v > 0) {
                      receiveTimeoutSignal.value = v;
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                initialValue: githubToken,
                obscureText: !showToken.value,
                style: smallSubtitle,
                decoration: InputDecoration(
                  labelText: 'GitHub Token',
                  hintText: 'github_pat_...',
                  helper: Text.rich(
                    TextSpan(
                      text:
                          'Fine-grained PAT (read-only). '
                          'Raises rate limit to 5,000 req/h. ',
                      children: [
                        TextSpan(
                          text: 'Learn more',
                          style: TextStyle(color: colorScheme.primary),
                          recognizer: learnMoreTap
                            ..onTap = () async {
                              const url =
                                  'https://github.com/settings/personal-access-tokens/new';
                              if (useExternalBrowserSignal.value) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const WebViewScreen(
                                      url: url,
                                      title: 'GitHub Token',
                                    ),
                                  ),
                                );
                              }
                            },
                        ),
                      ],
                    ),
                    style: smallSubtitle,
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showToken.value ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () {
                      showToken.value = !showToken.value;
                    },
                  ),
                ),
                onChanged: (value) {
                  githubTokenSignal.value = value.trim();
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Theme',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            _ThemeModeSelector(themeMode: themeMode),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Developer',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            SwitchListTile(
              value: developerMode,
              onChanged: (value) {
                updateTestModeSignal.value = value;
                updateChecker.check(force: true);
              },
              title: Text('Test Update Flow', style: smallTitle),
              subtitle: Text(
                'Simulate update available for testing download',
                style: smallSubtitle,
              ),
              dense: true,
            ),
            SwitchListTile(
              value: useExternalBrowser,
              onChanged: (value) {
                useExternalBrowserSignal.value = value;
              },
              title: Text('External Browser', style: smallTitle),
              subtitle: Text(
                'Open links in system browser instead of built-in WebView',
                style: smallSubtitle,
              ),
              dense: true,
            ),
            SwitchListTile(
              value: showLogsFab,
              onChanged: (value) {
                showLogsFabSignal.value = value;
              },
              title: Text('Show Logs Button', style: smallTitle),
              subtitle: Text(
                'Display floating logs button on all screens',
                style: smallSubtitle,
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeModeSelector({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final smallText = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: Text('System', style: smallText),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: Text('Light', style: smallText),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text('Dark', style: smallText),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (Set<ThemeMode> selection) async {
          await setTheme(selection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
