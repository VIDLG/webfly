import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/app_settings_service.dart';
import '../services/url_history_service.dart';
import '../services/asset_http_server.dart';
import '../utils/validators.dart';
import '../widgets/url_history_list.dart';
import '../widgets/webf_inspector_overlay.dart';
import '../router/config.dart' show kScannerPath, buildWebFRouteUrl;

class LauncherPage extends HookConsumerWidget {
  const LauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final errorMessage = useState<String?>(null);
    final showInspector = ref.watch(showWebfInspectorProvider).value ?? false;
    final urls = ref.watch(urlHistoryProvider).value;

    useEffect(() {
      if (urls == null || urls.isEmpty) return null;
      if (urlController.text.isEmpty) {
        urlController.text = urls.first;
      }
      return null;
    }, [urls, urlController]);

    void openWebF(String url) {
      ref.read(urlHistoryProvider.notifier).addUrl(url);
      errorMessage.value = null;

      // Always use hybrid routing mode (shared controller)
      final routeUrl = buildWebFRouteUrl(path: '/', url: url);
      print('[LauncherPage] Navigating to hybrid route: $routeUrl');
      context.push(routeUrl, extra: {'initial': true, 'url': url});
    }

    Future<void> openScanner() async {
      final result = await context.push<String>(kScannerPath);
      if (result != null) {
        openWebF(result);
      }
    }

    void applyManualUrl() {
      final input = urlController.text.trim();
      if (input.isEmpty) {
        errorMessage.value = 'Please enter a URL';
        return;
      }
      if (!isValidHttpUrl(input)) {
        errorMessage.value = 'Please enter a valid http/https URL';
        return;
      }
      openWebF(input);
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          SystemNavigator.pop(); // Exit the app
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('WebFly'), centerTitle: true),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter a URL or scan a QR code to launch',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'WebF Bundle URL',
                          hintText: 'https://example.com/bundle.js',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                          errorText: errorMessage.value,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              urlController.clear();
                              errorMessage.value = null;
                            },
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => applyManualUrl(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: showInspector,
                        onChanged: (value) {
                          ref
                              .read(showWebfInspectorProvider.notifier)
                              .setShowWebfInspector(value);
                        },
                        title: const Text('Show Inspector'),
                        subtitle: Text(
                          'Display WebF element inspector overlay',
                          style: theme.textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: applyManualUrl,
                              icon: const Icon(Icons.rocket_launch),
                              label: const Text('Launch'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: openScanner,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            // Open showcases from local HTTP server
                            final server = AssetHttpServer();
                            if (!server.isRunning) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Asset server not running'),
                                ),
                              );
                              return;
                            }

                            final showcaseUrl = '${server.baseUrl}/';
                            ref
                                .read(urlHistoryProvider.notifier)
                                .addUrl(showcaseUrl);
                            final routeUrl = buildWebFRouteUrl(
                              path: '/',
                              url: showcaseUrl,
                              title: 'Show Cases',
                            );
                            print(
                              '[LauncherPage] Opening showcases: $routeUrl',
                            );
                            context.push(
                              routeUrl,
                              extra: {'initial': true, 'url': showcaseUrl},
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.dashboard,
                                    size: 32,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Show Cases',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'React examples powered by WebF',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (urls != null && urls.isNotEmpty)
                        UrlHistoryList(onUrlTap: openWebF),
                    ],
                  ),
                ),
              ),
            ),
            if (showInspector) const WebFInspectorOverlay(),
          ],
        ),
      ),
    );
  }
}
