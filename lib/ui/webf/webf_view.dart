import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:webf/webf.dart';
import 'package:anyhow/anyhow.dart';
import '../../config.dart';
import '../../errors.dart';
import '../../store/app_settings.dart';
import '../../utils/app_logger.dart';
import '../../utils/network.dart';
import '../router/app_router.dart';
import '../widgets/webfly_loading.dart';

void _syncThemeToWebF(WebFController controller, ThemeMode themeMode) {
  // WebF automatically syncs with system theme when themeMode is ThemeMode.system.
  // We only need to set darkModeOverride when user explicitly chooses light or dark.
  switch (themeMode) {
    case ThemeMode.light:
      controller.darkModeOverride = false;
      break;
    case ThemeMode.dark:
      controller.darkModeOverride = true;
      break;
    case ThemeMode.system:
      // Clear override to let WebF automatically sync with system theme.
      controller.darkModeOverride = null;
      break;
  }
  // Ensure frontend receives theme change: WebF may not always dispatch
  // 'colorschemchange', so we dispatch it from Flutter after setting darkModeOverride.
  try {
    unawaited(
      controller.view
          .evaluateJavaScripts(
            "try { var e = new Event('colorschemchange'); window.dispatchEvent(e); document.dispatchEvent(e); } catch (err) {}",
          )
          .catchError(
            (e, st) => appLogger.w(
              '[WebFView] colorschemchange dispatch failed: $e\n$st',
            ),
          ),
    );
  } catch (e, st) {
    appLogger.w('[WebFView] evaluateJavaScripts for theme failed: $e\n$st');
  }
}

bool _canResolveHybridRoute(
  WebFController controller, {
  required String fullPath,
  required String pathOnly,
}) {
  try {
    final dynamic dynamicController = controller;
    final dynamic view = dynamicController.view;
    final dynamic result = view.getHybridRouterView(pathOnly);
    return result != null;
  } catch (e) {
    appLogger.d('[WebFView] Hybrid route check failed: $e');
    return false;
  }
}

/// Injects a WebF bundle and returns a Result type.
///
/// Theme sync is not done here; the caller should set [WebFController.onLoad]
/// (and sync when [ThemeMode] changes) so theme is applied after load.
Future<Result<WebFController>> injectWebfBundleAsync({
  required String controllerName,
  required String url,
  void Function(String)? onJSRuntimeError,
  Duration? timeout,
}) async {
  try {
    WebFController? controller = await WebFControllerManager.instance
        .addWithPrerendering(
          name: controllerName,
          createController: () => WebFController(
            routeObserver: kWebfRouteObserver,
            onJSError: (String errorMessage) {
              appLogger.e(
                '❌ JavaScript Error in: $controllerName\n$errorMessage',
                error: errorMessage,
              );
              onJSRuntimeError?.call(errorMessage);
            },
          ),
          bundle: WebFBundle.fromUrl(url),
          timeout: timeout,
          setup: (controller) {
            controller.hybridHistory.delegate = kGoRouterDelegate;
          },
        );

    // WebFControllerManager may return null due to concurrency rules (another request won).
    // In that case, fetch the winner controller.
    controller ??= await WebFControllerManager.instance.getController(
      controllerName,
    );

    if (controller == null) {
      return webfControllerError<WebFController>(
        message: 'Controller initialization returned null',
        controllerName: controllerName,
        url: url,
      );
    }

    return Ok(controller);
  } catch (e, stackTrace) {
    return webfControllerError<WebFController>(
      cause: e,
      controllerName: controllerName,
      url: url,
      stackTrace: stackTrace,
    );
  }
}

/// Default loading widget for WebF view
Widget _defaultLoadingWidget() {
  return const WebFlyLoading(message: 'Loading...');
}

/// Default error widget for WebF view
Widget _defaultErrorWidget(Object? error) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(error?.toString() ?? 'Unknown error', textAlign: TextAlign.center),
      ],
    ),
  );
}

class _JavaScriptRuntimeErrorView extends StatelessWidget {
  const _JavaScriptRuntimeErrorView({
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'JavaScript Runtime Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: SelectableText(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pure WebF view widget without Scaffold or AppBar.
///
/// This widget handles WebF controller lifecycle, route focus monitoring,
/// and displays loading/error states. It's designed to be composed into
/// larger page structures rather than being a complete page itself.
class WebFView extends HookWidget {
  const WebFView({
    super.key,
    required this.url,
    required this.controllerName,
    this.routePath = '/',
    this.loadingBuilder,
    this.errorBuilder,
    this.controllerLoadingTimeout,
    this.hybridRouteResolutionTimeout,
    this.hybridRoutePollInterval,
  });

  final String url;
  final String controllerName;
  final String routePath;

  /// Optional custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional custom error widget builder
  final Widget Function(BuildContext, Object?)? errorBuilder;

  /// Timeout for controller loading.
  /// Defaults to 15 seconds.
  final Duration? controllerLoadingTimeout;

  /// Timeout for hybrid route resolution.
  /// Defaults to 10 seconds.
  final Duration? hybridRouteResolutionTimeout;

  /// Polling interval for checking hybrid route resolution.
  /// Defaults to 50 milliseconds.
  final Duration? hybridRoutePollInterval;

  @override
  Widget build(BuildContext context) {
    final jsRuntimeError = useSignal<String?>(
      null,
    ); // JavaScript runtime errors
    final didMountRootWebF = useRef(false);
    final hybridRouteReady = useSignal(false);
    final hybridRouteTimeoutError = useSignal<Object?>(null);
    final hybridRouteTimeoutGen = useRef(0);
    final cacheControllers = useSignalValue(cacheControllersSignal);
    final themeMode = useSignalValue(themeModeSignal);

    final pathOnlyResult = extractPathOnly(routePath);
    final Object? routePathParseError = pathOnlyResult.isErr()
        ? pathOnlyResult.unwrapErr()
        : null;
    // Keep hook ordering stable: avoid early returns before all hooks.
    // Use a safe placeholder value; UI will prioritize routePathParseError.
    final String pathOnly = routePathParseError == null
        ? pathOnlyResult.unwrap()
        : '/';
    final bool isRootPath = pathOnly == '/';

    // Build controller via FutureSignal so loading/error/data is centralized.
    // Using `lazy: false` ensures the injection starts even if the widget returns early.
    final generation = useRef(0);
    final controllerFuture = useFutureSignal<WebFController>(
      () async {
        final localGen = ++generation.value;

        // Clear previous JS errors for the new load attempt.
        jsRuntimeError.value = null;

        // Reuse existing controller if already present.
        final existing = WebFControllerManager.instance.getControllerSync(
          controllerName,
        );
        if (existing != null && !existing.disposed) {
          // Keep delegate wired even across rebuilds.
          existing.hybridHistory.delegate = kGoRouterDelegate;
          return existing;
        }

        final timeout =
            controllerLoadingTimeout ?? kDefaultControllerLoadingTimeout;

        final result = await injectWebfBundleAsync(
          controllerName: controllerName,
          url: url,
          timeout: timeout,
          onJSRuntimeError: (errorMessage) {
            if (!context.mounted) return;
            // Ignore stale callbacks from previous loads.
            if (generation.value != localGen) return;
            jsRuntimeError.value = errorMessage;
          },
        );

        return result.match(
          ok: (controller) => controller,
          err: (error) {
            // Log additional business context for debugging.
            appLogger.d(
              '[WebFView] Error context',
              error:
                  'route=$routePath, controller=$controllerName, '
                  'url=$url, timeout=${timeout.inSeconds}s, '
                  'cacheControllers=$cacheControllers, '
                  'waitForHybridRoute=${routePath != '/'}',
            );

            // Preserve anyhow error chain + contexts.
            throw error;
          },
        );
      },
      keys: [controllerName, url],
      // If routePath is invalid, don't start controller work.
      lazy: routePathParseError != null,
      debugLabel: 'WebFView($controllerName)',
    );

    final controllerState = controllerFuture.value;
    final controller = controllerState.map(
      data: (c) => c,
      loading: () => null,
      error: (_, _) => null,
    );
    final initError = controllerState.map(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error,
    );

    final hasController = controller != null;
    final shouldMountWebF =
        hasController &&
        (isRootPath || controller.state == null || didMountRootWebF.value);

    // Deep-link bootstrap: before mounting WebF with an initialRoute != '/', try to
    // wait until WebF can resolve the hybrid router view. This avoids transient
    // "Loading Error: the route path ... was not found" during router registration.
    final shouldWaitForHybridRoute =
        shouldMountWebF && !isRootPath && !didMountRootWebF.value;

    // Sync theme to WebF when themeMode or controller changes; set onLoad so
    // theme is dispatched again when the page loads (frontend can then listen).
    useEffect(() {
      if (controller != null) {
        _syncThemeToWebF(controller, themeMode);
        controller.onLoad = (ctrl) => _syncThemeToWebF(ctrl, themeMode);
      }
      return null;
    }, [themeMode, controller]);

    // Disposal policy:
    // Only an instance that actually mounted a WebF widget (via WebF.fromControllerName)
    // is considered the owner of the controller lifecycle.
    useEffect(() {
      final controllerNameForDispose = controllerName;
      final shouldCacheControllersForDispose = cacheControllers;

      return () {
        if (!shouldCacheControllersForDispose && didMountRootWebF.value) {
          unawaited(
            WebFControllerManager.instance.removeAndDisposeController(
              controllerNameForDispose,
            ),
          );
        }
      };
    }, [controllerName, cacheControllers]);

    // Wait for hybrid router view to be resolvable before mounting WebF for deep-link.
    // Use a timer signal to drive polling without manual Timer management.
    final routeTimeout =
        hybridRouteResolutionTimeout ?? kDefaultHybridRouteResolutionTimeout;
    final pollInterval =
        hybridRoutePollInterval ?? kDefaultHybridRoutePollInterval;

    final hybridPollTick =
        useExistingSignal<AsyncState<TimerSignalEvent>, TimerSignal>(
          timerSignal(
            pollInterval,
            debugLabel: 'WebFView($controllerName) HybridPoll',
            autoDispose: true,
          ),
          keys: [pollInterval, controllerName],
        );

    final hybridReadyComputed = useComputed<bool>(
      () {
        if (!hasController) return false;
        if (!shouldWaitForHybridRoute) return true;

        // Subscribe to ticks while waiting.
        hybridPollTick();

        final ctrl = controller;
        return _canResolveHybridRoute(
          ctrl,
          fullPath: routePath,
          pathOnly: pathOnly,
        );
      },
      keys: [hasController, shouldWaitForHybridRoute, controller, routePath],
      debugLabel: 'WebFView($controllerName) HybridReady',
    );

    // Drive state + timeout based on the computed readiness.
    useSignalEffect(() {
      if (!hasController) {
        hybridRouteReady.value = false;
        hybridRouteTimeoutError.value = null;
        return;
      }

      if (!shouldWaitForHybridRoute) {
        hybridRouteReady.value = true;
        hybridRouteTimeoutError.value = null;
        return;
      }

      // Clear any previous timeout error for a new attempt.
      hybridRouteTimeoutError.value = null;

      final readyNow = hybridReadyComputed.value;
      if (hybridRouteReady.value != readyNow) {
        hybridRouteReady.value = readyNow;
      }

      if (readyNow) return;

      final localGen = ++hybridRouteTimeoutGen.value;
      unawaited(() async {
        await Future<void>.delayed(routeTimeout);
        if (!context.mounted) return;
        if (hybridRouteTimeoutGen.value != localGen) return;
        if (hybridRouteReady.value) return;

        final result = routeResolutionError<void>(
          message: 'Hybrid route resolution timeout',
          routePath: routePath,
          controllerName: controllerName,
        );
        final error = result.unwrapErr();

        // Log additional business context for debugging
        appLogger.d(
          '[WebFView] Route timeout context',
          error:
              'route=$routePath, controller=$controllerName, '
              'pollInterval=${pollInterval.inMilliseconds}ms, '
              'timeout=${routeTimeout.inSeconds}s',
        );

        // Preserve anyhow error chain + contexts for UI/debug.
        hybridRouteTimeoutError.value = error;
      }());
    });

    // If we decided to mount root WebF, mark ownership without triggering rebuilds.
    // This is used for lifecycle ownership and to avoid branch-flips later.
    if (shouldMountWebF &&
        (!shouldWaitForHybridRoute || hybridRouteReady.value)) {
      didMountRootWebF.value = true;
    }

    final routeOrInitOrTimeoutError =
        routePathParseError ?? initError ?? hybridRouteTimeoutError.value;
    if (routeOrInitOrTimeoutError != null) {
      return errorBuilder?.call(context, routeOrInitOrTimeoutError) ??
          _defaultErrorWidget(routeOrInitOrTimeoutError);
    }

    if (jsRuntimeError.value != null) {
      return _JavaScriptRuntimeErrorView(
        message: jsRuntimeError.value!,
        onClose: () => jsRuntimeError.value = null,
      );
    }

    if (controller == null ||
        (shouldWaitForHybridRoute && !hybridRouteReady.value)) {
      return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
    }

    // Memoize WebF widget so we don't create a new instance on every build.
    // Otherwise webf package may re-run load and log "WebF: loading with controller" repeatedly.
    final webFWidget = useMemoized(
      () => WebF.fromControllerName(
        controllerName: controllerName,
        initialRoute: pathOnly,
        loadingWidget: loadingBuilder?.call(context) ?? _defaultLoadingWidget(),
        errorBuilder: (context, error) {
          final resolvedError =
              errorBuilder?.call(context, error) ?? _defaultErrorWidget(error);
          return resolvedError;
        },
      ),
      [controllerName, pathOnly],
    );

    if (shouldMountWebF) {
      return webFWidget;
    }

    return WebFRouterView(
      controller: controller,
      path: pathOnly,
      defaultViewBuilder: (context) {
        return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
      },
    );
  }
}
