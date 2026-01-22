import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useEffect, useState;
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show HookConsumerWidget, WidgetRef;
import 'package:webf/launcher.dart' show WebFController, WebFControllerManager;
import 'package:webf/webf.dart' show WebFBundle;
import 'package:webf/widget.dart' show WebFRouterView;
import '../hooks/use_route_focus.dart';
import '../services/hybrid_controller_manager.dart';
import '../router/app_router.dart' show kGoRouterDelegate, kWebfRouteObserver;
import '../utils/app_logger.dart';

Future<WebFController?> injectWebfBundleAsync({
  required String controllerName,
  required String url,
}) async {
  appLogger.d(
    '[WebFView] Injecting bundle for controller: $controllerName\n  URL: $url',
  );

  try {
    final controller = await WebFControllerManager.instance.addWithPrerendering(
      name: controllerName,
      createController: () => WebFController(routeObserver: kWebfRouteObserver),
      bundle: WebFBundle.fromUrl(url),
      setup: (controller) {
        controller.hybridHistory.delegate = kGoRouterDelegate;
        appLogger.i('[WebFView] Controller setup complete');
      },
    );

    appLogger.i('[WebFView] Bundle injection complete');
    return controller;
  } catch (e, stackTrace) {
    appLogger.e(
      '[WebFView] Failed to inject bundle',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Default loading widget for WebF view
Widget _defaultLoadingWidget() {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Initializing WebF...'),
      ],
    ),
  );
}

/// Default error widget for WebF view
Widget _defaultErrorWidget(Object? error) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('${error ?? 'Unknown error'}', textAlign: TextAlign.center),
      ],
    ),
  );
}

/// A pure WebF view widget without Scaffold or AppBar.
///
/// This widget handles WebF controller lifecycle, route focus monitoring,
/// and displays loading/error states. It's designed to be composed into
/// larger page structures rather than being a complete page itself.
class WebFView extends HookConsumerWidget {
  const WebFView({
    super.key,
    required this.url,
    required this.controllerName,
    this.routePath = '/',
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final String controllerName;
  final String routePath;

  /// Optional custom loading widget builder
  final Widget Function(BuildContext)? loadingBuilder;

  /// Optional custom error widget builder
  final Widget Function(BuildContext, Object?)? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerInstance = useState<WebFController?>(null);
    final initError = useState<Object?>(null);
    final isInitialized = useState(false);
    final isAttached = useState(false);
    final isReady = useState(false);

    // Use route focus hook to monitor when this page gains/loses focus
    final isRouteCurrent = useRouteFocus();

    useEffect(() {
      var cancelled = false;
      isInitialized.value = false;
      initError.value = null;

      Future<void> run() async {
        final controller = await injectWebfBundleAsync(
          controllerName: controllerName,
          url: url,
        );
        if (cancelled) return;
        if (!context.mounted) return;
        controllerInstance.value = controller;
        if (controller == null) {
          initError.value = 'Controller initialization returned null';
        } else {
          isInitialized.value = true;
        }
      }

      run();
      return () {
        cancelled = true;
      };
    }, [controllerName, url]);

    // Effect: Handle attach/detach lifecycle based on route focus
    useEffect(
      () {
        if (!isInitialized.value || !isRouteCurrent.value) {
          return null;
        }
        final controller = controllerInstance.value;
        if (controller == null) {
          return null;
        }

        isAttached.value = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          // Intelligently attach: first reference uses manager, subsequent use direct push
          final refCount = HybridControllerManager.instance.attachController(
            controllerName,
            context,
            controller,
          );
          appLogger.d(
            '[WebFView] ✅ Attached controller (ref count: $refCount)',
          );

          // Mark as attached so route checking can begin
          isAttached.value = true;
        });

        return () {
          isAttached.value = false;

          // Intelligently detach: last reference uses manager, intermediate use direct pop
          final refCount = HybridControllerManager.instance.detachController(
            controllerName,
            context.mounted ? context : null,
            controller,
          );
          appLogger.d(
            '[WebFView] 🔌 Detached controller (ref count: $refCount)',
          );
        };
      },
      [
        isInitialized.value,
        isRouteCurrent.value,
        controllerInstance.value,
        controllerName,
      ],
    );

    // Effect: Check route ready status (only after attached)
    useEffect(() {
      if (!isAttached.value) {
        return null;
      }
      final controller = controllerInstance.value;
      if (controller == null) {
        return null;
      }

      isReady.value = false;
      final startTime = DateTime.now();
      var frameCount = 0;
      var disposed = false;

      void checkRouteReady() {
        if (disposed || !context.mounted) return;

        frameCount++;
        final routerView = controller.view.getHybridRouterView(routePath);
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;

        if (routerView != null) {
          appLogger.i(
            '[WebFView] 🎉 Route ready after $frameCount frames (${elapsed}ms)',
          );
          isReady.value = true;
          initError.value = null;
        } else if (frameCount >= 10) {
          // Stop after 10 frames (~150-200ms) - treat as error
          appLogger.e(
            '[WebFView] ⏰ Route not ready after $frameCount frames (${elapsed}ms)',
          );
          initError.value =
              'Route "$routePath" not found after ${elapsed}ms. Verify webf-router registration.';
          isReady.value = false;
        } else {
          // Schedule next frame check
          appLogger.d(
            '[WebFView] ⏳ Frame $frameCount: Route pending (${elapsed}ms)',
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => checkRouteReady(),
          );
        }
      }

      // Start checking
      WidgetsBinding.instance.addPostFrameCallback((_) => checkRouteReady());

      return () {
        disposed = true;
      };
    }, [isAttached.value, controllerInstance.value, routePath]);

    appLogger.d(
      '[WebFView] Building:\n  controllerName: $controllerName\n  path: $routePath\n  url: $url',
    );
    if (initError.value != null) {
      appLogger.e('[WebFView] Error: ${initError.value}');
    }

    if (!isInitialized.value || !isReady.value) {
      return loadingBuilder?.call(context) ?? _defaultLoadingWidget();
    }

    if (initError.value != null) {
      return errorBuilder?.call(context, initError.value) ??
          _defaultErrorWidget(initError.value);
    }

    final controller = controllerInstance.value!;

    return WebFRouterView(
      controller: controller,
      path: routePath,
      defaultViewBuilder: (context) => Center(
        child: Text(
          'Route "$routePath" not found. Verify webf-router registration.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
