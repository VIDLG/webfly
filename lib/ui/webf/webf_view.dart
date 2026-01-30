import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:webf/launcher.dart' show WebFController, WebFControllerManager;
import 'package:webf/webf.dart' show WebFBundle;
import 'package:webf/widget.dart' show WebF, WebFRouterView;
import '../router/app_router.dart' show kGoRouterDelegate, kWebfRouteObserver;
import '../../services/app_settings_service.dart' show cacheControllersSignal, themeModeSignal;
import '../../utils/app_logger.dart';
import '../../config.dart' show
    kDefaultControllerLoadingTimeout,
    kDefaultHybridRouteResolutionTimeout,
    kDefaultHybridRoutePollInterval;
import 'package:anyhow/anyhow.dart';
import '../../errors.dart' show
    extractAppError,
    routeResolutionError,
    TimeoutError,
    webfControllerError;
import '../../utils/network.dart' show extractPathOnly;
import 'webf_theme_sync.dart' show syncThemeToWebF;
import '../widgets/webfly_loading.dart';

bool _canResolveHybridRoute(WebFController controller, String routePath) {
  try {
    // WebF router only matches the path component, not query string or fragment
    final pathOnly = extractPathOnly(routePath);
    final dynamic dynamicController = controller;
    final dynamic view = dynamicController.view;
    final dynamic result = view.getHybridRouterView(pathOnly);
    final canResolve = result != null;
    if (!canResolve && routePath != pathOnly) {
      appLogger.d(
        '[WebFView] Hybrid route check: fullPath=$routePath, pathOnly=$pathOnly, canResolve=$canResolve',
      );
    }
    return canResolve;
  } catch (e) {
    appLogger.d('[WebFView] Hybrid route check failed: $e');
    return false;
  }
}

/// Injects a WebF bundle and returns a Result type
Future<Result<WebFController>> injectWebfBundleAsync({
  required String controllerName,
  required String url,
  void Function(String)? onJSRuntimeError,
  Duration? timeout,
}) async {
  appLogger.d('[WebFView] Injecting: controller=$controllerName, url=$url');

  try {
    WebFController? controller = await WebFControllerManager.instance.addWithPrerendering(
      name: controllerName,
      createController: () => WebFController(
        routeObserver: kWebfRouteObserver,
        onJSError: (String errorMessage) {
          // Log full error stack
          appLogger.e(
            '❌ JavaScript Error in: $controllerName\n$errorMessage',
            error: errorMessage,
          );

          // Update UI state to show the error
          onJSRuntimeError?.call(errorMessage);
        },
      ),
      bundle: WebFBundle.fromUrl(url),
      timeout: timeout,
      setup: (controller) {
        controller.hybridHistory.delegate = kGoRouterDelegate;
        
        // Sync initial Flutter theme state to WebF using darkModeOverride
        // Following WebF official recommendation
        syncThemeToWebF(controller, themeModeSignal.value);
        
        appLogger.d('[WebFView] Controller setup complete');
      },
    );

    // WebFControllerManager may return null due to concurrency rules (another request won).
    // In that case, fetch the winner controller.
    controller ??= await WebFControllerManager.instance.getController(controllerName);

    if (controller == null) {
      return webfControllerError<WebFController>(
        message: 'Controller initialization returned null',
        controllerName: controllerName,
        url: url,
      );
    }

    appLogger.d('[WebFView] Bundle injection complete');
    return Ok(controller);
  } catch (e, stackTrace) {
    return webfControllerError<WebFController>(
      error: e,
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
    this.cacheController,
    this.loadingBuilder,
    this.errorBuilder,
    this.controllerLoadingTimeout,
    this.hybridRouteResolutionTimeout,
    this.hybridRoutePollInterval,
  });

  final String url;
  final String controllerName;
  final String routePath;

  /// Whether to cache the underlying WebF controller.
  ///
  /// - `true`: keep controller alive across navigation.
  /// - `false`: dispose controller when this view is unmounted.
  /// - `null` (default): follow global `cacheControllersSignal`.
  final bool? cacheController;

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
    final initError = useState<Object?>(null);
    final jsRuntimeError = useState<String?>(null); // JavaScript runtime errors
    final controllerState = useState<WebFController?>(null);
    final didMountRootWebF = useRef(false);
    final hybridRouteReady = useState(false);
    final timeoutError = useState<String?>(null);
    final cacheControllers = cacheController ?? cacheControllersSignal.watch(context);

    final controller = controllerState.value;
    final hasController = controller != null;
    final shouldMountWebF = hasController &&
      (routePath == '/' ||
        controller.state == null ||
        didMountRootWebF.value);

    // Deep-link bootstrap: before mounting WebF with an initialRoute != '/', try to
    // wait until WebF can resolve the hybrid router view. This avoids transient
    // "Loading Error: the route path ... was not found" during router registration.
    final shouldWaitForHybridRoute =
      shouldMountWebF && routePath != '/' && !didMountRootWebF.value;

    useEffect(() {
      var cancelled = false;
      controllerState.value = null;
      initError.value = null;
      jsRuntimeError.value = null;
      timeoutError.value = null;

      final controllerNameForEffect = controllerName;

      Future<void> run() async {
        // Reuse existing controller if already present.
        final existing = WebFControllerManager.instance.getControllerSync(
          controllerNameForEffect,
        );
        if (existing != null && !existing.disposed) {
          // Keep delegate wired even across rebuilds.
          existing.hybridHistory.delegate = kGoRouterDelegate;
          controllerState.value = existing;
          return;
        }

        final timeout = controllerLoadingTimeout ?? kDefaultControllerLoadingTimeout;

        final result = await injectWebfBundleAsync(
          controllerName: controllerNameForEffect,
          url: url,
          timeout: timeout,
          onJSRuntimeError: (errorMessage) {
            if (!cancelled && context.mounted) {
              jsRuntimeError.value = errorMessage;
            }
          },
        );

        if (cancelled) return;
        if (!context.mounted) return;

        result.match(
          ok: (controller) {
            controllerState.value = controller;
          },
          err: (error) {
            // Extract AppError if possible for better error messages
            // Base error is already logged in errors.dart at creation point
            final appError = extractAppError(error);
            final errorMessage = appError?.toString() ?? error.toString();
            
            // Log additional business context for debugging
            appLogger.d(
              '[WebFView] Error context',
              error: 'route=$routePath, controller=$controllerNameForEffect, '
                  'url=$url, timeout=${timeout.inSeconds}s, '
                  'cacheControllers=$cacheControllers, '
                  'waitForHybridRoute=$shouldWaitForHybridRoute',
            );
            
            initError.value = errorMessage;
            
            // Check if it's a timeout error
            if (appError is TimeoutError) {
              timeoutError.value = errorMessage;
            }
          },
        );
      }

      run();
      return () {
        cancelled = true;
      };
    }, [controllerName, url]);

    // Sync Flutter theme changes to WebF
    useEffect(() {
      if (controller == null) return null;

      // Initial sync
      syncThemeToWebF(controller, themeModeSignal.value);

      // Listen to theme changes - effect automatically disposes when controller changes
      effect(() {
        final themeMode = themeModeSignal.value;
        syncThemeToWebF(controller, themeMode);
      });

      return null;
    }, [controller]);

    // Theme synchronization from WebF → Flutter is now handled via Native Module
    // JavaScript calls webf.invokeModule('Theme', 'setTheme', ['light'|'dark'|'system'])
    // No polling needed - direct method call is more efficient

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
    // This effect is always registered to satisfy hooks ordering; it no-ops when not needed.
    useEffect(() {
      if (!hasController) {
        hybridRouteReady.value = false;
        return null;
      }

      if (!shouldWaitForHybridRoute) {
        hybridRouteReady.value = true;
        return null;
      }

      final ctrl = controller;

      hybridRouteReady.value = _canResolveHybridRoute(ctrl, routePath);
      if (hybridRouteReady.value) {
        return null;
      }

      final routeTimeout = hybridRouteResolutionTimeout ?? kDefaultHybridRouteResolutionTimeout;
      final pollInterval = hybridRoutePollInterval ?? kDefaultHybridRoutePollInterval;

      // Set up timeout for hybrid route resolution
      final timeoutTimer = Timer(routeTimeout, () {
        if (!context.mounted) return;
        if (!hybridRouteReady.value) {
          final result = routeResolutionError<void>(
            message: 'Hybrid route resolution timeout',
            routePath: routePath,
            controllerName: controllerName,
          );
          // Error is already logged in errors.dart at creation point
          final errorMessage = result.unwrapErr().toString();
          
          // Log additional business context for debugging
          appLogger.d(
            '[WebFView] Route timeout context',
            error: 'route=$routePath, controller=$controllerName, '
                'pollInterval=${pollInterval.inMilliseconds}ms, '
                'timeout=${routeTimeout.inSeconds}s',
          );
          
          timeoutError.value = errorMessage;
        }
      });

      final poll = Timer.periodic(pollInterval, (timer) {
        if (!context.mounted) {
          timer.cancel();
          timeoutTimer.cancel();
          return;
        }

        final ready = _canResolveHybridRoute(ctrl, routePath);
        if (ready && !hybridRouteReady.value) {
          hybridRouteReady.value = true;
          timer.cancel();
          timeoutTimer.cancel();
        }
      });

      return () {
        poll.cancel();
        timeoutTimer.cancel();
      };
    }, [hasController, shouldWaitForHybridRoute, controller, routePath, controllerName]);

    appLogger.d(
      '[WebFView] build: controller=$controllerName, path=$routePath, url=$url',
    );
    // Error is already logged in errors.dart at creation point

    // If we decided to mount root WebF, mark ownership without triggering rebuilds.
    // This is used for lifecycle ownership and to avoid branch-flips later.
    if (shouldMountWebF && (!shouldWaitForHybridRoute || hybridRouteReady.value)) {
      didMountRootWebF.value = true;
    }

    final runtimeErrorMessage = jsRuntimeError.value;
    final timeoutMsg = timeoutError.value;

    if (initError.value != null) {
      return errorBuilder?.call(context, initError.value) ??
          _defaultErrorWidget(initError.value);
    }

    if (timeoutMsg != null) {
      return errorBuilder?.call(context, timeoutMsg) ??
          _defaultErrorWidget(timeoutMsg);
    }

    if (runtimeErrorMessage != null) {
      return _JavaScriptRuntimeErrorView(
        message: runtimeErrorMessage,
        onClose: () => jsRuntimeError.value = null,
      );
    }

    if (controller == null) {
      return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
    }

    if (shouldWaitForHybridRoute && !hybridRouteReady.value) {
      return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
    }

    return shouldMountWebF
        ? WebF.fromControllerName(
            controllerName: controllerName,
            // If deep-linking directly to a sub-route, let WebF build the hybrid view.
            // WebF's initialRoute only accepts the path component (without query string).
            // Query string (e.g., ?css=0) is automatically available via window.location.search
            // in the frontend, so we only pass the path part here.
            initialRoute: extractPathOnly(routePath),
            loadingWidget: loadingBuilder?.call(context) ?? _defaultLoadingWidget(),
            errorBuilder: (context, error) {
              final resolvedError = errorBuilder?.call(context, error) ??
                  _defaultErrorWidget(error);

              return resolvedError;
            },
          )
        : WebFRouterView(
            controller: controller,
            // WebFRouterView's path parameter should only contain the path component,
            // not query string or fragment. The query string is available via window.location.search.
            path: extractPathOnly(routePath),
            defaultViewBuilder: (context) {
              return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
            },
          );
  }
}
