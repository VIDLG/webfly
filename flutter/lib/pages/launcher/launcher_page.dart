import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../hooks/use_route_focus.dart';
import '../../services/app_settings_service.dart';
import '../../services/url_history_service.dart';
import '../../services/asset_http_server.dart';
import '../../services/hybrid_controller_manager.dart';
import '../../utils/validators.dart';
import 'widgets/history_list.dart';
import '../../widgets/webf_inspector_overlay.dart';
import 'widgets/settings_button.dart';
import 'widgets/launcher_header.dart';
import 'widgets/launcher_inputs.dart';
import 'widgets/launch_button.dart';
import 'widgets/use_cases_card.dart';
import '../../router/config.dart'
    show kScannerPath, kUseCasesPath, kAppRoutePath, buildWebFRouteUrl;

class LauncherPage extends HookConsumerWidget {
  const LauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController = useTextEditingController();
    final pathController = useTextEditingController(text: '/');
    final errorMessage = useState<String?>(null);
    final showInspector = ref.watch(showWebfInspectorProvider);
    final cacheControllers = ref.watch(cacheControllersProvider);
    final urls = ref.watch(urlHistoryProvider).value;
    final isUrlHighlighted = useState(false);
    final historyListEditMode = useState(false);
    final historyListKey = useMemoized(() => GlobalKey());

    useEffect(() {
      if (urls == null || urls.isEmpty) return null;
      if (urlController.text.isEmpty) {
        // Fill with full URL (url + path)
        final firstEntry = urls.first;
        urlController.text =
            '${firstEntry.url}${firstEntry.path == '/' ? '' : firstEntry.path}';
        pathController.text = firstEntry.path;
      }
      return null;
    }, [urls, urlController, pathController]);

    // Monitor route focus and clean up controllers when returning to launcher
    final isRouteFocused = useRouteFocus();
    useEffect(() {
      if (isRouteFocused.value && !cacheControllers) {
        // Dispose all controllers when this page regains focus
        // This ensures clean state when returning from WebF pages
        HybridControllerManager.instance.disposeAll();
      }
      return null;
    }, [isRouteFocused.value, cacheControllers]);

    void openWebF(String url, [String? customPath]) {
      // Normalize URL: remove trailing slashes
      final normalizedUrl = url.endsWith('/')
          ? url.substring(0, url.length - 1)
          : url;
      final path = customPath ?? '/';

      ref.read(urlHistoryProvider.notifier).addEntry(normalizedUrl, path);
      errorMessage.value = null;

      // Always use hybrid routing mode (shared controller)
      final routeUrl = buildWebFRouteUrl(
        url: normalizedUrl,
        route: kAppRoutePath,
        path: path,
      );
      print(
        '[LauncherPage] Navigating to hybrid route: $routeUrl (path: $path)',
      );
      context.push(routeUrl, extra: {'initial': true, 'url': normalizedUrl});
    }

    void highlightUrlInput() {
      isUrlHighlighted.value = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        isUrlHighlighted.value = false;
      });
    }

    void handleEditModeChanged(bool editMode) {
      historyListEditMode.value = editMode;
      if (editMode) {
        Future.delayed(const Duration(milliseconds: 100), () {
          final context = historyListKey.currentContext;
          if (context != null) {
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
        // Fill URL field with complete URL
        urlController.text = '$url${path == '/' ? '' : path}';
        pathController.text = path;
        highlightUrlInput();
      }
    }

    void applyManualUrl() {
      final input = urlController.text.trim();
      if (input.isEmpty) {
        errorMessage.value = 'Please enter a URL';
        return;
      }

      // Parse URL to extract base URL and path
      try {
        final uri = Uri.parse(input);
        if (!uri.hasScheme || uri.host.isEmpty) {
          errorMessage.value = 'Please enter a valid http/https URL';
          return;
        }

        final baseUrl =
            '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
        final pathFromUrl = uri.path.isEmpty || uri.path == '/'
            ? '/'
            : uri.path;

        // Path priority:
        // 1. If user manually edited path in Advanced (not default '/'), use it
        // 2. Otherwise use path from URL
        final pathInput = pathController.text.trim();
        final finalPath = (pathInput.isNotEmpty && pathInput != '/')
            ? pathInput
            : pathFromUrl;

        openWebF(baseUrl, finalPath);
      } catch (_) {
        errorMessage.value = 'Please enter a valid URL';
      }
    }

    final theme = Theme.of(context);

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
          actions: const [LauncherSettingsButton()],
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
                        if (urls != null && urls.isNotEmpty)
                          UrlHistoryList(
                            key: historyListKey,
                            onOpen: (url, path) => openWebF(url, path),
                            onTap: (url, path) {
                              // Fill with complete URL for editing
                              urlController.text =
                                  '$url${path == '/' ? '' : path}';
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
