import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webf/launcher.dart' show WebFControllerManager;
import '../../hooks/use_route_focus.dart';
import '../../services/app_settings_service.dart';
import '../../services/url_history_service.dart';
import '../../utils/app_logger.dart';
import 'widgets/history_list.dart';
import '../../widgets/webf_inspector_overlay.dart';
import 'widgets/settings.dart';
import 'widgets/launcher_header.dart';
import 'widgets/launcher_inputs.dart';
import 'widgets/launch_button.dart';
import 'widgets/use_cases_card.dart';
import '../../router/config.dart'
  show kScannerPath, kNativeDiagnosticsPath, kAppRoutePath, buildWebFRouteUrl;

class LauncherScreen extends HookWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final urlController = useTextEditingController();
    final pathController = useTextEditingController(text: '/');
    final errorMessage = useState<String?>(null);
    final cacheControllers = cacheControllersSignal.watch(context);
    final urls = urlHistorySignal.watch(context);
    final isUrlHighlighted = useState(false);
    final historyListEditMode = useState(false);
    final historyListKey = useMemoized(() => GlobalKey());
    final urlInputKey = useMemoized(() => GlobalKey());

    useEffect(() {
      if (urls.isEmpty) return null;
      if (urlController.text.isEmpty) {
        // Default to first entry
        final firstEntry = urls.first;
        urlController.text = firstEntry.url;
        pathController.text = firstEntry.path;
      }
      return null;
    }, [urls, urlController, pathController]);

    // Safety-net: when caching is disabled, fully clean up WebF controllers
    // when returning to launcher. The primary disposal path is per-WebFView
    // unmount, but this catches edge cases (aborted routes, unexpected rebuilds).
    final isRouteFocused = useRouteFocus();
    useEffect(() {
      if (isRouteFocused.value && !cacheControllers) {
        appLogger.d('[LauncherScreen] Cache disabled: disposing all WebF controllers');
        WebFControllerManager.instance.disposeAll();
      }
      return null;
    }, [isRouteFocused.value, cacheControllers]);

    void openWebF(String url, [String? customPath]) {
      // Normalize URL: Use the input as single source of truth
      final normalizedUrl = url;
      // We always treat the input as the full URL, so path is default '/'
      // The user sees the full URL in the history and inputs.
      final path = customPath ?? '/';

      UrlHistoryOperations.addEntry(normalizedUrl, path);
      errorMessage.value = null;

      // Always use hybrid routing mode (shared controller)
      final routeUrl = buildWebFRouteUrl(
        url: normalizedUrl,
        route: kAppRoutePath,
        path: path,
      );
      appLogger.d(
        '[LauncherScreen] Navigating to hybrid route: $routeUrl (path: $path)',
      );
      context.push(routeUrl, extra: {'initial': true, 'url': normalizedUrl});
    }

    void highlightUrlInput() {
      isUrlHighlighted.value = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        isUrlHighlighted.value = false;
      });

      // Scroll to input field and center it
      Future.delayed(const Duration(milliseconds: 50), () {
        final context = urlInputKey.currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3, // Center the input field (30% from top)
          );
        }
      });
    }

    void handleEditModeChanged(bool editMode) {
      historyListEditMode.value = editMode;
      if (editMode) {
        Future.delayed(const Duration(milliseconds: 100), () {
          final context = historyListKey.currentContext;
          if (context != null && context.mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
      }
    }

    Future<void> openScanner() async {
      final result = await context.push<Map<String, String>>(kScannerPath);
      if (result != null) {
        final url = result['url'] ?? '';
        final path = result['path'] ?? '/';
        // Fill URL field with complete URL including path
        urlController.text = '$url${path == '/' ? '' : path}';
        highlightUrlInput();
      }
    }

    void applyManualUrl() {
      final input = urlController.text.trim();
      if (input.isEmpty) {
        errorMessage.value = 'Please enter a URL';
        return;
      }

      // Parse URL
      try {
        final uri = Uri.parse(input);
        if (!uri.hasScheme || uri.host.isEmpty) {
          errorMessage.value = 'Please enter a valid http/https URL';
          return;
        }

        // Use the input as the full bundle URL
        final baseUrl = input;

        // Path priority:
        // 1. If user manually edited path in Advanced (not default '/'), use it
        // 2. Otherwise default to '/'
        final pathInput = pathController.text.trim();
        final finalPath = (pathInput.isNotEmpty) ? pathInput : '/';

        openWebF(baseUrl, finalPath);
      } catch (_) {
        errorMessage.value = 'Please enter a valid URL';
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If in edit mode, exit edit mode instead of app
        if (historyListEditMode.value) {
          // Signal to exit edit mode
          historyListEditMode.value = false;
          return;
        }

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
        appBar: AppBar(
          title: const Text('WebFly'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Native diagnostics',
              onPressed: () => context.push(kNativeDiagnosticsPath),
              icon: const Icon(Icons.monitor_heart_outlined),
            ),
            const LauncherSettingsButton(),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            // Dismiss keyboard and unfocus when tapping outside
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const LauncherHeader(),
                        const SizedBox(height: 20),
                        LauncherUrlInputSection(
                          key: urlInputKey,
                          urlController: urlController,
                          pathController: pathController,
                          errorMessage: errorMessage.value,
                          isHighlighted: isUrlHighlighted.value,
                          onClear: () {
                            urlController.clear();
                            pathController.text = '/';
                            errorMessage.value = null;
                          },
                          onSubmitted: (_) => applyManualUrl(),
                          onScan: openScanner,
                        ),
                        const SizedBox(height: 16),
                        LauncherButton(onLaunch: applyManualUrl),
                        const SizedBox(height: 24),
                        const LauncherUseCasesCard(),
                        const SizedBox(height: 24),
                        if (urls.isNotEmpty)
                          UrlHistoryList(
                            key: historyListKey,
                            onOpen: (url, path) => openWebF(url, path),
                            onTap: (url, path) {
                              urlController.text = url;
                              pathController.text = path;
                              highlightUrlInput();
                            },
                            onLongPress: (url, path) {},
                            onEditModeChanged: handleEditModeChanged,
                            editModeNotifier: historyListEditMode,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const WebFInspectorOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
