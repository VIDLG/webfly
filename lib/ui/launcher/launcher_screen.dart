import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webf/launcher.dart';
import '../hooks/use_route_focus.dart';
import '../../store/app_settings.dart';
import '../../store/update_checker.dart';
import '../../store/url_history.dart';
import '../../utils/app_logger.dart';
import 'widgets/history_list.dart';
import '../webf/webf_inspector_overlay.dart';
import 'widgets/launcher_header.dart';
import 'widgets/launcher_inputs.dart';
import 'widgets/launch_button.dart';
import 'widgets/use_cases_card.dart';
import 'package:webfly_webf_view/webfly_webf_view.dart'
    show normalizeWebfInnerPath;
import '../router/config.dart'
    show
        settingsPath,
        scannerPath,
        nativeDiagnosticsPath,
        aboutPath,
        appRoutePath,
        buildWebFRouteUrl;

class LauncherScreen extends HookWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final urlController = useTextEditingController();
    final pathController = useTextEditingController(text: '/');
    final errorMessage = useState<String?>(null);
    final cacheControllers = cacheControllersSignal.watch(context);
    final urls = urlHistorySignal.watch(context);
    final hasUpdate = hasUpdateSignal.watch(context);
    final isUrlHighlighted = useBoolean(false);
    final historyListEditMode = useSignal(false);
    final requestExitEditModeRef = useRef<void Function()?>(null);
    final historyListKey = useMemoized(() => GlobalKey());
    final urlInputKey = useMemoized(() => GlobalKey());

    // Auto-clear the highlight after a short delay, with timer lifecycle managed
    // by hooks (prevents delayed callbacks firing after unmount).
    useDebounce(
      () {
        if (isUrlHighlighted.value) isUrlHighlighted.toggle(false);
      },
      const Duration(milliseconds: 800),
      [isUrlHighlighted.value],
    );

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
        talker.debug(
          '[LauncherScreen] Cache disabled: disposing all WebF controllers',
        );
        WebFControllerManager.instance.disposeAll();
      }
      return null;
    }, [isRouteFocused.value, cacheControllers]);

    void openWebF(String url, [String? customPath]) {
      // Normalize URL: Use the input as single source of truth
      final normalizedUrl = url;
      // We always treat the input as the full URL, so path is default '/'
      // The user sees the full URL in the history and inputs.
      final path = normalizeWebfInnerPath(customPath ?? '/');

      addUrlHistoryEntry(normalizedUrl, path);
      errorMessage.value = null;

      // Always use hybrid routing mode (shared controller)
      final routeUrl = buildWebFRouteUrl(
        url: normalizedUrl,
        route: appRoutePath,
        path: path,
      );
      talker.debug(
        '[LauncherScreen] Navigating to hybrid route: $routeUrl (path: $path)',
      );
      context.push(routeUrl, extra: {'initial': true, 'url': normalizedUrl});
    }

    void highlightUrlInput() {
      isUrlHighlighted.toggle(true);

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
      final result = await context.push<Map<String, String>>(scannerPath);
      if (result != null) {
        final url = result['url'] ?? '';
        final path = result['path'] ?? '/';
        // Keep bundle URL and inner route separate (hybrid routing uses `path=`).
        urlController.text = url;
        pathController.text = normalizeWebfInnerPath(path);
        highlightUrlInput();
      }
    }

    String maybeStripInnerRouteFromBundleUrl(
      Uri bundleUri,
      String innerLocation,
    ) {
      if (innerLocation.isEmpty || innerLocation == '/') {
        return bundleUri.toString();
      }

      Uri inner;
      try {
        inner = Uri.parse(
          innerLocation.startsWith('/') ? innerLocation : '/$innerLocation',
        );
      } catch (_) {
        return bundleUri.toString();
      }

      final innerPath = inner.path;
      if (innerPath.isEmpty || innerPath == '/') {
        return bundleUri.toString();
      }

      final bundlePath = bundleUri.path;
      if (!bundlePath.endsWith(innerPath)) {
        return bundleUri.toString();
      }

      var newPath = bundlePath.substring(
        0,
        bundlePath.length - innerPath.length,
      );
      if (newPath.isEmpty) newPath = '/';

      // If the bundle URL query exactly matches the inner route query, it's
      // almost certainly accidental; strip it.
      final shouldStripQuery = bundleUri.query == inner.query;
      final fixed = bundleUri.replace(
        path: newPath,
        query: shouldStripQuery ? null : bundleUri.query,
        fragment: bundleUri.fragment,
      );
      return fixed.toString();
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

        // Path priority:
        // 1. If user manually edited path in Advanced (not default '/'), use it
        // 2. Otherwise default to '/'
        final pathInput = pathController.text.trim();
        final finalPath = normalizeWebfInnerPath(pathInput);

        // Use the input as the full bundle URL.
        // Back-compat: if the user accidentally put the inner route into the URL
        // (e.g. `http://host/route/.../led?css=0`), strip it back out.
        final baseUrl = maybeStripInnerRouteFromBundleUrl(uri, finalPath);

        openWebF(baseUrl, finalPath);
      } catch (_) {
        errorMessage.value = 'Please enter a valid URL';
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If in edit mode, ask child to exit edit mode instead of app
        if (historyListEditMode.value) {
          requestExitEditModeRef.value?.call();
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
            PopupMenuButton<String>(
              icon: Badge(
                isLabelVisible: hasUpdate,
                smallSize: 8,
                child: const Icon(Icons.add_circle_outline),
              ),
              tooltip: 'More',
              onSelected: (value) => context.push(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: settingsPath,
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: nativeDiagnosticsPath,
                  child: ListTile(
                    leading: Icon(Icons.monitor_heart_outlined),
                    title: Text('Diagnostics'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: aboutPath,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    trailing: hasUpdate
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          )
                        : null,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
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
                            onRegisterExitEditMode: (requestExit) {
                              requestExitEditModeRef.value = requestExit;
                            },
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
